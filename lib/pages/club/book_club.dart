import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_sslcommerz/model/SSLCSdkType.dart';
import 'package:flutter_sslcommerz/model/SSLCommerzInitialization.dart';
import 'package:flutter_sslcommerz/model/SSLCurrencyType.dart';
import 'package:flutter_sslcommerz/sslcommerz.dart';
import '../../models/club_model.dart';
import '../../models/club_membership_model.dart';
import '../../models/club_payment_model.dart';
import '../../services/club_service.dart';
import '../../services/payment_service.dart';
import 'club_detail_page.dart';

// A StatefulWidget to provide a fade-in animation for its child.
class FadeInAnimation extends StatefulWidget {
  final Widget child;
  final Duration duration;

  const FadeInAnimation({
    Key? key,
    required this.child,
    this.duration = const Duration(milliseconds: 500),
  }) : super(key: key);

  @override
  State<FadeInAnimation> createState() => _FadeInAnimationState();
}

class _FadeInAnimationState extends State<FadeInAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);
    _opacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(opacity: _opacity, child: widget.child);
  }
}

class BookClubPage extends StatefulWidget {
  const BookClubPage({Key? key}) : super(key: key);

  @override
  State<BookClubPage> createState() => _BookClubPageState();
}

class _BookClubPageState extends State<BookClubPage> {
  final TextEditingController _searchController = TextEditingController();
  final ClubService _clubService = ClubService();
  final PaymentService _paymentService = PaymentService();
  
  List<Club> _allClubs = [];
  List<Club> _filteredClubs = [];
  bool _isLoading = true;
  String _selectedFilter = 'All';
  String _searchText = '';
  
  // Track user's club memberships
  List<String> _userJoinedClubs = [];
  // Track user's pending memberships
  List<String> _userPendingClubs = [];
  
  // Add user data properties
  Map<String, dynamic>? _userData;
  bool _isLoadingUser = false;

