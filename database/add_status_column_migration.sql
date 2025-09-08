-- Migration: Add status column to club_memberships table
-- Date: September 9, 2025

-- Add the status column with enum type
ALTER TABLE club_memberships 
ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'active' 
CHECK (status IN ('active', 'expired', 'cancelled'));

-- Create index for better query performance on status
CREATE INDEX IF NOT EXISTS idx_club_memberships_status 
ON club_memberships(status);

-- Create composite index for common queries (club + status)
CREATE INDEX IF NOT EXISTS idx_club_memberships_club_status 
ON club_memberships(club_id, status);

-- Create composite index for user queries (user + status)
CREATE INDEX IF NOT EXISTS idx_club_memberships_user_status 
ON club_memberships(user_id, status);

-- Update any existing records to have 'active' status if they don't have one
UPDATE club_memberships 
SET status = 'active' 
WHERE status IS NULL;

-- Add a comment to the column for documentation
COMMENT ON COLUMN club_memberships.status IS 'Membership status: active, expired, or cancelled';

-- Verification query to check the column was added successfully
-- SELECT column_name, data_type, is_nullable, column_default 
-- FROM information_schema.columns 
-- WHERE table_name = 'club_memberships' AND column_name = 'status';
