# 📚 TaleHive Club System - Database Setup Guide

## 🎯 Overview
This guide walks you through setting up the complete database schema for the TaleHive Book Club System with premium memberships, AI chat features, and revenue sharing.

## 📋 Prerequisites
- Supabase project created and configured
- Flutter app connected to Supabase
- Admin access to Supabase dashboard

## 🗄️ Database Schema Components

### Tables Created:
1. **clubs** - Book club information with premium settings
2. **club_books** - Books associated with each club
3. **club_memberships** - User memberships (free/premium)
4. **club_payments** - Payment transactions with SSLCommerz integration

### Key Features:
- ✅ Row Level Security (RLS) policies
- ✅ Automated earnings calculations (80-20 split)
- ✅ Performance indexes
- ✅ Payment status tracking
- ✅ Membership expiration handling

## 🚀 Setup Instructions

### Step 1: Access Supabase SQL Editor
1. Go to your Supabase project dashboard
2. Navigate to **SQL Editor** in the left sidebar
3. Create a new query

### Step 2: Execute Club System Schema
1. Copy the entire content from `database_schemas/club_system_schema.sql`
2. Paste it into the SQL Editor
3. Click **Run** to execute the schema

### Step 3: Verify Tables Creation
Run this query to verify all tables are created:
```sql
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('clubs', 'club_books', 'club_memberships', 'club_payments');
```

### Step 4: Check RLS Policies
Verify Row Level Security is enabled:
```sql
SELECT schemaname, tablename, rowsecurity 
FROM pg_tables 
WHERE tablename IN ('clubs', 'club_books', 'club_memberships', 'club_payments');
```

### Step 5: Test Author Earnings Function
```sql
-- Replace with actual author ID from your authors table
SELECT * FROM get_author_earnings_summary('your-author-id-here');
```

## 💳 Payment Integration Setup

### SSLCommerz Configuration
The system is pre-configured with:
- **Store ID**: `wrist6830197f2308c`
- **Store Password**: `wrist6830197f2308c@ssl`
- **Payment Methods**: bKash, Nagad, Rocket, Credit/Debit Cards

### Revenue Sharing
- **Author Earnings**: 80% of all premium membership payments
- **Platform Commission**: 20% of all premium membership payments
- **Auto-calculation**: Triggered when payment status changes to 'completed'

## 🤖 AI Integration

### Gemini AI Configuration
- **API Key**: Configured in `ai_service.dart`
- **Features**: Book recommendations, chat responses, personalized content
- **Premium Features**: Enhanced AI interactions for premium members

## 📊 Database Monitoring

### Key Metrics to Track:
```sql
-- Total active clubs
SELECT COUNT(*) FROM clubs WHERE is_active = true;

-- Premium vs Free clubs
SELECT is_premium, COUNT(*) FROM clubs GROUP BY is_premium;

-- Monthly revenue
SELECT 
  DATE_TRUNC('month', completed_at) as month,
  SUM(amount) as total_revenue,
  SUM(amount * 0.8) as author_earnings,
  SUM(amount * 0.2) as platform_commission
FROM club_payments 
WHERE status = 'completed' 
GROUP BY month 
ORDER BY month DESC;

-- Active memberships
SELECT membership_type, COUNT(*) 
FROM club_memberships 
WHERE status = 'active' 
GROUP BY membership_type;
```

## 🔧 Maintenance Tasks

### Monthly Tasks:
1. **Cleanup expired memberships**:
```sql
UPDATE club_memberships 
SET status = 'expired' 
WHERE expires_at < NOW() AND status = 'active';
```

2. **Generate earnings reports**:
```sql
SELECT 
  a.name as author_name,
  a.total_earnings,
  COUNT(DISTINCT c.id) as club_count,
  COUNT(DISTINCT cm.id) as member_count
FROM authors a
LEFT JOIN clubs c ON a.id = c.author_id
LEFT JOIN club_memberships cm ON c.id = cm.club_id
WHERE a.total_earnings > 0
GROUP BY a.id, a.name, a.total_earnings
ORDER BY a.total_earnings DESC;
```

## 🛡️ Security Features

### Row Level Security (RLS):
- Users can only see active clubs
- Authors can only manage their own clubs
- Users can only view their own payments and memberships
- Club authors can view their club's payments and memberships

### Data Protection:
- Sensitive payment data encrypted in `payment_data` JSONB field
- User authentication required for all write operations
- Automatic cleanup of deleted user data via CASCADE constraints

## 🎉 Success Verification

After setup completion, you should see:
- ✅ 4 new tables in your Supabase dashboard
- ✅ RLS policies active on all tables
- ✅ Automated triggers for earnings calculation
- ✅ Sample data inserted (if included in schema)
- ✅ All indexes created for optimal performance

## 📞 Support

If you encounter any issues during setup:
1. Check Supabase logs for error details
2. Verify your project has sufficient permissions
3. Ensure all prerequisite tables exist (authors, books, etc.)
4. Contact support with specific error messages

---

**🚀 Ready to launch your Book Club Platform!**

The database is now configured for:
- Premium club memberships
- Automated payment processing
- AI-powered recommendations
- Revenue sharing with authors
- Comprehensive analytics and reporting
