-- Fix the default status for club_memberships to be 'pending' instead of 'active'
-- This ensures premium memberships require author approval

-- Change the default value for status column from 'active' to 'pending'
ALTER TABLE public.club_memberships 
ALTER COLUMN status SET DEFAULT 'pending'::text;

-- Update any existing premium memberships that should be pending
-- (This will set premium memberships to pending if they were created in the last hour)
UPDATE public.club_memberships 
SET status = 'pending' 
WHERE membership_type = 'premium' 
  AND status = 'active' 
  AND created_at >= NOW() - INTERVAL '1 hour'
  AND id IN (
    SELECT cm.id 
    FROM club_memberships cm
    JOIN club_payments cp ON cm.user_id = cp.user_id AND cm.club_id = cp.club_id
    WHERE cp.status = 'completed'
  );
