-- COPY AND PASTE THIS INTO SUPABASE SQL EDITOR
-- This will fix the premium club approval system

-- Step 1: Change default status from 'active' to 'pending'
ALTER TABLE public.club_memberships 
ALTER COLUMN status SET DEFAULT 'pending'::text;

-- Step 2: Update recent premium memberships to pending status
-- (This will fix any memberships created in the last 2 hours)
UPDATE public.club_memberships 
SET status = 'pending' 
WHERE membership_type = 'premium' 
  AND status = 'active' 
  AND created_at >= NOW() - INTERVAL '2 hours';

-- Step 3: Verify the changes
SELECT 
  cm.*,
  cp.status as payment_status,
  cp.amount as payment_amount
FROM club_memberships cm
LEFT JOIN club_payments cp ON cm.user_id = cp.user_id AND cm.club_id = cp.club_id
WHERE cm.membership_type = 'premium'
ORDER BY cm.created_at DESC
LIMIT 10;
