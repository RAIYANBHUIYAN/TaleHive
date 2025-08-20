import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:async';
import '../main_home_page/main_page.dart';

class UserDashboardPage extends StatefulWidget {
  const UserDashboardPage({
    Key? key,
    required this.onMyBooksTap,
    required this.onEditProfileTap,
  }) : super(key: key);

  final VoidCallback onMyBooksTap;
  final VoidCallback onEditProfileTap;

  @override
  _UserDashboardPageState createState() => _UserDashboardPageState();
}

class _UserDashboardPageState extends State<UserDashboardPage> {
  final supabase = Supabase.instance.client;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final ImagePicker _picker = ImagePicker();
  Map<String, dynamic>? userData;
  bool _isUploadingImage = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    try {
      final user = supabase.auth.currentUser;
      if (user != null) {
        try {
          final userResponse = await supabase
              .from('users')
              .select()
              .eq('id', user.id)
              .single();

          setState(() {
            userData = userResponse;
          });
        } catch (e) {
          print('Error loading user data: $e');
          setState(() {
            userData = {
              'id': user.id,
              'email': user.email,
              'full_name': user.userMetadata?['full_name'] ?? user.userMetadata?['name'],
              'photo_url': user.userMetadata?['avatar_url'],
            };
          });
        }
      }
    } catch (e) {
      print('Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateProfileImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 70,
      );

      if (image == null) return;

      setState(() => _isUploadingImage = true);

      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final bytes = await File(image.path).readAsBytes();
      final fileExt = image.path.split('.').last;
      final fileName = '${user.id}/avatar_${DateTime.now().millisecondsSinceEpoch}.$fileExt';

      await supabase.storage
          .from('avatars')
          .uploadBinary(fileName, bytes);

      final imageUrl = supabase.storage
          .from('avatars')
          .getPublicUrl(fileName);

      await supabase.from('users')
          .update({'photo_url': imageUrl})
          .eq('id', user.id);

      await supabase.auth.updateUser(UserAttributes(
        data: {'avatar_url': imageUrl},
      ));

      await _loadUserData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Profile image updated successfully!'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

    } catch (e) {
      print('Error updating profile image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Failed to update image: ${e.toString()}')),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingImage = false);
      }
    }
  }

  void _showEditProfileDialog() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Edit Profile',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Container();
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: Tween<double>(
            begin: 0.7,
            end: 1.0,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutBack,
          )),
          child: FadeTransition(
            opacity: animation,
            child: AlertDialog(
              backgroundColor: Colors.transparent,
              contentPadding: EdgeInsets.zero,
              content: _EditProfilePopup(
                userData: userData,
                onSave: _updateUserProfile,
                onCancel: () => Navigator.of(context).pop(),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _updateUserProfile(Map<String, dynamic> updatedData) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      await supabase.from('users')
          .update(updatedData)
          .eq('id', user.id);

      if (updatedData['full_name'] != null) {
        await supabase.auth.updateUser(UserAttributes(
          data: {'full_name': updatedData['full_name']},
        ));
      }

      await _loadUserData();

      if (mounted) {
        Navigator.of(context).pop();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Profile updated successfully!'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

    } catch (e) {
      print('Error updating profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Failed to update profile: ${e.toString()}')),
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
  Widget build(BuildContext context) {
    final user = supabase.auth.currentUser;
    final profileImageUrl = userData?['photo_url'] ?? 
                           userData?['avatar_url'] ?? 
                           user?.userMetadata?['avatar_url'];

    final userDisplayData = {
      'name': userData?['full_name'] ?? userData?['firstName'] ?? userData?['name'] ?? 
              user?.userMetadata?['full_name'] ?? user?.userMetadata?['name'] ?? 'User',
      'id': userData?['email']?.split('@')[0] ?? user?.email?.split('@')[0] ?? 
            userData?['id']?.toString().substring(0, 8) ?? 'BS 1754',
      'books': userData?['booksRead'] ?? 100,
      'friends': userData?['friends'] ?? 1245,
      'following': userData?['following'] ?? 8,
      'joined': userData?['created_at'] != null
          ? _formatDate(userData!['created_at'])
          : 'Month DD YEAR',
      'genres': userData?['favoriteGenres'] ?? 'Romance, Mystery/Thriller, Fantasy, Science Fiction, +5 More',
      'photoURL': profileImageUrl,
    };

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF00B4D8),
        elevation: 0,
        title: Row(
          children: [
            GestureDetector(
              onTap: _updateProfileImage,
              child: Stack(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.white,
                    backgroundImage: profileImageUrl != null && profileImageUrl.toString().isNotEmpty
                        ? NetworkImage(profileImageUrl)
                        : null,
                    child: profileImageUrl == null || profileImageUrl.toString().isEmpty
                        ? const Icon(Icons.person, color: Color(0xFF00B4D8))
                        : null,
                  ),
                  if (_isUploadingImage)
                    Positioned.fill(
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                userDisplayData['name'] as String,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Spacer(),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => _showLogoutDialog(context),
            icon: const Icon(
              Icons.logout,
              color: Colors.white,
            ),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 500;
                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: 600,
                      minWidth: 0,
                    ),
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                      elevation: 6,
                      margin: const EdgeInsets.symmetric(
                        horizontal: 0,
                        vertical: 0,
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFe0eafc), Color(0xFFcfdef3)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(28),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 24,
                        ),
                        child: isNarrow
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  _buildProfileAvatar(profileImageUrl),
                                  const SizedBox(height: 18),
                                  _ProfileDetails(
                                    user: userDisplayData,
                                    onEditProfileTap: widget.onEditProfileTap,
                                    isNarrow: true,
                                  ),
                                ],
                              )
                            : Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildProfileAvatar(profileImageUrl),
                                  const SizedBox(width: 36),
                                  Expanded(
                                    child: _ProfileDetails(
                                      user: userDisplayData,
                                      onEditProfileTap: widget.onEditProfileTap,
                                      isNarrow: false,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.only(left: 16),
              child: ElevatedButton.icon(
                onPressed: widget.onMyBooksTap,
                icon: const Icon(Icons.menu_book),
                label: const Text('My Books'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileAvatar(String? profileImageUrl) {
    return GestureDetector(
      onTap: _updateProfileImage,
      child: Stack(
        children: [
          CircleAvatar(
            radius: 56,
            backgroundColor: Colors.white,
            backgroundImage: profileImageUrl != null && profileImageUrl.isNotEmpty
                ? NetworkImage(profileImageUrl)
                : null,
            child: profileImageUrl == null || profileImageUrl.isEmpty
                ? const Icon(Icons.person, size: 56, color: Color(0xFF00B4D8))
                : null,
          ),
          if (_isUploadingImage)
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3,
                  ),
                ),
              ),
            ),
          if (!_isUploadingImage)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Color(0xFF00B4D8),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
        ],
      ),
    );
  }

  static Widget _statBox(String value, String label, {IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.only(right: 24),
      child: Column(
        children: [
          if (icon != null) ...[
            Icon(icon, color: const Color(0xFF4a4e69), size: 22),
            const SizedBox(height: 2),
          ],
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Color(0xFF22223b),
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: Color(0xFF4a4e69), fontSize: 13),
          ),
        ],
      ),
    );
  }

  static String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'Month DD YEAR';
    try {
      DateTime? date;
      if (timestamp is DateTime) {
        date = timestamp;
      } else if (timestamp is String) {
        date = DateTime.tryParse(timestamp);
      }
      if (date != null) {
        return '${_getMonthName(date.month)} ${date.day} ${date.year}';
      }
      return 'Month DD YEAR';
    } catch (e) {
      return 'Month DD YEAR';
    }
  }

  static String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => _performLogout(context), // Use optimized version
              // OR for ultra-fast experience:
              // onPressed: () => _performQuickLogout(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  // Super simple instant logout
  void _performLogout(BuildContext context) async {
    Navigator.pop(context); // Close dialog

    // Navigate immediately - no loading, no delays
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const MainPage()),
      (Route<dynamic> route) => false,
    );

    // Simple success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Logged out'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 1),
      ),
    );

    // Clear Supabase session in background - fire and forget
    try {
      supabase.auth.signOut();
    } catch (e) {
      // Ignore any errors
    }
  }
}

