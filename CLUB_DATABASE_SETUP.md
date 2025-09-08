# 🗄️ TaleHive Database Setup Guide

## 📋 **Database Tables Required**

The club system requires these tables to be set up in your Supabase database:

### **1. Execute Database Schema**
Run these SQL files in your Supabase SQL Editor in order:

1. **`database_schemas/simple_reading_analytics.sql`** - Basic tables
2. **`database/add_status_column_migration.sql`** - Add status column  
3. **`database/add_foreign_keys_migration.sql`** - Add foreign key constraints

### **2. Tables Overview**

#### **clubs table**
```sql
- id (uuid, primary key)
- name (text)
- description (text) 
- author_id (uuid, references auth.users)
- cover_image_url (text)
- is_premium (boolean)
- membership_price (numeric)
- is_active (boolean)
- created_at (timestamptz)
- updated_at (timestamptz)
```

#### **club_memberships table**
```sql
- id (uuid, primary key)
- club_id (uuid, references clubs)
- user_id (uuid, references auth.users)  
- membership_type (text: 'free' or 'premium')
- status (text: 'active', 'expired', 'cancelled')
- joined_at (timestamptz)
- expires_at (timestamptz, nullable)
```

#### **club_books table**
```sql
- id (uuid, primary key)
- club_id (uuid, references clubs)
- book_id (uuid, references books)
- book_title (text)
- book_author_id (uuid)
- added_at (timestamptz)
```

#### **club_payments table**
```sql
- id (uuid, primary key)
- membership_id (uuid, references club_memberships)
- user_id (uuid, references auth.users)
- club_id (uuid, references clubs)
- amount (numeric)
- status (text: 'pending', 'completed', 'failed')
- payment_method (text: 'bkash', 'nagad', 'rocket', 'card')
- transaction_id (text)
- created_at (timestamptz)
- completed_at (timestamptz)
```

### **3. Row Level Security (RLS)**

Make sure to enable RLS and create appropriate policies:

```sql
-- Enable RLS on all tables
ALTER TABLE clubs ENABLE ROW LEVEL SECURITY;
ALTER TABLE club_memberships ENABLE ROW LEVEL SECURITY;  
ALTER TABLE club_books ENABLE ROW LEVEL SECURITY;
ALTER TABLE club_payments ENABLE ROW LEVEL SECURITY;

-- Sample policies (adjust as needed)
-- Authors can manage their own clubs
CREATE POLICY "Authors can manage own clubs" ON clubs
    FOR ALL USING (auth.uid() = author_id);

-- Users can view their own memberships    
CREATE POLICY "Users can view own memberships" ON club_memberships
    FOR SELECT USING (auth.uid() = user_id);

-- Club authors can view their club members
CREATE POLICY "Authors can view club members" ON club_memberships
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM clubs 
            WHERE clubs.id = club_memberships.club_id 
            AND clubs.author_id = auth.uid()
        )
    );
```

### **4. Quick Setup Commands**

#### **Option A: Execute via Supabase Dashboard**
1. Go to your Supabase project dashboard
2. Navigate to **SQL Editor**
3. Copy and paste each migration file content
4. Execute them in order

#### **Option B: Check Current Status**
Run this query to see what tables exist:
```sql
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name LIKE 'club%';
```

### **5. Verification Queries**

After setup, verify everything works:

```sql
-- Check if tables exist
SELECT COUNT(*) FROM clubs;
SELECT COUNT(*) FROM club_memberships;
SELECT COUNT(*) FROM club_books;
SELECT COUNT(*) FROM club_payments;

-- Check foreign key constraints
SELECT tc.constraint_name, tc.table_name, kcu.column_name
FROM information_schema.table_constraints AS tc 
JOIN information_schema.key_column_usage AS kcu
  ON tc.constraint_name = kcu.constraint_name
WHERE constraint_type = 'FOREIGN KEY' 
AND tc.table_name LIKE 'club%';
```

### **6. Test Data (Optional)**

Create some test data to verify the system:

```sql
-- Insert a test club (replace with your user ID)
INSERT INTO clubs (id, name, description, author_id, is_premium, membership_price, is_active)
VALUES (
    gen_random_uuid(), 
    'Test Book Club', 
    'A test club for development', 
    'your-user-id-here',
    false, 
    0, 
    true
);

-- Insert a test membership  
INSERT INTO club_memberships (id, club_id, user_id, membership_type, status, joined_at)
VALUES (
    gen_random_uuid(),
    (SELECT id FROM clubs WHERE name = 'Test Book Club' LIMIT 1),
    'your-user-id-here',
    'free',
    'active',
    NOW()
);
```

---

## 🚨 **Troubleshooting**

### **Issue: "Could not find relationship"**
- **Problem**: Foreign key constraints missing
- **Solution**: Run `database/add_foreign_keys_migration.sql`

### **Issue: "No members showing"** 
- **Problem**: No data in club_memberships table
- **Solution**: Use the debug button in the app or insert test data

### **Issue: "Table doesn't exist"**
- **Problem**: Database schema not executed
- **Solution**: Run the schema files in Supabase SQL Editor

---

✅ **After completing this setup, your TaleHive club system will be fully functional!**
