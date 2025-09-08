#!/bin/bash
# TaleHive Database Setup Script
# This script provides the SQL commands to execute in Supabase SQL Editor

echo "🏗️  TaleHive Club System Database Setup"
echo "======================================"
echo ""
echo "📋 STEP 1: Copy this entire SQL block and execute in Supabase SQL Editor:"
echo ""
echo "-- ============================================"
echo "-- Copy everything below this line"
echo "-- ============================================"
echo ""

# Read the schema file and output it
cat database_schemas/club_system_schema.sql

echo ""
echo "-- ============================================"
echo "-- Copy everything above this line"
echo "-- ============================================"
echo ""
echo "📋 STEP 2: After successful execution, run these verification queries:"
echo ""
echo "-- Check if tables were created successfully"
echo "SELECT table_name FROM information_schema.tables WHERE table_schema = 'public' AND table_name IN ('clubs', 'club_books', 'club_memberships', 'club_payments');"
echo ""
echo "-- Verify RLS is enabled"
echo "SELECT schemaname, tablename, rowsecurity FROM pg_tables WHERE tablename IN ('clubs', 'club_books', 'club_memberships', 'club_payments');"
echo ""
echo "-- Check indexes"
echo "SELECT indexname, tablename FROM pg_indexes WHERE tablename IN ('clubs', 'club_books', 'club_memberships', 'club_payments');"
echo ""
echo "🎉 Setup complete! Your database is ready for the club system."
echo ""
echo "📖 For detailed instructions, see: DATABASE_SETUP_GUIDE.md"
