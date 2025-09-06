-- Simple Reading Analytics Schema
-- This schema provides basic reading analytics without complex real-time features
-- Uses existing borrow_requests table instead of creating new current_readings table

-- Table to track basic book popularity (simple analytics)
-- Create only if it doesn't exist, since you might already have it
CREATE TABLE IF NOT EXISTS book_popularity (
    book_id UUID PRIMARY KEY REFERENCES books(id) ON DELETE CASCADE,
    total_borrows INTEGER DEFAULT 0,
    unique_readers INTEGER DEFAULT 0,
    last_borrowed_date DATE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Simple function to get current readers with basic info
-- Uses existing borrow_requests table where status = 'accepted' AND end_date hasn't passed
CREATE OR REPLACE FUNCTION get_current_readings()
RETURNS TABLE (
    reading_id UUID,
    user_id UUID,
    user_name TEXT,
    user_email TEXT,
    book_id UUID,
    book_title TEXT,
    book_cover TEXT,
    author_name TEXT,
    borrowed_date DATE,
    due_date DATE,
    days_remaining INTEGER,
    status TEXT,
    category TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        br.id as reading_id,
        br.user_id,
        CONCAT(u.first_name, ' ', u.last_name) as user_name,
        u.email,
        br.book_id,
        b.title,
        b.cover_image_url,
        COALESCE(a.first_name || ' ' || a.last_name, 'Unknown Author') as author_name,
        br.start_date::DATE as borrowed_date,
        br.end_date::DATE as due_date,
        (br.end_date::DATE - CURRENT_DATE)::INTEGER as days_remaining,
        CASE 
            WHEN br.end_date::DATE < CURRENT_DATE THEN 'overdue'
            WHEN br.end_date::DATE = CURRENT_DATE THEN 'due_today'
            ELSE 'reading'
        END as status,
        b.category
    FROM borrow_requests br
    JOIN users u ON br.user_id = u.id
    JOIN books b ON br.book_id = b.id
    LEFT JOIN authors a ON b.author_id = a.id
    WHERE br.status = 'accepted'
    -- Show all accepted requests, regardless of end_date for admin monitoring
    ORDER BY br.end_date ASC;
END;
$$ LANGUAGE plpgsql;

-- Simple function to get most popular books
CREATE OR REPLACE FUNCTION get_most_popular_books()
RETURNS TABLE (
    book_id UUID,
    book_title TEXT,
    book_cover TEXT,
    author_name TEXT,
    category TEXT,
    total_borrows INTEGER,
    unique_readers INTEGER,
    last_borrowed_date DATE
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        bp.book_id,
        b.title,
        b.cover_image_url,
        COALESCE(a.first_name || ' ' || a.last_name, 'Unknown Author') as author_name,
        b.category,
        bp.total_borrows,
        bp.unique_readers,
        bp.last_borrowed_date
    FROM book_popularity bp
    JOIN books b ON bp.book_id = b.id
    LEFT JOIN authors a ON b.author_id = a.id
    WHERE bp.total_borrows > 0
    ORDER BY bp.total_borrows DESC, bp.unique_readers DESC
    LIMIT 20;
END;
$$ LANGUAGE plpgsql;

-- Simple trigger to update book popularity when borrow requests are accepted
-- No need to insert into current_readings since we use borrow_requests directly
CREATE OR REPLACE FUNCTION update_book_popularity()
RETURNS TRIGGER AS $$
BEGIN
    -- Only process when status changes to 'accepted'
    IF NEW.status = 'accepted' AND (OLD.status IS NULL OR OLD.status != 'accepted') THEN
        -- Update book popularity
        INSERT INTO book_popularity (book_id, total_borrows, unique_readers, last_borrowed_date)
        VALUES (NEW.book_id, 1, 1, NEW.start_date::DATE)
        ON CONFLICT (book_id) DO UPDATE SET
            total_borrows = book_popularity.total_borrows + 1,
            unique_readers = (
                SELECT COUNT(DISTINCT user_id) 
                FROM borrow_requests 
                WHERE book_id = NEW.book_id AND status = 'accepted'
            ),
            last_borrowed_date = NEW.start_date::DATE,
            updated_at = NOW();
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger
DROP TRIGGER IF EXISTS trigger_update_book_popularity ON borrow_requests;
CREATE TRIGGER trigger_update_book_popularity
    AFTER UPDATE ON borrow_requests
    FOR EACH ROW
    EXECUTE FUNCTION update_book_popularity();

-- Create indexes for better performance on borrow_requests (if not already exist)
CREATE INDEX IF NOT EXISTS idx_borrow_requests_status_accepted ON borrow_requests(status) WHERE status = 'accepted';
CREATE INDEX IF NOT EXISTS idx_borrow_requests_end_date ON borrow_requests(end_date);
CREATE INDEX IF NOT EXISTS idx_book_popularity_total_borrows ON book_popularity(total_borrows DESC);

-- Simple function to extend due date (updates borrow_requests end_date)
-- This is the main admin action since books auto-expire after end_date
CREATE OR REPLACE FUNCTION extend_due_date(reading_id UUID, new_due_date DATE)
RETURNS BOOLEAN AS $$
BEGIN
    UPDATE borrow_requests 
    SET end_date = new_due_date::TIMESTAMP, updated_at = NOW()
    WHERE id = reading_id AND status = 'accepted';
    
    RETURN FOUND;
END;
$$ LANGUAGE plpgsql;

-- Debug function to test basic borrow_requests query
CREATE OR REPLACE FUNCTION test_basic_query()
RETURNS TABLE (
    request_id UUID,
    book_title TEXT,
    user_email TEXT,
    status TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        br.id,
        b.title,
        u.email,
        br.status
    FROM borrow_requests br
    JOIN users u ON br.user_id = u.id
    JOIN books b ON br.book_id = b.id
    LIMIT 5;
END;
$$ LANGUAGE plpgsql;

-- Function to get active readable books for a user (where end_date hasn't passed)
-- This can be used in the user app to check book access
CREATE OR REPLACE FUNCTION get_user_active_books(user_uuid UUID)
RETURNS TABLE (
    book_id UUID,
    book_title TEXT,
    end_date TIMESTAMP,
    days_remaining INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        br.book_id,
        b.title,
        br.end_date,
        (br.end_date::DATE - CURRENT_DATE)::INTEGER as days_remaining
    FROM borrow_requests br
    JOIN books b ON br.book_id = b.id
    WHERE br.user_id = user_uuid 
      AND br.status = 'accepted'
      AND br.end_date::DATE >= CURRENT_DATE -- Only books that haven't expired
    ORDER BY br.end_date ASC;
END;
$$ LANGUAGE plpgsql;
