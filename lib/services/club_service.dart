import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/club_model.dart';
import '../models/club_book_model.dart';
import '../models/club_membership_model.dart';
import '../models/author_earnings_model.dart';

class ClubService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Club Management
  Future<List<Club>> getClubsByAuthor(String authorId) async {
    try {
      final response = await _supabase
          .from('clubs')
          .select('''
            *,
            authors!clubs_author_id_fkey(first_name, last_name, photo_url)
          ''')
          .eq('author_id', authorId)
          .eq('is_active', true)
          .order('created_at', ascending: false);

      return response.map<Club>((json) {
        return Club.fromJson({
          ...json,
          'author_first_name': json['authors']?['first_name'],
          'author_last_name': json['authors']?['last_name'],
          'author_photo_url': json['authors']?['photo_url'],
        });
      }).toList();
    } catch (e) {
      print('Error fetching clubs by author: $e');
      return [];
    }
  }

  Future<List<Club>> getAllActiveClubs({int? limit, int? offset}) async {
    try {
      var query = _supabase
          .from('clubs')
          .select('''
            *,
            authors!clubs_author_id_fkey(first_name, last_name, photo_url)
          ''')
          .eq('is_active', true)
          .order('created_at', ascending: false);

      if (limit != null) {
        query = query.limit(limit);
      }
      if (offset != null) {
        query = query.range(offset, offset + (limit ?? 10) - 1);
      }

      final response = await query;

      return response.map<Club>((json) {
        return Club.fromJson({
          ...json,
          'author_first_name': json['authors']?['first_name'],
          'author_last_name': json['authors']?['last_name'],
          'author_photo_url': json['authors']?['photo_url'],
        });
      }).toList();
    } catch (e) {
      print('Error fetching all clubs: $e');
      return [];
    }
  }

  Future<Club?> createClub({
    required String name,
    required String description,
    required String authorId,
    String? coverImageUrl,
    bool isPremium = false,
    double membershipPrice = 0.0,
  }) async {
    try {
      final clubData = {
        'name': name,
        'description': description,
        'author_id': authorId,
        'cover_image_url': coverImageUrl,
        'is_premium': isPremium,
        'membership_price': membershipPrice,
        'is_active': true,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabase
          .from('clubs')
          .insert(clubData)
          .select('''
            *,
            authors!clubs_author_id_fkey(first_name, last_name, photo_url)
          ''')
          .single();

      return Club.fromJson({
        ...response,
        'author_first_name': response['authors']?['first_name'],
        'author_last_name': response['authors']?['last_name'],
        'author_photo_url': response['authors']?['photo_url'],
      });
    } catch (e) {
      print('Error creating club: $e');
      return null;
    }
  }

  Future<bool> updateClub(Club club) async {
    try {
      await _supabase
          .from('clubs')
          .update({
            'name': club.name,
            'description': club.description,
            'cover_image_url': club.coverImageUrl,
            'is_premium': club.isPremium,
            'membership_price': club.membershipPrice,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', club.id);
      return true;
    } catch (e) {
      print('Error updating club: $e');
      return false;
    }
  }

  Future<bool> deleteClub(String clubId) async {
    try {
      print('🗑️ Starting comprehensive club deletion process for club ID: $clubId');
      
      // Step 1: Delete all club payments related to this club
      print('💳 Deleting club payments...');
      await _supabase
          .from('club_payments')
          .delete()
          .eq('club_id', clubId);
      print('✅ Club payments deleted');
      
      // Step 2: Delete all club memberships related to this club
      print('👥 Deleting club memberships...');
      await _supabase
          .from('club_memberships')
          .delete()
          .eq('club_id', clubId);
      print('✅ Club memberships deleted');
      
      // Step 3: Delete all club books related to this club
      print('📚 Deleting club books...');
      await _supabase
          .from('club_books')
          .delete()
          .eq('club_id', clubId);
      print('✅ Club books deleted');
      
      // Step 4: Delete any club analytics/stats if they exist
      // Note: Add more tables here if you have additional related tables
      try {
        print('📊 Checking for club analytics/stats...');
        // If you have a club_analytics or club_stats table, delete here
        // await _supabase.from('club_analytics').delete().eq('club_id', clubId);
        print('✅ Analytics cleanup completed');
      } catch (e) {
        print('⚠️ No analytics tables found or error cleaning up: $e');
      }
      
      // Step 5: Finally delete the club itself
      print('🏛️ Deleting the club record...');
      await _supabase
          .from('clubs')
          .delete()
          .eq('id', clubId);
      print('✅ Club record deleted');
      
      print('🎉 Club deletion completed successfully! All related data removed:');
      print('   - Club payments ✅');
      print('   - Club memberships ✅'); 
      print('   - Club books ✅');
      print('   - Club record ✅');
      
      return true;
    } catch (e) {
      print('❌ Error during club deletion process: $e');
      print('❌ Club deletion failed. Some data may have been partially deleted.');
      return false;
    }
  }

  // Club Books Management
  Future<List<ClubBook>> getClubBooks(String clubId) async {
    try {
      final response = await _supabase
          .from('club_books')
          .select('''
            *,
            books!club_books_book_id_fkey(title, cover_image_url, pdf_url, author_id, category, price, summary)
          ''')
          .eq('club_id', clubId)
          .order('added_at', ascending: false);

      return response.map<ClubBook>((json) {
        return ClubBook.fromJson({
          ...json,
          'book_title': json['books']?['title'],
          'book_cover_url': json['books']?['cover_image_url'],
          'book_pdf_url': json['books']?['pdf_url'],
          'book_author_id': json['books']?['author_id'],
          'book_category': json['books']?['category'],
          'book_price': json['books']?['price'],
          'book_summary': json['books']?['summary'],
        });
      }).toList();
    } catch (e) {
      print('Error fetching club books: $e');
      return [];
    }
  }

  Future<bool> addBookToClub(String clubId, String bookId, {String accessLevel = 'free'}) async {
    try {
      await _supabase.from('club_books').insert({
        'club_id': clubId,
        'book_id': bookId,
        'access_level': accessLevel,
        // added_at will be set automatically by the table default
      });
      return true;
    } catch (e) {
      print('Error adding book to club: $e');
      return false;
    }
  }

  Future<bool> removeBookFromClub(String clubId, String bookId) async {
    try {
      print('🗑️ Attempting to remove book $bookId from club $clubId');
      
      // First verify the record exists
      final existingRecord = await _supabase
          .from('club_books')
          .select()
          .eq('club_id', clubId)
          .eq('book_id', bookId)
          .maybeSingle();
      
      if (existingRecord == null) {
        print('⚠️ No club_books record found for club $clubId and book $bookId');
        return false;
      }
      
      print('✓ Found existing record: ${existingRecord['id']}');
      
      // Perform the deletion
      await _supabase
          .from('club_books')
          .delete()
          .eq('club_id', clubId)
          .eq('book_id', bookId);
      
      print('✅ Successfully removed book from club');
      return true;
    } catch (e) {
      print('❌ Error removing book from club: $e');
      print('Club ID: $clubId');
      print('Book ID: $bookId');
      return false;
    }
  }

  // Club Memberships Management
Future<List<ClubMembership>> getClubMembers(String clubId, {bool activeOnly = false}) async {
  try {
    print('Loading members for club ID: $clubId');
    
    // First, get club memberships without joins
    var query = _supabase
        .from('club_memberships')
        .select('*')
        .eq('club_id', clubId);

    if (activeOnly) {
      query = query.eq('status', 'active');
    }

    final membershipResponse = await query.order('joined_at', ascending: false);
    print('Found ${membershipResponse.length} memberships');

    if (membershipResponse.isEmpty) {
      return [];
    }

    // Get club details
    final clubResponse = await _supabase
        .from('clubs')
        .select('name, cover_image_url, is_premium')
        .eq('id', clubId)
        .single();

    List<ClubMembership> memberships = [];

    // For each membership, get user details
    for (var membership in membershipResponse) {
      final userId = membership['user_id'];
      
      // Get user details from users table
      final userResponse = await _supabase
          .from('users')
          .select('first_name, last_name, email, photo_url, username, contact_no')
          .eq('id', userId)
          .maybeSingle();

      memberships.add(ClubMembership.fromJson({
        ...membership,
        'user_first_name': userResponse?['first_name'] ?? 'User',
        'user_last_name': userResponse?['last_name'] ?? '',
        'user_email': userResponse?['email'] ?? '',
        'user_photo_url': userResponse?['photo_url'],
        'user_username': userResponse?['username'],
        'user_contact_no': userResponse?['contact_no'],
        'club_name': clubResponse['name'],
        'club_cover_url': clubResponse['cover_image_url'],
        'club_is_premium': clubResponse['is_premium'],
      }));
    }

    print('Successfully loaded ${memberships.length} members with user details');
    return memberships;
  } catch (e) {
    print('Error fetching club members: $e');
    print('Detailed error: ${e.toString()}');
    return [];
  }
}


Future<List<ClubMembership>> getUserMemberships(String userId) async {
  try {
    final response = await _supabase
        .from('club_memberships')
        .select('''
          *,
          clubs!club_memberships_club_id_fkey(
            name, cover_image_url, is_premium
          )
        ''')
        .eq('user_id', userId)
        // Remove the status filter to get ALL memberships (active, pending, etc.)
        .order('joined_at', ascending: false);

    return response.map<ClubMembership>((json) {
      return ClubMembership.fromJson({
        ...json,
        'club_name': json['clubs']?['name'],
        'club_cover_url': json['clubs']?['cover_image_url'],
        'club_is_premium': json['clubs']?['is_premium'],
      });
    }).toList();
  } catch (e) {
    print('Error fetching user memberships: $e');
    return [];
  }
}


Future<ClubMembership?> joinClub({
  required String clubId,
  required String userId,
  required MembershipType membershipType,
  bool isPendingApproval = false, // New parameter for pending approval
}) async {
  try {
    // Check if user is already a member
    final existing = await _supabase
        .from('club_memberships')
        .select('*')
        .eq('club_id', clubId)
        .eq('user_id', userId)
        .maybeSingle();

    if (existing != null) {
      print('User is already a member of this club');
      // Reactivate if cancelled
      if (existing['status'] == 'cancelled') {
        final status = isPendingApproval ? 'pending' : 'active';
        final updated = await _supabase
            .from('club_memberships')
            .update({
              'status': status,
              'membership_type': membershipType == MembershipType.premium ? 'premium' : 'free',
              'joined_at': DateTime.now().toIso8601String(),
              'expires_at': membershipType == MembershipType.premium
                  ? DateTime.now().add(const Duration(days: 30)).toIso8601String()
                  : null,
            })
            .eq('id', existing['id'])
            .select('''
              *,
              clubs!club_memberships_club_id_fkey(name, cover_image_url, is_premium)
            ''')
            .single();

        return ClubMembership.fromJson({
          ...updated,
          'club_name': updated['clubs']?['name'],
          'club_cover_url': updated['clubs']?['cover_image_url'],
          'club_is_premium': updated['clubs']?['is_premium'],
        });
      } else {
        // Return existing membership as is
        return ClubMembership.fromJson(existing);
      }
    }

    // Create new membership
    final status = isPendingApproval ? 'pending' : 'active';
    final membershipData = {
      'club_id': clubId,
      'user_id': userId,
      'membership_type': membershipType == MembershipType.premium ? 'premium' : 'free',
      'status': status,
      'joined_at': DateTime.now().toIso8601String(),
      'expires_at': membershipType == MembershipType.premium
          ? DateTime.now().add(const Duration(days: 30)).toIso8601String()
          : null,
    };

    final response = await _supabase
        .from('club_memberships')
        .insert(membershipData)
        .select('''
          *,
          clubs!club_memberships_club_id_fkey(name, cover_image_url, is_premium)
        ''')
        .single();

    return ClubMembership.fromJson({
      ...response,
      'club_name': response['clubs']?['name'],
      'club_cover_url': response['clubs']?['cover_image_url'],
      'club_is_premium': response['clubs']?['is_premium'],
    });
  } catch (e) {
    print('Error joining club: $e');
    return null;
  }
}

  // Author Earnings
  Future<AuthorEarnings?> getAuthorEarnings(String authorId) async {
    try {
      // Get author's clubs
      final clubsResponse = await _supabase
          .from('clubs')
          .select('id, name')
          .eq('author_id', authorId)
          .eq('is_active', true);

      if (clubsResponse.isEmpty) {
        return AuthorEarnings(
          authorId: authorId,
          totalEarnings: 0.0,
          monthlyEarnings: 0.0,
          totalMembers: 0,
          premiumMembers: 0,
          activeClubs: 0,
          earningsByClub: {},
          membersByClub: {},
          recentTransactions: [],
        );
      }

      final clubIds = clubsResponse.map((c) => c['id']).toList();

      // Get payments for author's clubs
      final paymentsResponse = await _supabase
          .from('club_payments')
          .select('''
            *,
            clubs!club_payments_club_id_fkey(name)
          ''')
          .inFilter('club_id', clubIds)
          .eq('status', 'completed')
          .order('created_at', ascending: false);

      // Calculate earnings (80% to author)
      double totalEarnings = 0.0;
      double monthlyEarnings = 0.0;
      Map<String, double> earningsByClub = {};
      List<EarningsTransaction> recentTransactions = [];

      final now = DateTime.now();
      final monthStart = DateTime(now.year, now.month, 1);

      for (final payment in paymentsResponse) {
        final amount = (payment['amount'] as num).toDouble();
        final authorShare = amount * 0.8; // 80% to author
        final clubId = payment['club_id'] as String;
        final clubName = payment['clubs']['name'] as String;
        final createdAt = DateTime.parse(payment['created_at']);

        totalEarnings += authorShare;
        
        if (createdAt.isAfter(monthStart)) {
          monthlyEarnings += authorShare;
        }

        // Earnings by club
        earningsByClub[clubName] = (earningsByClub[clubName] ?? 0.0) + authorShare;

        // Recent transactions (last 10)
        if (recentTransactions.length < 10) {
          recentTransactions.add(EarningsTransaction(
            id: payment['id'],
            clubId: clubId,
            clubName: clubName,
            userId: payment['user_id'],
            userName: '${payment['users']['first_name']} ${payment['users']['last_name']}',
            amount: authorShare,
            date: createdAt,
            type: 'membership',
          ));
        }
      }

      // Get membership counts
      final membershipsResponse = await _supabase
          .from('club_memberships')
          .select('club_id, membership_type')
          .inFilter('club_id', clubIds)
          .eq('status', 'active');

      Map<String, int> membersByClub = {};
      int totalMembers = 0;
      int premiumMembers = 0;

      for (final membership in membershipsResponse) {
        final clubId = membership['club_id'] as String;
        final clubName = clubsResponse
            .firstWhere((c) => c['id'] == clubId)['name'] as String;
        
        membersByClub[clubName] = (membersByClub[clubName] ?? 0) + 1;
        totalMembers++;
        
        if (membership['membership_type'] == 'premium') {
          premiumMembers++;
        }
      }

      return AuthorEarnings(
        authorId: authorId,
        totalEarnings: totalEarnings,
        monthlyEarnings: monthlyEarnings,
        totalMembers: totalMembers,
        premiumMembers: premiumMembers,
        activeClubs: clubsResponse.length,
        earningsByClub: earningsByClub,
        membersByClub: membersByClub,
        recentTransactions: recentTransactions,
      );
    } catch (e) {
      print('Error fetching author earnings: $e');
      return null;
    }
  }

  // Search and Filter
  Future<List<Club>> searchClubs(String query) async {
    try {
      final response = await _supabase
          .from('clubs')
          .select('''
            *,
            authors!clubs_author_id_fkey(first_name, last_name, photo_url)
          ''')
          .ilike('name', '%$query%')
          .eq('is_active', true)
          .limit(20);

      return response.map<Club>((json) {
        return Club.fromJson({
          ...json,
          'author_first_name': json['authors']?['first_name'],
          'author_last_name': json['authors']?['last_name'],
          'author_photo_url': json['authors']?['photo_url'],
        });
      }).toList();
    } catch (e) {
      print('Error searching clubs: $e');
      return [];
    }
  }

  // Member Management
  Future<bool> updateMembershipStatus({
    required String membershipId,
    required MembershipStatus status,
  }) async {
    try {
      await _supabase
          .from('club_memberships')
          .update({
            'status': _membershipStatusToString(status),
          })
          .eq('id', membershipId);

      return true;
    } catch (e) {
      print('Error updating membership status: $e');
      return false;
    }
  }

  Future<bool> removeMemberFromClub({
    required String clubId,
    required String userId,
  }) async {
    try {
      await _supabase
          .from('club_memberships')
          .update({
            'status': 'cancelled',
          })
          .eq('club_id', clubId)
          .eq('user_id', userId);

      return true;
    } catch (e) {
      print('Error removing member from club: $e');
      return false;
    }
  }

  Future<bool> deleteMemberFromClub({
    required String clubId,
    required String userId,
  }) async {
    try {
      await _supabase
          .from('club_memberships')
          .delete()
          .eq('club_id', clubId)
          .eq('user_id', userId);

      return true;
    } catch (e) {
      print('Error deleting member from club: $e');
      return false;
    }
  }

  Future<bool> deleteMembershipById(String membershipId) async {
    try {
      await _supabase
          .from('club_memberships')
          .delete()
          .eq('id', membershipId);

      return true;
    } catch (e) {
      print('Error deleting membership: $e');
      return false;
    }
  }

  // New methods for membership approval/rejection
  Future<bool> approveMembership(String membershipId) async {
    try {
      await _supabase
          .from('club_memberships')
          .update({
            'status': 'active',
            'joined_at': DateTime.now().toIso8601String(), // Update join date to approval date
          })
          .eq('id', membershipId);

      print('✅ Membership approved: $membershipId');
      return true;
    } catch (e) {
      print('❌ Error approving membership: $e');
      return false;
    }
  }

  Future<bool> rejectMembership(String membershipId) async {
    try {
      // When rejecting, we can either delete the membership or mark as cancelled
      // For audit purposes, let's mark as cancelled
      await _supabase
          .from('club_memberships')
          .update({
            'status': 'cancelled',
          })
          .eq('id', membershipId);

      print('✅ Membership rejected: $membershipId');
      return true;
    } catch (e) {
      print('❌ Error rejecting membership: $e');
      return false;
    }
  }

  // Get payment information for a member
  Future<Map<String, dynamic>?> getMemberPaymentInfo(String userId, String clubId) async {
    try {
      final paymentResponse = await _supabase
          .from('club_payments')
          .select('*')
          .eq('user_id', userId)
          .eq('club_id', clubId)
          .eq('status', 'completed')
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      return paymentResponse;
    } catch (e) {
      print('Error getting member payment info: $e');
      return null;
    }
  }

  // New method to handle user leaving a club
  Future<bool> leaveClub({
    required String clubId,
    required String userId,
  }) async {
    try {
      print('🚪 User $userId leaving club $clubId');

      // First, delete payment records for this user-club combination
      await _supabase
          .from('club_payments')
          .delete()
          .eq('user_id', userId)
          .eq('club_id', clubId);
      
      print('💳 Deleted payment records');

      // Then, delete the membership record
      await _supabase
          .from('club_memberships')
          .delete()
          .eq('user_id', userId)
          .eq('club_id', clubId);

      print('✅ User successfully left the club');
      return true;
    } catch (e) {
      print('❌ Error leaving club: $e');
      return false;
    }
  }

  String _membershipStatusToString(MembershipStatus status) {
    switch (status) {
      case MembershipStatus.active:
        return 'active';
      case MembershipStatus.expired:
        return 'expired';
      case MembershipStatus.cancelled:
        return 'cancelled';
      case MembershipStatus.pending:
        return 'pending';
    }
  }
}
