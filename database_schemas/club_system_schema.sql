-- Book Club System Database Schema
-- This schema creates the necessary tables for the club-based book platform
-- with premium subscriptions, AI chat features, and revenue sharing

-- 1. Clubs table - stores book club information
CREATE TABLE IF NOT EXISTS public.clubs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    author_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    cover_image_url TEXT,
    is_premium BOOLEAN DEFAULT FALSE,
    membership_price DECIMAL(10,2) DEFAULT 0.00,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Club Books table - stores books associated with each club
CREATE TABLE IF NOT EXISTS public.club_books (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    club_id UUID NOT NULL REFERENCES public.clubs(id) ON DELETE CASCADE,
    book_id UUID NOT NULL REFERENCES public.books(id) ON DELETE CASCADE,
    added_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(club_id, book_id)
);

-- 3. Club Memberships table - stores user memberships to clubs
CREATE TABLE IF NOT EXISTS public.club_memberships (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    club_id UUID NOT NULL REFERENCES public.clubs(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    membership_type VARCHAR(20) DEFAULT 'free' CHECK (membership_type IN ('free', 'premium')),
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'expired', 'cancelled')),
    joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    expires_at TIMESTAMP WITH TIME ZONE,
    UNIQUE(club_id, user_id)
);

-- 4. Club Payments table - stores payment transactions for premium memberships
CREATE TABLE IF NOT EXISTS public.club_payments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    membership_id UUID NOT NULL REFERENCES public.club_memberships(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    club_id UUID NOT NULL REFERENCES public.clubs(id) ON DELETE CASCADE,
    amount DECIMAL(10,2) NOT NULL,
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'completed', 'failed', 'refunded')),
    payment_method VARCHAR(50) NOT NULL CHECK (payment_method IN ('bkash', 'nagad', 'rocket', 'card', 'bank_transfer')),
    transaction_id VARCHAR(255),
    payment_data JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    completed_at TIMESTAMP WITH TIME ZONE
);

-- 5. Update authors table to include total earnings (80% of payments)
ALTER TABLE public.authors 
ADD COLUMN IF NOT EXISTS total_earnings DECIMAL(10,2) DEFAULT 0.00;

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_clubs_author_id ON public.clubs(author_id);
CREATE INDEX IF NOT EXISTS idx_clubs_is_active ON public.clubs(is_active);
CREATE INDEX IF NOT EXISTS idx_clubs_is_premium ON public.clubs(is_premium);

CREATE INDEX IF NOT EXISTS idx_club_books_club_id ON public.club_books(club_id);
CREATE INDEX IF NOT EXISTS idx_club_books_book_id ON public.club_books(book_id);

CREATE INDEX IF NOT EXISTS idx_club_memberships_club_id ON public.club_memberships(club_id);
CREATE INDEX IF NOT EXISTS idx_club_memberships_user_id ON public.club_memberships(user_id);
CREATE INDEX IF NOT EXISTS idx_club_memberships_status ON public.club_memberships(status);

CREATE INDEX IF NOT EXISTS idx_club_payments_user_id ON public.club_payments(user_id);
CREATE INDEX IF NOT EXISTS idx_club_payments_club_id ON public.club_payments(club_id);
CREATE INDEX IF NOT EXISTS idx_club_payments_status ON public.club_payments(status);
CREATE INDEX IF NOT EXISTS idx_club_payments_created_at ON public.club_payments(created_at DESC);

-- Enable Row Level Security (RLS)
ALTER TABLE public.clubs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.club_books ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.club_memberships ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.club_payments ENABLE ROW LEVEL SECURITY;

-- RLS Policies for clubs table
CREATE POLICY "Anyone can view active clubs" ON public.clubs
    FOR SELECT USING (is_active = true);

CREATE POLICY "Authors can manage their own clubs" ON public.clubs
    FOR ALL USING (auth.uid() = author_id);

-- RLS Policies for club_books table
CREATE POLICY "Anyone can view club books" ON public.club_books
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.clubs 
            WHERE clubs.id = club_books.club_id 
            AND clubs.is_active = true
        )
    );

CREATE POLICY "Club authors can manage club books" ON public.club_books
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.clubs 
            WHERE clubs.id = club_books.club_id 
            AND clubs.author_id = auth.uid()
        )
    );

-- RLS Policies for club_memberships table
CREATE POLICY "Users can view their own memberships" ON public.club_memberships
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Club authors can view their club memberships" ON public.club_memberships
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.clubs 
            WHERE clubs.id = club_memberships.club_id 
            AND clubs.author_id = auth.uid()
        )
    );

CREATE POLICY "Users can join clubs" ON public.club_memberships
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own memberships" ON public.club_memberships
    FOR UPDATE USING (auth.uid() = user_id);

