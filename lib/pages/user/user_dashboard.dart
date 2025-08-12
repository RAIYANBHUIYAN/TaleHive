import 'package:flutter/material.dart';

// --- Data Model ---
// To make our code more structured and scalable, we define a User model.
// This class holds all the data related to a user, ensuring type safety
// and making it easier to manage user information throughout the app.
// Instead of using a raw Map, we use this dedicated class.
class UserModel {
  /// The full name of the user.
  final String name;

  /// The unique identifier for the user.
  final String id;

  /// The total number of books the user has read or logged.
  final int books;

  /// The number of friends the user has on the platform.
  final int friends;

  /// The number of other users this user is following.
  final int following;

  /// The date the user joined the platform.
  final String joined;

  /// A string representing the user's favorite genres.
  final String genres;

  /// The path to the user's avatar image in the assets folder.
  final String avatarAsset;

  /// Constructor for the UserModel.
  /// All fields are required to create a user instance.
  const UserModel({
    required this.name,
    required this.id,
    required this.books,
    required this.friends,
    required this.following,
    required this.joined,
    required this.genres,
    required this.avatarAsset,
  });
}

/// The main dashboard page for a user.
///
/// This widget is the root of the user profile screen. It is a StatelessWidget
/// because all the data it displays is passed into it. It orchestrates the
/// layout of the AppBar, the main profile card, and other action buttons.
class UserDashboardPage extends StatelessWidget {
  /// Callback function to execute when the "My Books" button is tapped.
  final VoidCallback onMyBooksTap;

  /// Callback function to execute when the "Edit Profile" button is tapped.
  final VoidCallback onEditProfileTap;

  /// A static instance of our user data.
  ///
  /// In a real application, this data would be fetched from a database or API.
  /// For this example, we are using a statically defined UserModel.
  static final UserModel _user = UserModel(
    name: 'Arif Abdullah',
    id: 'BS 1754',
    books: 100,
    friends: 1245,
    following: 8,
    joined: 'Month DD YEAR',
    genres: 'Romance, Mystery/Thriller, Fantasy, Science Fiction, +5 More',
    avatarAsset: 'Asset/images/arif.jpg',
  );

  /// Constructor for the UserDashboardPage.
  const UserDashboardPage({
    Key? key,
    required this.onMyBooksTap,
    required this.onEditProfileTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // The Scaffold provides the basic structure of the visual interface.
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFC),
      // The AppBar is built using a helper method to keep the build method clean.
      appBar: _buildAppBar(context, _user),
      // The body is a SingleChildScrollView to prevent overflow on smaller screens.
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // The main profile card is the centerpiece of the dashboard.
            // We use a helper method to construct it for better organization.
            _buildUserProfileCard(context, _user),
            const SizedBox(height: 24),
            // The "My Books" button, also built with a helper method.
            _buildMyBooksButton(),
            const SizedBox(height: 24),
            // --- Placeholder for Future Features ---
            // This section demonstrates how you could add more UI elements
            // in the future without cluttering the main build method.
            // _buildRecentActivitySection(),
            // _buildFriendSuggestions(),
          ],
        ),
      ),
    );
  }

  /// Builds the top AppBar for the dashboard.
  ///
  /// This private helper method encapsulates all the logic for creating and
  /// styling the AppBar, making the main `build` method easier to read.
  PreferredSizeWidget _buildAppBar(BuildContext context, UserModel user) {
    return AppBar(
      backgroundColor: const Color(0xFF00B4D8),
      elevation: 0,
      title: Row(
        children: [
          // User avatar in the AppBar.
          const CircleAvatar(
            backgroundColor: Colors.white,
            child: Icon(Icons.person, color: Color(0xFF00B4D8)),
          ),
          const SizedBox(width: 12),
          // User's name, which can shrink if space is limited.
          Flexible(
            child: Text(
              user.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // A spacer to push any subsequent widgets to the end.
          const Spacer(),
        ],
      ),
    );
  }

  /// Builds the main profile card that contains user details.
  ///
  /// This method uses a LayoutBuilder to create a responsive layout that
  /// adapts between a row and a column based on the available width.
  Widget _buildUserProfileCard(BuildContext context, UserModel user) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Determine if the layout should be narrow (column) or wide (row).
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
              margin: EdgeInsets.zero,
              child: Container(
                // A decorative gradient for the card background.
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFe0eafc), Color(0xFFcfdef3)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(28),
                ),
                padding: const EdgeInsets.all(24),
                // The content of the card is determined by the responsive layout.
                child: isNarrow
                    ? _buildNarrowLayout(user)
                    : _buildWideLayout(user),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Builds the content for the profile card in a narrow (column) view.
  Widget _buildNarrowLayout(UserModel user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // The main user avatar.
        CircleAvatar(
          radius: 56,
          backgroundColor: Colors.white,
          backgroundImage: AssetImage(user.avatarAsset),
        ),
        const SizedBox(height: 18),
        // The detailed profile information widget.
        _ProfileDetails(
          user: user,
          onEditProfileTap: onEditProfileTap,
          isNarrow: true,
        ),
      ],
    );
  }

  /// Builds the content for the profile card in a wide (row) view.
  Widget _buildWideLayout(UserModel user) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // The main user avatar.
        CircleAvatar(
          radius: 56,
          backgroundColor: Colors.white,
          backgroundImage: AssetImage(user.avatarAsset),
        ),
        const SizedBox(width: 36),
        // The detailed profile information, which expands to fill the space.
        Expanded(
          child: _ProfileDetails(
            user: user,
            onEditProfileTap: onEditProfileTap,
            isNarrow: false,
          ),
        ),
      ],
    );
  }

  /// Builds the "My Books" button.
  Widget _buildMyBooksButton() {
    return Padding(
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
    );
  }

  /// A helper function to build a single statistic box.
  ///
  /// This static method can be called from anywhere to create a consistent
  /// styled box for displaying user statistics like books, friends, etc.
  static Widget _statBox(String value, String label, {IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.only(right: 24),
      child: Column(
        children: [
          // Optionally display an icon above the statistic.
          if (icon != null) ...[
            Icon(icon, color: const Color(0xFF4a4e69), size: 22),
            const SizedBox(height: 2),
          ],
          // The numerical value of the statistic.
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Color(0xFF22223b),
            ),
          ),
          // The label describing the statistic.
          Text(
            label,
            style: const TextStyle(color: Color(0xFF4a4e69), fontSize: 13),
          ),
        ],
      ),
    );
  }

  // --- Placeholder Methods for Future Expansion ---
  // These methods do not do anything but serve as placeholders to show where
  // future logic could be added. This is a good practice for planning ahead.

  /// A placeholder to simulate fetching user activity data.
  Future<void> _fetchUserActivity() async {
    // In a real app, you would make an API call here.
    await Future.delayed(const Duration(seconds: 1));
    // print("User activity fetched.");
  }

  /// A placeholder to handle a friend request action.
  void _handleFriendRequest(String userId) {
    // Logic to send or accept a friend request would go here.
    // print("Handling friend request for user: $userId");
  }
}