  final List<String> _filters = ['All', 'Free', 'Premium', 'My Clubs'];

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadClubs();
    _loadUserMemberships();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoadingUser = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        try {
          final response = await Supabase.instance.client
              .from('users')
              .select()
              .eq('id', user.id)
              .single();
          
          setState(() {
            _userData = response;
          });
          print('Successfully loaded user data from users table');
        } catch (userError) {
          print('Could not load from users table: $userError');
          // Fallback to auth metadata
          setState(() {
            _userData = {
              'full_name': user.userMetadata?['full_name'] ?? user.userMetadata?['name'] ?? 'User',
              'email': user.email,
              'photo_url': user.userMetadata?['avatar_url'],
            };
          });
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
    } finally {
      setState(() => _isLoadingUser = false);
    }
  }

  Future<void> _loadClubs() async {
    setState(() => _isLoading = true);
    
    try {
      final clubs = await _clubService.getAllActiveClubs();
      setState(() {
        _allClubs = clubs;
        _filteredClubs = clubs;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading clubs: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading clubs: $e')),
        );
      }
    }
  }

  Future<void> _loadUserMemberships() async {
    try {
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser != null) {
        final memberships = await _clubService.getUserMemberships(currentUser.id);
        print('📋 Loaded ${memberships.length} memberships for user');
        
        // Debug: Print all memberships
        for (var membership in memberships) {
          print('   📝 Membership: club=${membership.clubId}, status=${membership.status}, type=${membership.membershipType}');
          print('      isActive=${membership.isActive}, isPending=${membership.isPending}');
        }
        
        setState(() {
          // Track active memberships (can access club)
          _userJoinedClubs = memberships
              .where((membership) => membership.isActive)
              .map((membership) => membership.clubId)
              .toList();
          
          // Track pending memberships (waiting for approval)
          _userPendingClubs = memberships
              .where((membership) => membership.isPending)
              .map((membership) => membership.clubId)
              .toList();
        });
        
        print('✅ Active clubs: ${_userJoinedClubs.length}');
        print('⏳ Pending clubs: ${_userPendingClubs.length}');
        for (var clubId in _userPendingClubs) {
          print('   - Pending: $clubId');
        }
      }
    } catch (e) {
      print('Error loading user memberships: $e');
    }
  }

  bool _isUserJoinedClub(String clubId) {
    return _userJoinedClubs.contains(clubId);
  }

  bool _hasUserPendingMembership(String clubId) {
    return _userPendingClubs.contains(clubId);
  }

  void _applyFilters() {
    setState(() {
      _filteredClubs = _allClubs.where((club) {
        // Search filter
        final searchLower = _searchText.toLowerCase();
        final matchesSearch = club.name.toLowerCase().contains(searchLower) ||
            club.description.toLowerCase().contains(searchLower) ||
            club.authorFullName.toLowerCase().contains(searchLower);
        
        // Category filter
        bool matchesFilter = true;
        switch (_selectedFilter) {
          case 'Free':
            matchesFilter = !club.isPremium;
            break;
          case 'Premium':
            matchesFilter = club.isPremium;
            break;
          case 'My Clubs':
            // TODO: Filter by current user's clubs
            matchesFilter = true;
            break;
          case 'All':
          default:
            matchesFilter = true;
        }
        
        return matchesSearch && matchesFilter;
      }).toList();
    });
  }

  Future<void> _joinClub(Club club) async {
    try {
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please login to join clubs'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      if (club.isPremium && club.membershipPrice > 0) {
        // Show payment dialog for premium clubs
        await _showPaymentDialog(club);
      } else {
        // Join free club directly
        await _clubService.joinClub(
          clubId: club.id,
          userId: currentUser.id,
          membershipType: MembershipType.free,
        );
        
        // Refresh user memberships
        await _loadUserMemberships();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Successfully joined ${club.name}!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      print('Error joining club: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error joining club: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _visitClub(Club club) async {
    // Navigate to club detail page showing club books
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ClubDetailPage(club: club),
      ),
    );
  }

  Future<void> _showPaymentDialog(Club club) async {
    bool isProcessing = false;
    
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text('Join ${club.name}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Membership Fee: ৳${club.membershipPrice.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF023E8A),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Payment Methods:',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    Chip(
                      label: const Text('bKash'),
                      backgroundColor: Colors.pink[100],
                      avatar: const Icon(Icons.payment, size: 16),
                    ),
                    Chip(
                      label: const Text('Nagad'),
                      backgroundColor: Colors.orange[100],
                      avatar: const Icon(Icons.payment, size: 16),
                    ),
                    Chip(
                      label: const Text('Rocket'),
                      backgroundColor: Colors.purple[100],
                      avatar: const Icon(Icons.payment, size: 16),
                    ),
                    Chip(
                      label: const Text('Card'),
                      backgroundColor: Colors.blue[100],
                      avatar: const Icon(Icons.credit_card, size: 16),
                    ),
                  ],
                ),
                if (isProcessing) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: const Row(
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Processing payment...\nPlease complete the payment in the SSL Commerz window.',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: isProcessing ? null : () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: isProcessing ? null : () async {
                  setDialogState(() => isProcessing = true);
                  
                  Navigator.pop(context);
                  await _processPayment(club);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0096C7),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: isProcessing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Pay Now',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _processPayment(Club club) async {
    try {
      final currentUser = Supabase.instance.client.auth.currentUser!;
      
      // Generate a unique transaction ID using timestamp
      final tranId = "CLUB_${club.id.substring(0, 8)}_${DateTime.now().millisecondsSinceEpoch}";
      
      // First create a club membership record with pending status for premium clubs
      final membership = await _clubService.joinClub(
        clubId: club.id,
        userId: currentUser.id,
        membershipType: MembershipType.premium,
        isPendingApproval: true, // Premium clubs require approval
      );

      if (membership == null) {
        throw Exception('Failed to create club membership');
      }

      // Create payment record in database
      final payment = await _paymentService.createPayment(
        membershipId: membership.id,
        userId: currentUser.id,
        clubId: club.id,
        amount: club.membershipPrice,
        paymentMethod: PaymentMethod.card,
      );

      if (payment == null) {
        throw Exception('Failed to create payment record');
      }

      // Initialize SSL Commerz payment
      Sslcommerz sslcommerz = Sslcommerz(
        initializer: SSLCommerzInitialization(
          multi_card_name: "visa,master,bkash,nagad,rocket",
          currency: SSLCurrencyType.BDT,
          product_category: "Club Membership",
          sdkType: SSLCSdkType.TESTBOX, // Use TESTBOX for development
          store_id: "wrist6830197f2308c",
          store_passwd: "wrist6830197f2308c@ssl",
          total_amount: club.membershipPrice,
          tran_id: tranId,
        ),
      );

      // Process payment with SSL Commerz
      final response = await sslcommerz.payNow();

      if (mounted) {
        if (response.status == 'VALID') {
          // Payment successful
          try {
            // Update payment record with transaction details
            await _paymentService.completePayment(
              paymentId: payment.id,
              transactionId: response.tranId!,
              additionalData: {
                'bank_tran_id': response.bankTranId,
                'card_type': response.cardType,
                'card_no': response.cardNo,
                'amount': response.amount,
                'status': response.status,
              },
            );

            // Refresh user memberships BEFORE showing success message
            await _loadUserMemberships();
            
            // Show success message with pending approval notice
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.payment, color: Colors.white),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Payment successful for ${club.name}!'),
                          Text(
                            'Your membership is pending author approval.',
                            style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.9)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                backgroundColor: Colors.blue,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 5),
              ),
            );

            // Force a state update to refresh the UI
            setState(() {
              // This will trigger a rebuild and show the pending status
            });

          } catch (e) {
            print('Error completing payment: $e');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.warning, color: Colors.white),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text('Payment successful but there was an issue: $e'),
                    ),
                  ],
                ),
                backgroundColor: Colors.orange,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
          
        } else if (response.status == 'FAILED') {
          // Payment failed
          await _paymentService.failPayment(
            paymentId: payment.id,
            reason: 'Payment failed in SSL Commerz',
          );
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.white),
                  SizedBox(width: 10),
                  Text('Payment failed. Please try again.'),
                ],
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
          
        } else if (response.status == 'CLOSED') {
          // Payment window closed
          await _paymentService.failPayment(
            paymentId: payment.id,
            reason: 'Payment window closed by user',
          );
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.white),
                  SizedBox(width: 10),
                  Text('Payment window closed. You can try again anytime.'),
                ],
              ),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
      
    } catch (e) {
      print('Error processing payment: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('Error processing payment: ${e.toString()}'),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildUserAvatar() {
    final user = Supabase.instance.client.auth.currentUser;
    
    if (_isLoadingUser) {
      return Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: const Color(0xFF0096C7),
            width: 3,
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: const CircleAvatar(
          radius: 36,
          backgroundColor: Colors.white,
          child: CircularProgressIndicator(
            color: Color(0xFF0096C7),
            strokeWidth: 2,
          ),
        ),
      );
    }

    String? photoURL = _userData?['photo_url'] ?? 
                      _userData?['avatar_url'] ?? 
                      user?.userMetadata?['avatar_url'];
    
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: const Color(0xFF0096C7),
          width: 3,
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: CircleAvatar(
        radius: 36,
        backgroundColor: Colors.white,
        backgroundImage: photoURL != null && photoURL.isNotEmpty 
            ? NetworkImage(photoURL) 
            : null,
        onBackgroundImageError: photoURL != null ? (exception, stackTrace) {
          print('Failed to load profile image: $exception');
        } : null,
        child: photoURL == null || photoURL.isEmpty
            ? Icon(
                Icons.person,
                size: 36,
                color: const Color(0xFF0096C7),
              )
            : null,
      ),
    );
  }

  String _getPersonalizedGreeting() {
    if (_isLoadingUser) {
      return 'Loading...';
    }
    
    final user = Supabase.instance.client.auth.currentUser;
    String userName = 'Explorer';
    
    if (user != null) {
      // Try to get name from user data
      if (_userData?['first_name'] != null || _userData?['last_name'] != null) {
        final firstName = _userData?['first_name'] ?? '';
        final lastName = _userData?['last_name'] ?? '';
        userName = '$firstName $lastName'.trim();
      } else if (_userData?['full_name'] != null) {
        userName = _userData!['full_name'];
      } else if (user.userMetadata?['full_name'] != null) {
        userName = user.userMetadata!['full_name'];
      } else if (user.userMetadata?['name'] != null) {
        userName = user.userMetadata!['name'];
      } else if (user.email != null) {
        userName = user.email!.split('@')[0].replaceAll(RegExp(r'[^a-zA-Z]'), ' ').trim();
      }
    }
    
    // Get only first name for greeting
    final firstName = userName.split(' ').first;
    return 'Hi $firstName, Discover Book Clubs';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FB),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadClubs,
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 18),
            children: [
              // Header Row (avatar + header)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _buildUserAvatar(),
                    const SizedBox(width: 24),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getPersonalizedGreeting(),
                            style: GoogleFonts.montserrat(
                              fontWeight: FontWeight.bold,
                              fontSize: 26,
                              color: const Color(0xFF023E8A),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Join communities around your favorite books',
                            style: TextStyle(
                              color: Colors.blueGrey[600],
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Featured Club Section
              if (_allClubs.isNotEmpty) ...[
                _SectionHeader(title: 'Featured Club'),
                _buildFeaturedClubCard(_allClubs.first),
                const SizedBox(height: 24),
              ],

              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Card(
                  elevation: 2,
                  shadowColor: Colors.black26,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            onChanged: (value) {
                              setState(() => _searchText = value);
                              _applyFilters();
                            },
                            decoration: const InputDecoration(
                              hintText: 'Search clubs or authors...',
                              prefixIcon: Icon(
                                Icons.search,
                                color: Color(0xFF0096C7),
                              ),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: _loadClubs,
                          icon: const Icon(Icons.refresh),
                          tooltip: 'Refresh clubs',
                          color: const Color(0xFF0077B6),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Filter Chips
              _SectionHeader(title: 'Filter Clubs'),
              _buildFilterChips(),
              const SizedBox(height: 28),

              _SectionHeader(title: 'All Book Clubs'),

              // Loading indicator or Club List
              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(
                      color: Color(0xFF0096C7),
                    ),
                  ),
                )
              else if (_filteredClubs.isEmpty)
                _buildEmptyState()
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _filteredClubs.length,
                  itemBuilder: (context, index) {
                    final club = _filteredClubs[index];
                    return FadeInAnimation(
                      child: Padding(
                        padding: const EdgeInsets.only(
                          bottom: 18,
                          left: 24,
                          right: 24,
                        ),
                        child: _buildClubCard(club),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  // A widget for displaying a styled section header.
  Widget _SectionHeader({required String title}) {
    return Padding(
      padding: const EdgeInsets.only(left: 24, right: 24, bottom: 12),
      child: Text(
        title,
        style: GoogleFonts.lato(
          fontWeight: FontWeight.bold,
          fontSize: 20,
          color: const Color(0xFF023E8A),
        ),
      ),
    );
  }

  // A widget to display when no clubs match the filter criteria.
  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.only(top: 50, bottom: 50),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.groups_outlined,
              size: 80,
              color: Colors.blueGrey[200],
            ),
            const SizedBox(height: 16),
            Text(
              'No Book Clubs Found',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey[400],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search or check back later for new clubs.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.blueGrey[300]),
            ),
          ],
        ),
      ),
    );
  }

  // A card widget to display a single club's information.
  Widget _buildClubCard(Club club) {
    return Card(
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Club Cover Image
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: club.coverImageUrl != null
                    ? Image.network(
                        club.coverImageUrl!,
                        width: 80,
                        height: 110,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            _buildClubPlaceholder(),
                      )
                    : _buildClubPlaceholder(),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Club name and premium badge
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            club.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Color(0xFF0077B6),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (club.isPremium) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFD700),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'PREMIUM',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF023E8A),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    
                    // Author name
                    Text(
                      'by ${club.authorFullName}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                        color: Colors.black54,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    
                    // Description
                    Flexible(
                      child: Text(
                        club.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black87,
                          height: 1.3,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Price and action button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Price section
                        Flexible(
                          flex: 1,
                          child: club.isPremium
                              ? Text(
                                  '৳${club.membershipPrice.toStringAsFixed(0)}/mo',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Color(0xFF0077B6),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                )
                              : const Text(
                                  'FREE',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Colors.green,
                                  ),
                                ),
                        ),
                        const SizedBox(width: 8),
                        
                        // Action button
                        Flexible(
                          flex: 1,
                          child: _buildActionButton(club),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Build action button based on membership status
  Widget _buildActionButton(Club club) {
    final isJoined = _isUserJoinedClub(club.id);
    final hasPending = _hasUserPendingMembership(club.id);
    
    print('🔍 Club ${club.name} (${club.id}):');
    print('   - isJoined: $isJoined');
    print('   - hasPending: $hasPending');
    
    if (isJoined) {
      // User is already a member - show "Visit Club" button
      return ElevatedButton(
        onPressed: () => _visitClub(club),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF28A745), // Green for joined
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 6,
          ),
          minimumSize: const Size(0, 32),
        ),
        child: const Text(
          'Visit',
          style: TextStyle(fontSize: 12),
        ),
      );
    } else {
      // Check if user has pending membership for this club
      final hasPendingMembership = _hasUserPendingMembership(club.id);
      
      if (hasPendingMembership) {
        // User has pending membership - show pending status
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.orange[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.orange[300]!),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.hourglass_empty, size: 12, color: Colors.orange[700]),
              const SizedBox(width: 4),
              Text(
                'Pending',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.orange[700],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      } else {
        // User is not a member - show join button
        return ElevatedButton(
          onPressed: () => _joinClub(club),
          style: ElevatedButton.styleFrom(
            backgroundColor: club.isPremium 
                ? const Color(0xFFFFD700)
                : const Color(0xFFADE8F4),
            foregroundColor: const Color(0xFF023E8A),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 6,
            ),
            minimumSize: const Size(0, 32),
          ),
          child: Text(
            club.isPremium ? 'Join' : 'Join',
            style: const TextStyle(fontSize: 12),
          ),
        );
      }
    }
  }

  // Placeholder for club cover image
  Widget _buildClubPlaceholder() {
    return Container(
      width: 80,
      height: 110,
      decoration: BoxDecoration(
        color: const Color(0xFFADE8F4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(
        Icons.groups,
        size: 35,
        color: Color(0xFF0077B6),
      ),
    );
  }

  // A widget for the horizontal list of filter chips.
  Widget _buildFilterChips() {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: _filters.length,
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final isSelected = _selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: ChoiceChip(
              label: Text(filter),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedFilter = filter;
                  });
                  _applyFilters();
                }
              },
              backgroundColor: Colors.white,
              selectedColor: const Color(0xFF0096C7),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF023E8A),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected
                      ? const Color(0xFF0096C7)
                      : Colors.grey[300]!,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // A card to showcase a featured club
  Widget _buildFeaturedClubCard(Club club) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF0077B6), Color(0xFF00B4D8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0096C7).withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: club.coverImageUrl != null
                  ? Image.network(
                      club.coverImageUrl!,
                      width: 80,
                      height: 120,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          Container(
                            width: 80,
                            height: 120,
                            color: Colors.white.withOpacity(0.2),
                            child: const Icon(
                              Icons.groups,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                    )
                  : Container(
                      width: 80,
                      height: 120,
                      color: Colors.white.withOpacity(0.2),
                      child: const Icon(
                        Icons.groups,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    club.name,
                    style: GoogleFonts.lato(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'by ${club.authorFullName}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    club.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (club.isPremium)
                        Text(
                          '৳${club.membershipPrice.toStringAsFixed(0)}/month',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        )
                      else
                        const Text(
                          'FREE TO JOIN',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      OutlinedButton(
                        onPressed: () {
                          if (_isUserJoinedClub(club.id)) {
                            _visitClub(club);
                          } else if (_hasUserPendingMembership(club.id)) {
                            // Show pending status message
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Your membership is pending author approval'),
                                backgroundColor: Colors.orange,
                              ),
                            );
                          } else {
                            _joinClub(club);
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          _isUserJoinedClub(club.id) 
                              ? 'Visit Club' 
                              : _hasUserPendingMembership(club.id)
                                  ? 'Pending'
                                  : 'Join Now',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