-- RLS Policies for club_payments table
CREATE POLICY "Users can view their own payments" ON public.club_payments
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Club authors can view their club payments" ON public.club_payments
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.clubs 
            WHERE clubs.id = club_payments.club_id 
            AND clubs.author_id = auth.uid()
        )
    );

CREATE POLICY "Users can create their own payments" ON public.club_payments
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Function to update author earnings when a payment is completed
CREATE OR REPLACE FUNCTION update_author_earnings()
RETURNS TRIGGER AS $$
BEGIN
    -- Only process when payment status changes to 'completed'
    IF NEW.status = 'completed' AND (OLD.status IS NULL OR OLD.status != 'completed') THEN
        -- Calculate author earnings (80% of payment amount)
        UPDATE public.authors 
        SET total_earnings = COALESCE(total_earnings, 0) + (NEW.amount * 0.8)
        WHERE id = (
            SELECT author_id 
            FROM public.clubs 
            WHERE id = NEW.club_id
        );
    END IF;
    
    -- If payment is refunded, subtract the earnings
    IF NEW.status = 'refunded' AND OLD.status = 'completed' THEN
        UPDATE public.authors 
        SET total_earnings = GREATEST(COALESCE(total_earnings, 0) - (NEW.amount * 0.8), 0)
        WHERE id = (
            SELECT author_id 
            FROM public.clubs 
            WHERE id = NEW.club_id
        );
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for updating author earnings
DROP TRIGGER IF EXISTS trigger_update_author_earnings ON public.club_payments;
CREATE TRIGGER trigger_update_author_earnings
    AFTER UPDATE OF status ON public.club_payments
    FOR EACH ROW
    EXECUTE FUNCTION update_author_earnings();

-- Function to get author earnings summary
CREATE OR REPLACE FUNCTION get_author_earnings_summary(p_author_id UUID)
RETURNS TABLE (
    total_earnings DECIMAL(10,2),
    monthly_earnings DECIMAL(10,2),
    total_members BIGINT,
    premium_members BIGINT,
    active_clubs BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COALESCE(a.total_earnings, 0) as total_earnings,
        COALESCE(monthly.monthly_earnings, 0) as monthly_earnings,
        COALESCE(members.total_members, 0) as total_members,
        COALESCE(members.premium_members, 0) as premium_members,
        COALESCE(clubs.active_clubs, 0) as active_clubs
    FROM public.authors a
    LEFT JOIN (
        -- Monthly earnings calculation
        SELECT 
            c.author_id,
            SUM(cp.amount * 0.8) as monthly_earnings
        FROM public.club_payments cp
        JOIN public.clubs c ON cp.club_id = c.id
        WHERE c.author_id = p_author_id
        AND cp.status = 'completed'
        AND cp.completed_at >= date_trunc('month', CURRENT_DATE)
        GROUP BY c.author_id
    ) monthly ON a.id = monthly.author_id
    LEFT JOIN (
        -- Member counts
        SELECT 
            c.author_id,
            COUNT(*) as total_members,
            COUNT(CASE WHEN cm.membership_type = 'premium' THEN 1 END) as premium_members
        FROM public.club_memberships cm
        JOIN public.clubs c ON cm.club_id = c.id
        WHERE c.author_id = p_author_id
        AND cm.status = 'active'
        GROUP BY c.author_id
    ) members ON a.id = members.author_id
    LEFT JOIN (
        -- Active clubs count
        SELECT 
            author_id,
            COUNT(*) as active_clubs
        FROM public.clubs
        WHERE author_id = p_author_id
        AND is_active = true
        GROUP BY author_id
    ) clubs ON a.id = clubs.author_id
    WHERE a.id = p_author_id;
END;
$$ LANGUAGE plpgsql;

-- Insert sample data (optional - remove in production)
-- Sample club for testing
INSERT INTO public.clubs (name, description, author_id, is_premium, membership_price) 
VALUES (
    'Modern Fiction Book Club',
    'A community for discussing contemporary literary fiction and emerging authors.',
    (SELECT id FROM public.authors LIMIT 1),
    true,
    99.00
) ON CONFLICT DO NOTHING;

-- Grant necessary permissions
GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT SELECT ON public.clubs TO anon, authenticated;
GRANT SELECT ON public.club_books TO anon, authenticated;
GRANT ALL ON public.club_memberships TO authenticated;
GRANT ALL ON public.club_payments TO authenticated;
GRANT SELECT ON public.authors TO anon, authenticated;
GRANT UPDATE(total_earnings) ON public.authors TO authenticated;

-- Success message
SELECT 'Book Club System schema created successfully! 🎉' as status;