class _ProfileDetails extends StatelessWidget {
  final Map<String, dynamic> user;
  final VoidCallback onEditProfileTap;
  final bool isNarrow;

  const _ProfileDetails({
    required this.user,
    required this.onEditProfileTap,
    required this.isNarrow,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: isNarrow
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: isNarrow
                    ? CrossAxisAlignment.center
                    : CrossAxisAlignment.start,
                children: [
                  Text(
                    user['name'] as String,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 28,
                      color: Color(0xFF22223b),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user['id'] as String,
                    style: const TextStyle(
                      color: Color(0xFF4a4e69),
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            if (!isNarrow) ...[
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () {
                  final dashboardState = context.findAncestorStateOfType<_UserDashboardPageState>();
                  dashboardState?._showEditProfileDialog();
                },
                icon: const Icon(Icons.edit, size: 20),
                label: const Text('Edit Profile'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFf2e9e4),
                  foregroundColor: const Color(0xFF22223b),
                  side: const BorderSide(color: Color(0xFF4a4e69)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),

                  elevation: 0,
                ),
              ),
            ],
          ],
        ),
        if (isNarrow) ...[
          const SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: () {
              final dashboardState = context.findAncestorStateOfType<_UserDashboardPageState>();
              dashboardState?._showEditProfileDialog();
            },
            icon: const Icon(Icons.edit, size: 20),
            label: const Text('Edit Profile'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFf2e9e4),
              foregroundColor: const Color(0xFF22223b),
              side: const BorderSide(color: Color(0xFF4a4e69)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              elevation: 0,
            ),
          ),
        ],
        const SizedBox(height: 14),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: isNarrow
                ? MainAxisAlignment.center
                : MainAxisAlignment.start,
            children: [
              _UserDashboardPageState._statBox(
                '${user['books']}',
                'Books',
                icon: Icons.menu_book,
              ),
              _UserDashboardPageState._statBox(
                '${user['friends']}',
                'Friends',
                icon: Icons.people,
              ),
              _UserDashboardPageState._statBox(
                '${user['following']}',
                'Following',
                icon: Icons.person_add_alt_1,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Joined in ${user['joined'] as String}',
          style: const TextStyle(color: Color(0xFF4a4e69), fontSize: 15),
        ),
        const SizedBox(height: 6),
        const Text(
          'Favorite GENRES',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: Color(0xFF22223b),
          ),
        ),
        Text(
          user['genres'] as String,
          style: const TextStyle(color: Color(0xFF4a4e69), fontSize: 15),
        ),
      ],
    );
  }
}

