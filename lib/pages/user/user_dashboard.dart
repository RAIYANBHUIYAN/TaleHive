import 'package:flutter/material.dart';

class UserDashboardPage extends StatelessWidget {
  const UserDashboardPage({
    Key? key,
    required this.onMyBooksTap,
    required this.onEditProfileTap,
  }) : super(key: key);

  final VoidCallback onMyBooksTap;
  final VoidCallback onEditProfileTap;

  @override
  Widget build(BuildContext context) {
    final user = {
      'name': 'Arif Abdullah',
      'id': 'BS 1754',
      'books': 100,
      'friends': 1245,
      'following': 8,
      'joined': 'Month DD YEAR',
      'genres': 'Romance, Mystery/Thriller, Fantasy, Science Fiction, +5 More',
    };
    final isMobile = MediaQuery.of(context).size.width < 600;
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF00B4D8),
        elevation: 0,
        title: Row(
          children: [
            const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person, color: Color(0xFF00B4D8)),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                user['name'] as String,
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
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Card at the top
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
                          gradient: LinearGradient(
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
                                  CircleAvatar(
                                    radius: 56,
                                    backgroundColor: Colors.white,
                                    backgroundImage: AssetImage(
                                      'Asset/images/arif.jpg',
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  _ProfileDetails(
                                    user: user,
                                    onEditProfileTap: onEditProfileTap,
                                    isNarrow: true,
                                  ),
                                ],
                              )
                            : Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    radius: 56,
                                    backgroundColor: Colors.white,
                                    backgroundImage: AssetImage(
                                      'Asset/images/arif.jpg',
                                    ),
                                  ),
                                  const SizedBox(width: 36),
                                  Expanded(
                                    child: _ProfileDetails(
                                      user: user,
                                      onEditProfileTap: onEditProfileTap,
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
            // My Books button left-aligned
            Padding(
              padding: const EdgeInsets.only(left: 16),
              child: ElevatedButton.icon(
                onPressed: onMyBooksTap,
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

  static Widget _statBox(String value, String label, {IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.only(right: 24),
      child: Column(
        children: [
          if (icon != null) ...[
            Icon(icon, color: Color(0xFF4a4e69), size: 22),
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
            if (!isNarrow) ...[
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: onEditProfileTap,
                icon: const Icon(Icons.edit, size: 20),
                label: const Text('Edit Profile'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFf2e9e4),
                  foregroundColor: Color(0xFF22223b),
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
            onPressed: onEditProfileTap,
            icon: const Icon(Icons.edit, size: 20),
            label: const Text('Edit Profile'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFf2e9e4),
              foregroundColor: Color(0xFF22223b),
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
              UserDashboardPage._statBox(
                '${user['books']}',
                'Books',
                icon: Icons.menu_book,
              ),
              UserDashboardPage._statBox(
                '${user['friends']}',
                'Friends',
                icon: Icons.people,
              ),
              UserDashboardPage._statBox(
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
        Text(
          'Favorite GENRES',
          style: const TextStyle(
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
