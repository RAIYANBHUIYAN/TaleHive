# Book Club System - Models and Services

This document outlines the models and services created for the book club system with premium memberships and AI integration.

## Models Created

### 1. Club Model (`lib/models/club_model.dart`)
- Represents book clubs created by authors
- Fields: id, name, description, authorId, coverImageUrl, isPremium, membershipPrice, isActive, etc.
- Includes author information (joined data)

### 2. ClubBook Model (`lib/models/club_book_model.dart`)
- Represents books associated with specific clubs
- Links clubs to books with metadata
- Fields: id, clubId, bookId, addedAt, plus book details

### 3. ClubMembership Model (`lib/models/club_membership_model.dart`)
- Represents user memberships in clubs
- Supports both free and premium memberships
- Fields: id, clubId, userId, membershipType, status, joinedAt, expiresAt, etc.
- Enums: MembershipType (free/premium), MembershipStatus (active/expired/cancelled)

### 4. ClubPayment Model (`lib/models/club_payment_model.dart`)
- Represents payment transactions for premium memberships
- Supports multiple payment methods (bKash, Nagad, Rocket, Card, Bank Transfer)
- Fields: id, membershipId, userId, clubId, amount, status, paymentMethod, etc.
- Enums: PaymentStatus, PaymentMethod

### 5. AuthorEarnings Model (`lib/models/author_earnings_model.dart`)
- Represents author earnings analytics and transaction history
- Fields: authorId, totalEarnings, monthlyEarnings, totalMembers, etc.
- Includes recent transaction details

## Services Created

### 1. ClubService (`lib/services/club_service.dart`)
**Club Management:**
- `getClubsByAuthor()` - Get clubs created by specific author
- `getAllActiveClubs()` - Get all active clubs with pagination
- `createClub()` - Create new book club
- `updateClub()` - Update club information
- `deleteClub()` - Soft delete club

**Club Books Management:**
- `getClubBooks()` - Get books in a specific club
- `addBookToClub()` - Add book to club
- `removeBookFromClub()` - Remove book from club

**Membership Management:**
- `getClubMembers()` - Get members of a specific club
- `getUserMemberships()` - Get clubs user is member of
- `joinClub()` - Join a club with free/premium membership

**Analytics:**
- `getAuthorEarnings()` - Get comprehensive earnings data for author
- `searchClubs()` - Search clubs by name

### 2. PaymentService (`lib/services/payment_service.dart`)
**Payment Processing:**
- `createPayment()` - Create new payment record
- `initiateSSLCommerzPayment()` - Start SSLCommerz payment flow
- `completePayment()` - Complete successful payment
- `failPayment()` - Handle failed payment
- `validatePayment()` - Validate payment with SSLCommerz

**Payment History:**
- `getPaymentsByUser()` - Get user's payment history
- `getPaymentsByClub()` - Get payments for specific club

**Features:**
- Supports all major Bangladesh payment methods
- 80-20 revenue sharing (80% to author, 20% to platform)
- Secure payment validation

### 3. AIService (`lib/services/ai_service.dart`)
**Chat Features:**
- `getChatResponse()` - Get AI response with book/club context
- `getReadingInsight()` - Get literary analysis and insights

**Book Recommendations:**
- `getBookRecommendations()` - Get book suggestions by genre/preferences
- `generateBookSummary()` - Generate book summaries
- `generateDiscussionQuestions()` - Create discussion questions

**Premium Features:**
- `getPersonalizedRecommendation()` - Personalized recommendations for premium members

## Database Schema

### Tables Created (`database_schemas/club_system_schema.sql`):

1. **clubs** - Store club information
2. **club_books** - Link clubs to books
3. **club_memberships** - Store user memberships
4. **club_payments** - Store payment transactions
5. **authors** - Added `total_earnings` column

### Key Features:
- Row Level Security (RLS) policies
- Automated earnings calculation triggers
- Comprehensive indexing for performance
- Revenue sharing automation (80-20 split)
- Support for free and premium memberships

## Integration Points

### SSLCommerz Payment Gateway
- Configured for Bangladesh market
- Supports bKash, Nagad, Rocket, Card, Bank Transfer
- Sandbox environment ready
- Webhook handling for payment completion

### Gemini AI Integration
- Context-aware book discussions
- Literary analysis and insights
- Book recommendations
- Discussion question generation
- Premium personalized features

## Next Steps

1. **Run Database Schema**: Execute the SQL schema in Supabase
2. **Update Author Dashboard**: Add club creation and earnings display
3. **Create Club Management UI**: Build interfaces for club management
4. **Implement Payment Flow**: Create payment screens and processing
5. **Add AI Chat Interface**: Build chat interface for premium members

## Configuration Required

1. **Supabase**: Run the database schema
2. **SSLCommerz**: Add your store credentials in PaymentService
3. **Gemini AI**: Add your API key in AIService
4. **Flutter Dependencies**: Ensure http package is added to pubspec.yaml

The system is now ready for UI implementation! 🚀