class _EditProfilePopup extends StatefulWidget {
  final Map<String, dynamic>? userData;
  final ValueChanged<Map<String, dynamic>> onSave;
  final VoidCallback onCancel;

  const _EditProfilePopup({
    Key? key,
    required this.userData,
    required this.onSave,
    required this.onCancel,
  }) : super(key: key);

  @override
  __EditProfilePopupState createState() => __EditProfilePopupState();
}

class __EditProfilePopupState extends State<_EditProfilePopup> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _bioController;
  late TextEditingController _locationController;
  late TextEditingController _genresController;
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.userData?['full_name'] ?? '');
    _emailController = TextEditingController(text: widget.userData?['email'] ?? '');
    _phoneController = TextEditingController(text: widget.userData?['phone'] ?? '');
    _bioController = TextEditingController(text: widget.userData?['bio'] ?? '');
    _locationController = TextEditingController(text: widget.userData?['location'] ?? '');
    _genresController = TextEditingController(text: widget.userData?['favorite_genres'] ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    _genresController.dispose();
    super.dispose();
  }

  void _saveProfile() {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      final updatedData = <String, dynamic>{};
      
      if (_nameController.text.trim().isNotEmpty) {
        updatedData['full_name'] = _nameController.text.trim();
      }
      if (_phoneController.text.trim().isNotEmpty) {
        updatedData['phone'] = _phoneController.text.trim();
      }
      if (_bioController.text.trim().isNotEmpty) {
        updatedData['bio'] = _bioController.text.trim();
      }
      if (_locationController.text.trim().isNotEmpty) {
        updatedData['location'] = _locationController.text.trim();
      }
      if (_genresController.text.trim().isNotEmpty) {
        updatedData['favorite_genres'] = _genresController.text.trim();
      }
      
      widget.onSave(updatedData);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          child: Container(
            constraints: const BoxConstraints(maxHeight: 600),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF00B4D8), Color(0xFF0096C7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.edit, color: Colors.white, size: 24),
                      const SizedBox(width: 12),
                      const Text(
                        'Edit Profile',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: widget.onCancel,
                        icon: const Icon(Icons.close, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          _buildTextFormField(
                            controller: _nameController,
                            label: 'Full Name',
                            icon: Icons.person,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter your full name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          _buildTextFormField(
                            controller: _emailController,
                            label: 'Email',
                            icon: Icons.email,
                            enabled: false,
                            hint: 'Email cannot be changed',
                          ),
                          const SizedBox(height: 16),
                          _buildTextFormField(
                            controller: _phoneController,
                            label: 'Phone Number',
                            icon: Icons.phone,
                            keyboardType: TextInputType.phone,
                            hint: 'Enter your phone number',
                          ),
                          const SizedBox(height: 16),
                          _buildTextFormField(
                            controller: _locationController,
                            label: 'Location',
                            icon: Icons.location_on,
                            hint: 'Enter your city/country',
                          ),
                          const SizedBox(height: 16),
                          _buildTextFormField(
                            controller: _bioController,
                            label: 'Bio',
                            icon: Icons.description,
                            maxLines: 3,
                            hint: 'Tell us about yourself...',
                          ),
                          const SizedBox(height: 16),
                          _buildTextFormField(
                            controller: _genresController,
                            label: 'Favorite Genres',
                            icon: Icons.category,
                            hint: 'Romance, Mystery, Sci-Fi, etc.',
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    border: Border(
                      top: BorderSide(color: Colors.grey[200]!),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isLoading ? null : widget.onCancel,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: BorderSide(color: Colors.grey[400]!),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _saveProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00B4D8),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Save Changes',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    bool enabled = true,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: const Color(0xFF00B4D8)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF00B4D8), width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        filled: !enabled,
        fillColor: enabled ? null : Colors.grey[100],
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}
