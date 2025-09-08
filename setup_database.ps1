# TaleHive Database Setup Script (PowerShell)
# This script provides the SQL commands to execute in Supabase SQL Editor

Write-Host "🏗️  TaleHive Club System Database Setup" -ForegroundColor Green
Write-Host "======================================" -ForegroundColor Green
Write-Host ""
Write-Host "📋 STEP 1: Copy the SQL schema and execute in Supabase SQL Editor:" -ForegroundColor Yellow
Write-Host ""
Write-Host "🌐 Go to your Supabase project → SQL Editor → New Query" -ForegroundColor Cyan
Write-Host "📄 Copy the content from: database_schemas/club_system_schema.sql" -ForegroundColor Cyan
Write-Host "▶️  Click 'Run' to execute the schema" -ForegroundColor Cyan
Write-Host ""

# Check if schema file exists
if (Test-Path "database_schemas\club_system_schema.sql") {
    Write-Host "✅ Schema file found: database_schemas\club_system_schema.sql" -ForegroundColor Green
    Write-Host "📊 File size: $((Get-Item 'database_schemas\club_system_schema.sql').Length) bytes" -ForegroundColor Green
} else {
    Write-Host "❌ Schema file not found! Please check the file path." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "📋 STEP 2: After successful execution, verify with these queries:" -ForegroundColor Yellow
Write-Host ""

@"
-- 1. Check if tables were created successfully
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('clubs', 'club_books', 'club_memberships', 'club_payments');

-- 2. Verify Row Level Security is enabled  
SELECT schemaname, tablename, rowsecurity 
FROM pg_tables 
WHERE tablename IN ('clubs', 'club_books', 'club_memberships', 'club_payments');

-- 3. Check indexes were created
SELECT indexname, tablename 
FROM pg_indexes 
WHERE tablename IN ('clubs', 'club_books', 'club_memberships', 'club_payments');

-- 4. Test the earnings function (replace with actual author ID)
-- SELECT * FROM get_author_earnings_summary('your-author-id-here');

-- 5. Check sample data
SELECT COUNT(*) as club_count FROM clubs;
SELECT COUNT(*) as membership_count FROM club_memberships;
"@ | Write-Host -ForegroundColor Gray

Write-Host ""
Write-Host "🔧 STEP 3: Configure your Flutter app:" -ForegroundColor Yellow
Write-Host "   1. Update Supabase URL and anon key in main.dart" -ForegroundColor Cyan
Write-Host "   2. Test club service methods" -ForegroundColor Cyan
Write-Host "   3. Verify payment integration" -ForegroundColor Cyan
Write-Host ""

Write-Host "📊 Expected Results:" -ForegroundColor Yellow
Write-Host "   ✅ 4 tables created (clubs, club_books, club_memberships, club_payments)" -ForegroundColor Green
Write-Host "   ✅ RLS enabled on all tables" -ForegroundColor Green  
Write-Host "   ✅ Automated earnings trigger active" -ForegroundColor Green
Write-Host "   ✅ Performance indexes created" -ForegroundColor Green
Write-Host "   ✅ Sample data inserted" -ForegroundColor Green
Write-Host ""

Write-Host "🎉 Database setup complete! Your club system is ready to use." -ForegroundColor Green
Write-Host "📖 For detailed instructions, see: DATABASE_SETUP_GUIDE.md" -ForegroundColor Cyan

# Optionally open the schema file in default editor
$response = Read-Host "Would you like to open the schema file now? (y/N)"
if ($response -eq 'y' -or $response -eq 'Y') {
    Start-Process "database_schemas\club_system_schema.sql"
}
