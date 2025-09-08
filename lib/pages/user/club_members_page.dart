import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/club_model.dart';
import '../../models/club_membership_model.dart';
import '../../services/club_service.dart';

class ClubMembersPage extends StatefulWidget {
  final Club club;

  const ClubMembersPage({Key? key, required this.club}) : super(key: key);

  @override
  State<ClubMembersPage> createState() => _ClubMembersPageState();
}

class _ClubMembersPageState extends State<ClubMembersPage> {
  final ClubService _clubService = ClubService();
  List<ClubMembership> _members = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _loadMembers();
    _checkDatabaseState(); // Check database on load
  }

  Future<void> _loadMembers() async {
    setState(() => _isLoading = true);
    try {
      print('Loading members for club ID: ${widget.club.id}');
      print('Club name: ${widget.club.name}');
      
      // Get all members (not just active ones) to show complete member list
      final members = await _clubService.getClubMembers(widget.club.id);
      
      print('Found ${members.length} members');
      for (var member in members) {
        print('Member: ${member.userFirstName} ${member.userLastName}, Status: ${member.status}');
      }
      
      setState(() {
        _members = members;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading members: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading members: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<ClubMembership> get _filteredMembers {
    List<ClubMembership> filtered = _members.where((member) {
      final fullName = '${member.userFirstName ?? ''} ${member.userLastName ?? ''}'.trim();
      final matchesSearch = fullName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                           (member.userEmail?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
      
      final matchesFilter = _selectedFilter == 'All' ||
                           (_selectedFilter == 'Premium' && member.membershipType == MembershipType.premium) ||
                           (_selectedFilter == 'Free' && member.membershipType == MembershipType.free) ||
                           (_selectedFilter == 'Active' && member.status == MembershipStatus.active) ||
                           (_selectedFilter == 'Expired' && member.status == MembershipStatus.expired) ||
                           (_selectedFilter == 'Cancelled' && member.status == MembershipStatus.cancelled);
      
      return matchesSearch && matchesFilter;
    }).toList();

    // Sort by join date (newest first)
    filtered.sort((a, b) => b.joinedAt.compareTo(a.joinedAt));
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text('${widget.club.name} - Members'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMembers,
          ),
        ],
      ),
      body: Column(
        children: [
          // Header with stats
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                // Stats row
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Total',
                        _members.length.toString(),
                        Icons.people,
                        Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildStatCard(
                        'Active',
                        _members.where((m) => m.status == MembershipStatus.active).length.toString(),
                        Icons.check_circle,
                        Colors.green,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildStatCard(
                        'Premium',
                        _members.where((m) => m.membershipType == MembershipType.premium && m.status == MembershipStatus.active).length.toString(),
                        Icons.star,
                        Colors.amber,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildStatCard(
                        'Cancelled',
                        _members.where((m) => m.status == MembershipStatus.cancelled).length.toString(),
                        Icons.cancel_outlined,
                        Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Search and filter
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        decoration: const InputDecoration(
                          hintText: 'Search members...',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: Color(0xFFF1F5F9),
                        ),
                        onChanged: (value) => setState(() => _searchQuery = value),
                      ),
                    ),
                    const SizedBox(width: 12),
                    DropdownButton<String>(
                      value: _selectedFilter,
                      items: ['All', 'Premium', 'Free', 'Active', 'Expired', 'Cancelled']
                          .map((filter) => DropdownMenuItem(
                                value: filter,
                                child: Text(filter),
                              ))
                          .toList(),
                      onChanged: (value) => setState(() => _selectedFilter = value!),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Members list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredMembers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.people_outline, size: 80, color: Colors.grey),
                            const SizedBox(height: 16),
                            Text(
                              _members.isEmpty 
                                  ? 'No members yet'
                                  : 'No members match your search',
                              style: const TextStyle(fontSize: 18, color: Colors.grey),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _members.isEmpty 
                                  ? 'Members will appear here when they join your club'
                                  : 'Try adjusting your search or filter settings',
                              style: const TextStyle(fontSize: 14, color: Colors.grey),
                              textAlign: TextAlign.center,
                            ),
                            if (_members.isEmpty) ...[
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _createSampleMembership,
                                child: const Text('Create Sample Membership (Debug)'),
                              ),
                            ],
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredMembers.length,
                        itemBuilder: (context, index) {
                          final member = _filteredMembers[index];
                          return _buildMemberCard(member);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMemberCard(ClubMembership member) {
    final isExpired = member.status == MembershipStatus.expired;
    final isCancelled = member.status == MembershipStatus.cancelled;
    final isActive = member.status == MembershipStatus.active;
    final isPremium = member.membershipType == MembershipType.premium;
    final fullName = '${member.userFirstName ?? ''} ${member.userLastName ?? ''}'.trim();
    final displayName = fullName.isEmpty ? 'Unknown User' : fullName;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isCancelled ? Colors.grey[50] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isCancelled ? Border.all(color: Colors.grey[300]!, width: 1) : null,
        boxShadow: isCancelled ? [] : [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 24,
              backgroundColor: isCancelled 
                  ? Colors.grey[300]
                  : isPremium 
                      ? Colors.amber[100] 
                      : Colors.blue[100],
              child: Text(
                displayName.substring(0, 1).toUpperCase(),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isCancelled 
                      ? Colors.grey[600]
                      : isPremium 
                          ? Colors.amber[700] 
                          : Colors.blue[700],
                ),
              ),
            ),
            const SizedBox(width: 16),
            
            // Member info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          displayName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: isCancelled ? Colors.grey[600] : Colors.black87,
                          ),
                        ),
                      ),
                      if (isPremium && !isCancelled)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.amber,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.star, size: 14, color: Colors.white),
                              SizedBox(width: 4),
                              Text(
                                'Premium',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    member.userEmail ?? 'No email',
                    style: TextStyle(
                      color: isCancelled ? Colors.grey[500] : Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Status and dates
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isCancelled 
                              ? Colors.grey[200]
                              : isExpired 
                                  ? Colors.red[100] 
                                  : Colors.green[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          member.status.toString().split('.').last.toUpperCase(),
                          style: TextStyle(
                            color: isCancelled 
                                ? Colors.grey[700]
                                : isExpired 
                                    ? Colors.red[700] 
                                    : Colors.green[700],
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Joined: ${_formatDate(member.joinedAt)}',
                        style: TextStyle(
                          fontSize: 12, 
                          color: isCancelled ? Colors.grey[500] : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  
                  if (isPremium && member.expiresAt != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Expires: ${_formatDate(member.expiresAt!)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isExpired 
                            ? Colors.red 
                            : isCancelled 
                                ? Colors.grey[500] 
                                : Colors.grey,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            // Actions - only show for active members
            if (isActive)
              PopupMenuButton<String>(
                onSelected: (value) => _handleMemberAction(value, member),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'view_profile',
                    child: Row(
                      children: [
                        Icon(Icons.person, size: 16),
                        SizedBox(width: 8),
                        Text('View Profile'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'send_message',
                    child: Row(
                      children: [
                        Icon(Icons.message, size: 16),
                        SizedBox(width: 8),
                        Text('Send Message'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'remove_member',
                    child: Row(
                      children: [
                        Icon(Icons.remove_circle, size: 16, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Remove Member', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              )
            else
              // Show status icon for inactive members
              Icon(
                isCancelled ? Icons.cancel_outlined : Icons.access_time,
                color: Colors.grey[400],
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _createSampleMembership() async {
    try {
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No user logged in'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      print('Current user ID: ${currentUser.id}');
      print('Creating membership for club: ${widget.club.id}');

      // First check if club_memberships table exists and if there's any data
      await _checkDatabaseState();

      // Create a sample membership
      final membership = await _clubService.joinClub(
        clubId: widget.club.id,
        userId: currentUser.id,
        membershipType: MembershipType.free,
      );

      if (membership != null) {
        print('Sample membership created: ${membership.id}');
        await _loadMembers(); // Refresh the list
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sample membership created successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception('Failed to create sample membership');
      }
    } catch (e) {
      print('Error creating sample membership: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _checkDatabaseState() async {
    try {
      // Check if there are any club memberships at all
      final response = await Supabase.instance.client
          .from('club_memberships')
          .select('*');
      
      print('Total club memberships in database: ${response.length}');

      // Check if there are memberships for this specific club
      final clubResponse = await Supabase.instance.client
          .from('club_memberships')
          .select('*')
          .eq('club_id', widget.club.id);
      
      print('Memberships for this club: ${clubResponse.length}');
      
    } catch (e) {
      print('Error checking database state: $e');
      // Table might not exist
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Database error: $e\nMake sure to run the database migration first!'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _handleMemberAction(String action, ClubMembership member) {
    final fullName = '${member.userFirstName ?? ''} ${member.userLastName ?? ''}'.trim();
    final displayName = fullName.isEmpty ? 'Unknown User' : fullName;
    
    switch (action) {
      case 'view_profile':
        // TODO: Navigate to member profile
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Viewing $displayName\'s profile')),
        );
        break;
      case 'send_message':
        // TODO: Open messaging interface
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Messaging $displayName')),
        );
        break;
      case 'remove_member':
        _showRemoveMemberDialog(member);
        break;
    }
  }

  Future<void> _removeMemberFromClub(ClubMembership member) async {
    try {
      // Update member status to 'cancelled' instead of deleting
      final success = await _clubService.updateMembershipStatus(
        membershipId: member.id,
        status: MembershipStatus.cancelled,
      );

      if (success) {
        await _loadMembers(); // Refresh the list
        if (mounted) {
          final fullName = '${member.userFirstName ?? ''} ${member.userLastName ?? ''}'.trim();
          final displayName = fullName.isEmpty ? 'Unknown User' : fullName;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$displayName has been removed from the club'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception('Failed to remove member');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error removing member: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showRemoveMemberDialog(ClubMembership member) {
    final fullName = '${member.userFirstName ?? ''} ${member.userLastName ?? ''}'.trim();
    final displayName = fullName.isEmpty ? 'Unknown User' : fullName;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Member'),
        content: Text(
          'Are you sure you want to remove $displayName from ${widget.club.name}?\n\nThis action will cancel their membership.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _removeMemberFromClub(member);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remove', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
