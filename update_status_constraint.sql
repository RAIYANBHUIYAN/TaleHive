ALTER TABLE public.club_memberships DROP CONSTRAINT IF EXISTS club_memberships_status_check;
ALTER TABLE public.club_memberships ADD CONSTRAINT club_memberships_status_check CHECK (status = ANY(ARRAY['active'::text, 'expired'::text, 'cancelled'::text, 'pending'::text]));
