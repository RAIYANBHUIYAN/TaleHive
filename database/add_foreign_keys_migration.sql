-- Migration: Add foreign key constraints to club_memberships table
-- Date: September 9, 2025

-- Add foreign key constraint between club_memberships.user_id and users.id
ALTER TABLE club_memberships 
ADD CONSTRAINT club_memberships_user_id_fkey 
FOREIGN KEY (user_id) REFERENCES auth.users(id) 
ON DELETE CASCADE;

-- Add foreign key constraint between club_memberships.club_id and clubs.id
ALTER TABLE club_memberships 
ADD CONSTRAINT club_memberships_club_id_fkey 
FOREIGN KEY (club_id) REFERENCES clubs(id) 
ON DELETE CASCADE;

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_club_memberships_user_id 
ON club_memberships(user_id);

CREATE INDEX IF NOT EXISTS idx_club_memberships_club_id 
ON club_memberships(club_id);

-- Verification queries (uncomment to test)
-- SELECT tc.constraint_name, tc.table_name, kcu.column_name, 
--        ccu.table_name AS foreign_table_name,
--        ccu.column_name AS foreign_column_name 
-- FROM 
--     information_schema.table_constraints AS tc 
--     JOIN information_schema.key_column_usage AS kcu
--       ON tc.constraint_name = kcu.constraint_name
--     JOIN information_schema.constraint_column_usage AS ccu
--       ON ccu.constraint_name = tc.constraint_name
-- WHERE constraint_type = 'FOREIGN KEY' AND tc.table_name='club_memberships';
