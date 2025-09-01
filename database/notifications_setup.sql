-- Create notifications table
CREATE TABLE IF NOT EXISTS public.notifications (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  type text NOT NULL,
  title text NOT NULL,
  body text,
  data jsonb,
  is_read boolean NOT NULL DEFAULT false,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT notifications_pkey PRIMARY KEY (id),
  CONSTRAINT notifications_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS notifications_user_id_idx ON public.notifications (user_id);
CREATE INDEX IF NOT EXISTS notifications_created_at_idx ON public.notifications (created_at DESC);
CREATE INDEX IF NOT EXISTS notifications_is_read_idx ON public.notifications (is_read);

-- Enable Row Level Security (RLS)
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

-- Create policy to allow users to see only their own notifications
CREATE POLICY "Users can view their own notifications" ON public.notifications
  FOR SELECT USING (auth.uid() = user_id);

-- Create policy to allow users to update their own notifications (for marking as read)
CREATE POLICY "Users can update their own notifications" ON public.notifications
  FOR UPDATE USING (auth.uid() = user_id);

-- Create policy to allow admins to insert notifications
CREATE POLICY "Admins can insert notifications" ON public.notifications
  FOR INSERT WITH CHECK (true);

-- Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to automatically update updated_at
CREATE TRIGGER notifications_updated_at
  BEFORE UPDATE ON public.notifications
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_updated_at();

-- Create function to send notifications when borrow request status changes
CREATE OR REPLACE FUNCTION public.create_borrow_notification()
RETURNS TRIGGER AS $$
BEGIN
  -- When borrow request is approved
  IF NEW.status = 'accepted' AND OLD.status = 'pending' THEN
    INSERT INTO public.notifications (user_id, type, title, body, data)
    VALUES (
      NEW.user_id,
      'borrow_approved',
      'Borrow Request Approved',
      'Your borrow request has been approved! You can now download the book.',
      jsonb_build_object(
        'borrow_request_id', NEW.id,
        'book_id', NEW.book_id,
        'start_date', NEW.start_date,
        'end_date', NEW.end_date
      )
    );
  END IF;

  -- When borrow request is rejected
  IF NEW.status = 'rejected' AND OLD.status = 'pending' THEN
    INSERT INTO public.notifications (user_id, type, title, body, data)
    VALUES (
      NEW.user_id,
      'borrow_rejected',
      'Borrow Request Rejected',
      'Unfortunately, your borrow request has been rejected. Please contact support for more information.',
      jsonb_build_object(
        'borrow_request_id', NEW.id,
        'book_id', NEW.book_id
      )
    );
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for borrow request status changes
CREATE TRIGGER borrow_status_notification
  AFTER UPDATE ON public.borrow_requests
  FOR EACH ROW
  EXECUTE FUNCTION public.create_borrow_notification();

-- Create function to send due date reminders
CREATE OR REPLACE FUNCTION public.send_due_reminders()
RETURNS void AS $$
DECLARE
  borrow_record RECORD;
BEGIN
  -- Send reminders for books due in 3 days
  FOR borrow_record IN
    SELECT br.*, b.title as book_title
    FROM public.borrow_requests br
    JOIN public.books b ON br.book_id::text = b.id
    WHERE br.status = 'accepted'
    AND br.end_date::date - CURRENT_DATE = 3
    AND NOT EXISTS (
      SELECT 1 FROM public.notifications n
      WHERE n.user_id = br.user_id
      AND n.type = 'borrow_due_reminder'
      AND (n.data->>'borrow_request_id')::uuid = br.id
      AND n.created_at::date = CURRENT_DATE
    )
  LOOP
    INSERT INTO public.notifications (user_id, type, title, body, data)
    VALUES (
      borrow_record.user_id,
      'borrow_due_reminder',
      'Book Due in 3 Days',
      format('Your borrowed book "%s" is due in 3 days. Please return it on time.', borrow_record.book_title),
      jsonb_build_object(
        'borrow_request_id', borrow_record.id,
        'book_id', borrow_record.book_id,
        'end_date', borrow_record.end_date,
        'book_title', borrow_record.book_title
      )
    );
  END LOOP;

  -- Send overdue notifications
  FOR borrow_record IN
    SELECT br.*, b.title as book_title
    FROM public.borrow_requests br
    JOIN public.books b ON br.book_id::text = b.id
    WHERE br.status = 'accepted'
    AND br.end_date::date < CURRENT_DATE
    AND NOT EXISTS (
      SELECT 1 FROM public.notifications n
      WHERE n.user_id = br.user_id
      AND n.type = 'borrow_overdue'
      AND (n.data->>'borrow_request_id')::uuid = br.id
      AND n.created_at::date = CURRENT_DATE
    )
  LOOP
    INSERT INTO public.notifications (user_id, type, title, body, data)
    VALUES (
      borrow_record.user_id,
      'borrow_overdue',
      'Book Overdue',
      format('Your borrowed book "%s" was due on %s. Please return it as soon as possible.', 
             borrow_record.book_title, 
             borrow_record.end_date::date),
      jsonb_build_object(
        'borrow_request_id', borrow_record.id,
        'book_id', borrow_record.book_id,
        'end_date', borrow_record.end_date,
        'book_title', borrow_record.book_title
      )
    );
  END LOOP;
END;
$$ LANGUAGE plpgsql;

-- Note: To automate due date reminders, you would need to set up a cron job or use Supabase Edge Functions
-- to call the send_due_reminders() function daily.

-- Example usage:
-- SELECT public.send_due_reminders();
