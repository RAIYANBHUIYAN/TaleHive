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
      await _supabase
          .from('clubs')
          .update({'is_active': false})
          .eq('id', clubId);
      return true;
    } catch (e) {
      print('Error deleting club: $e');
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
            books!club_books_book_id_fkey(title, cover_image_url, author_id, category, price, summary)
          ''')
          .eq('club_id', clubId)
          .order('added_at', ascending: false);

      return response.map<ClubBook>((json) {
        return ClubBook.fromJson({
          ...json,
          'book_title': json['books']?['title'],
          'book_cover_url': json['books']?['cover_image_url'],
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

  Future<bool> addBookToClub(String clubId, String bookId) async {
    try {
      await _supabase.from('club_books').insert({
        'club_id': clubId,
        'book_id': bookId,
        'added_at': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (e) {
      print('Error adding book to club: $e');
      return false;
    }
  }

  Future<bool> removeBookFromClub(String clubId, String bookId) async {
    try {
      await _supabase
          .from('club_books')
          .delete()
          .eq('club_id', clubId)
          .eq('book_id', bookId);
      return true;
    } catch (e) {
      print('Error removing book from club: $e');
      return false;
    }
  }

  // Club Memberships Management
Future<List<ClubMembership>> getClubMembers(String clubId, {bool activeOnly = false}) async {
  try {
    print('Loading members for club ID: $clubId');

    var query = _supabase
        .from('club_memberships')
        .select('''
          *,
          users!fk_club_memberships_user(
            first_name, last_name, email, photo_url, username, contact_no
          ),
          clubs!club_memberships_club_id_fkey(
            name, cover_image_url, is_premium
          )
        ''')
        .eq('club_id', clubId);

    if (activeOnly) {
      query = query.eq('status', 'active');
    }

    final response = await query.order('joined_at', ascending: false);

    print('Found ${response.length} members');

    return response.map<ClubMembership>((json) {
      return ClubMembership.fromJson({
        ...json,
        'user_first_name': json['users']?['first_name'],
        'user_last_name': json['users']?['last_name'],
        'user_email': json['users']?['email'],
        'user_photo_url': json['users']?['photo_url'],
        'user_username': json['users']?['username'],
        'user_contact_no': json['users']?['contact_no'],
        'club_name': json['clubs']?['name'],
        'club_cover_url': json['clubs']?['cover_image_url'],
        'club_is_premium': json['clubs']?['is_premium'],
      });
    }).toList();
  } catch (e) {
    print('Error fetching club members: $e');
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
        .eq('status', 'active')
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
        final updated = await _supabase
            .from('club_memberships')
            .update({
              'status': 'active',
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
    final membershipData = {
      'club_id': clubId,
      'user_id': userId,
      'membership_type': membershipType == MembershipType.premium ? 'premium' : 'free',
      'status': 'active',
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
            users!club_payments_user_id_fkey(first_name, last_name),
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
            'updated_at': DateTime.now().toIso8601String(),
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
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('club_id', clubId)
          .eq('user_id', userId);

      return true;
    } catch (e) {
      print('Error removing member from club: $e');
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
    }
  }
}