/// A private widget that displays the core details of the user profile.
///
/// This widget is used inside the main profile card and is responsible for
/// laying out the user's name, ID, stats, and other information. It also
/// adapts its layout based on the `isNarrow` flag.
class _ProfileDetails extends StatelessWidget {
  final UserModel user;
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
      // Align content to the center in narrow view, or start in wide view.
      crossAxisAlignment:
          isNarrow ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        // Section for Name and ID.
        _buildNameAndIdSection(),
        const SizedBox(height: 14),

        // Section for stats (Books, Friends, Following).
        _buildStatsRow(),
        const SizedBox(height: 14),

        // Section for additional info like join date and genres.
        _buildAdditionalInfoSection(),
      ],
    );
  }

  /// Builds the name, ID, and edit profile button section.
  Widget _buildNameAndIdSection() {
    // The main container for this section.
    // We use a Column and then a Row to structure these elements.
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // The user's name and ID are grouped in an Expanded widget
            // so they can take up available space and wrap if needed.
            Expanded(
              child: Column(
                crossAxisAlignment:
                    isNarrow ? CrossAxisAlignment.center : CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 28,
                      color: Color(0xFF22223b),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.id,
                    style: const TextStyle(
                      color: Color(0xFF4a4e69),
                      fontSize: 28,
                    ),
                  ),
                ],
              ),
            ),
            // The "Edit Profile" button is only shown in the wide layout here.
            if (!isNarrow) ...[
              const SizedBox(width: 8),
              _buildEditProfileButton(),
            ],
          ],
        ),
        // The "Edit Profile" button is shown below the name in the narrow layout.
        if (isNarrow) ...[
          const SizedBox(height: 10),
          _buildEditProfileButton(),
        ],
      ],
    );
  }

  /// Builds the "Edit Profile" button with consistent styling.
  Widget _buildEditProfileButton() {
    return ElevatedButton.icon(
      onPressed: onEditProfileTap,
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
    );
  }

  /// Builds the horizontally scrollable row of user statistics.
  Widget _buildStatsRow() {
    // A SingleChildScrollView is used to ensure the stats row
    // does not overflow on smaller screen widths.
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        // The alignment of the stats row depends on the layout mode.
        mainAxisAlignment:
            isNarrow ? MainAxisAlignment.center : MainAxisAlignment.start,
        children: [
          // Each stat is created using the static _statBox helper method.
          UserDashboardPage._statBox(
            '${user.books}',
            'Books',
            icon: Icons.menu_book,
          ),
          UserDashboardPage._statBox(
            '${user.friends}',
            'Friends',
            icon: Icons.people,
          ),
          UserDashboardPage._statBox(
            '${user.following}',
            'Following',
            icon: Icons.person_add_alt_1,
          ),
        ],
      ),
    );
  }

  /// Builds the final section containing join date and favorite genres.
  Widget _buildAdditionalInfoSection() {
    // This column holds the final text-based information.
    // The cross-axis alignment ensures it matches the rest of the profile card.
    return Column(
      crossAxisAlignment:
          isNarrow ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        // Joined date information.
        Text(
          'Joined in ${user.joined}',
          style: const TextStyle(color: Color(0xFF4a4e69), fontSize: 15),
        ),
        const SizedBox(height: 6),
        // Favorite genres title.
        const Text(
          'FAVORITE GENRES',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: Color(0xFF22223b),
          ),
        ),
        // List of favorite genres.
        Text(
          user.genres,
          style: const TextStyle(color: Color(0xFF4a4e69), fontSize: 15),
        ),
      ],
    );
  }
}