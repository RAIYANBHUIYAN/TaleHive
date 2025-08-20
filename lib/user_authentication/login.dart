// lib/user_authentication/login.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../pages/user/user_home.dart';
import '../pages/user/author_dashboard.dart';
import 'signup.dart';
import 'forgot_password.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final _formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool isLoading = false;
  
  final supabase = Supabase.instance.client;
  late final GoogleSignIn _googleSignIn;

  @override
  void initState() {
    super.initState();
    _googleSignIn = GoogleSignIn(
      clientId: dotenv.env['GOOGLE_CLIENT_ID'],
    );
  }

  Future<void> _loginWithEmail() async {
    if (_formKey.currentState!.validate()) {
      setState(() => isLoading = true);
      try {
        final AuthResponse response = await supabase.auth.signInWithPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );

        if (response.user != null) {
          // Successful login
          final user = supabase.auth.currentUser;
          if (user != null) {
            // Check user role from database
            try {
              // Try to find user in authors table
              final authorData = await supabase
                  .from('authors')
                  .select('role')
                  .eq('id', user.id)
                  .maybeSingle();
              
              if (authorData != null) {
                // User is an author
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/author_dashboard',
                  (route) => false,
                );
              } else {
                // User is a reader
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/user_home',
                  (route) => false,
                );
              }
            } catch (e) {
              // Fallback to user home
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/user_home',
                (route) => false,
              );
            }
          }
          _showSuccess('Welcome back! Login successful');
        }
      } on AuthException catch (e) {
        _showError('Login failed: ${e.message}');
      } finally {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _loginWithGoogle() async {
    setState(() => isLoading = true);
    try {
      // Force account selection every time - this ensures clean login
      final GoogleSignInAccount? googleUser = await GoogleSignIn(
        scopes: ['email', 'profile'],
        // This forces account selection
      ).signIn();

      if (googleUser == null) {
        setState(() => isLoading = false);
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final AuthResponse response = await supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: googleAuth.idToken!,
        accessToken: googleAuth.accessToken!,
      );

      if (response.user != null) {
        await _saveUserToSupabase(response.user!);
        await _checkUserRoleAndNavigate(response.user!);
        _showSuccess('Welcome! Signed in with Google');
      }
    } catch (e) {
      _showError('Google Sign-In failed: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _checkUserRoleAndNavigate(User user) async {
    try {
      // Check if user exists in authors table
      final authorResponse = await supabase
          .from('authors')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (authorResponse != null) {
        await supabase
            .from('authors')
            .update({'last_login_at': DateTime.now().toIso8601String()})
            .eq('id', user.id);
        
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AuthorDashboardPage()),
        );
        return;
      }

      // Check if user exists in users table
      final userResponse = await supabase
          .from('users')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (userResponse != null) {
        await supabase
            .from('users')
            .update({'last_login_at': DateTime.now().toIso8601String()})
            .eq('id', user.id);
        
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const UserHomePage()),
        );
        return;
      }

      // Create as reader if doesn't exist
      await supabase.from('users').insert({
        'id': user.id,
        'email': user.email,
        'first_name': user.userMetadata?['name']?.split(' ').first ?? 'User',
        'last_name': user.userMetadata?['name']?.split(' ').skip(1).join(' ') ?? '',
        'photo_url': user.userMetadata?['avatar_url'] ?? '',
        'role': 'reader',
      });

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const UserHomePage()),
      );
    } catch (e) {
      print('Error checking user role: $e');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const UserHomePage()),
      );
    }
  }

  Future<void> _saveUserToSupabase(User user) async {
    try {
      final existingUser = await supabase
          .from('users')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      final existingAuthor = await supabase
          .from('authors')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (existingUser == null && existingAuthor == null) {
        await supabase.from('users').insert({
          'id': user.id,
          'email': user.email,
          'first_name': user.userMetadata?['name']?.split(' ').first ?? 'User',
          'last_name': user.userMetadata?['name']?.split(' ').skip(1).join(' ') ?? '',
          'photo_url': user.userMetadata?['avatar_url'] ?? '',
          'role': 'reader',
        });
      }
    } catch (e) {
      print('Error saving user: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  // Alternative: Always sign out from Google before signing in (fast operation)
  Future<User?> signInWithGoogleForceSelection() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
      );

      // Quick Google sign out (this is fast, unlike disconnect)
      await googleSignIn.signOut().timeout(const Duration(seconds: 1));

      // Now sign in - this will show account selection
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final response = await supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: googleAuth.idToken!,
        accessToken: googleAuth.accessToken,
      );

      return response.user;
    } catch (e) {
      print('Google sign-in error: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        // Center the content vertically
        child: SingleChildScrollView(
          // Wrap in SingleChildScrollView to prevent overflow on small screens
          padding: const EdgeInsets.all(20.0), // Add some padding
          child: Column(
            // Changed Row to Column for mobile layout
            mainAxisAlignment:
                MainAxisAlignment.center, // Center content vertically
            crossAxisAlignment:
                CrossAxisAlignment.center, // Center content horizontally
            children: [
              // Add the logo at the top with error handling
              Image.asset(
                'Asset/images/logo.jpg',
                height: 100,
                errorBuilder: (context, error, stackTrace) {
                  return Column(
                    children: [
                      Icon(Icons.image_not_supported, size: 60, color: Colors.grey),
                      SizedBox(height: 8),
                      Text(
                        'Logo not found',
                        style: TextStyle(color: Colors.red, fontSize: 14),
                      ),
                    ],
                  );
                },
              ),
              SizedBox(height: 20), // Spacing below the logo
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment:
                    CrossAxisAlignment.center, // Center elements horizontally
                children: [
                  Text(
                    'Welcome Back !!',
                    style: TextStyle(
                      fontSize: 40,
                      color: Colors.blue,
                    ), // Slightly smaller font size for mobile
                  ),
                  Text('Please enter your credentials to log in'),
                  SizedBox(height: 20), // Add some spacing
                  Container(
                    width:
                        300, // Keep a reasonable width for the form container
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextFormField(
                            controller: emailController,
                            validator: (value) => value == null || !value.contains('@') ? 'Enter valid email' : null,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              labelText: 'Email',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30.0),
                                borderSide: BorderSide(
                                  color: Colors.lightGreen,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30.0),
                                borderSide: BorderSide(
                                  color: Colors.lightGreen,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30.0),
                                borderSide: BorderSide(
                                  color: Colors.lightGreenAccent,
                                  width: 2.0,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 15), // Spacing between fields
                          TextFormField(
                            controller: passwordController,
                            validator: (value) => value == null || value.length < 6 ? 'Minimum 6 characters' : null,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30.0),
                                borderSide: BorderSide(
                                  color: Colors.lightGreen,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30.0),
                                borderSide: BorderSide(
                                  color: Colors.lightGreen,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30.0),
                                borderSide: BorderSide(
                                  color: Colors.lightGreenAccent,
                                  width: 2.0,
                                ),
                              ),
                              // Add the password visibility toggle icon
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _isPasswordVisible
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                  color: Colors
                                      .grey, // Adjust icon color as needed
                                ),
                                onPressed: () {
                                  // Toggle password visibility state
                                  setState(() {
                                    _isPasswordVisible = !_isPasswordVisible;
                                  });
                                },
                              ),
                            ),
                            obscureText:
                                !_isPasswordVisible, // Use the state variable here
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 10), // Spacing
                  TextButton(
                    onPressed: () {
                      // Navigate to the Forgot Password page with a custom animation
                      Navigator.push(
                        context,
                        PageRouteBuilder(
                          pageBuilder:
                              (context, animation, secondaryAnimation) =>
                                  const ForgotPassword(),
                          transitionsBuilder:
                              (context, animation, secondaryAnimation, child) {
                                const begin = Offset(
                                  1.0,
                                  0.0,
                                ); // Start from the right
                                const end = Offset.zero; // End at the center
                                const curve =
                                    Curves.ease; // Smooth animation curve

                                var tween = Tween(
                                  begin: begin,
                                  end: end,
                                ).chain(CurveTween(curve: curve));

                                return SlideTransition(
                                  position: animation.drive(tween),
                                  child: child,
                                );
                              },
                        ),
                      );
                    },
                    child: Text(
                      'Forgot password?',
                      style: TextStyle(color: Colors.blueGrey),
                    ),
                  ),
                  SizedBox(height: 20), // Spacing
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: isLoading ? null : _loginWithEmail,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.lightGreen,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30.0),
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: 40,
                            vertical: 15,
                          ),
                        ),
                        child: isLoading
                            ? CircularProgressIndicator(color: Colors.white)
                            : Text(
                                'LOG IN',
                                style: TextStyle(color: Colors.white),
                              ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          // Navigate to the Signup page with a custom animation
                          Navigator.push(
                            context,
                            PageRouteBuilder(
                              pageBuilder:
                                  (context, animation, secondaryAnimation) =>
                                      const Signup(),
                              transitionsBuilder:
                                  (
                                    context,
                                    animation,
                                    secondaryAnimation,
                                    child,
                                  ) {
                                    const begin = Offset(
                                      1.0,
                                      0.0,
                                    ); // Start from the right
                                    const end =
                                        Offset.zero; // End at the center
                                    const curve =
                                        Curves.ease; // Smooth animation curve

                                    var tween = Tween(
                                      begin: begin,
                                      end: end,
                                    ).chain(CurveTween(curve: curve));

                                    return SlideTransition(
                                      position: animation.drive(tween),
                                      child: child,
                                    );
                                  },
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.lightGreen,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30.0),
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: 40,
                            vertical: 15,
                          ),
                        ),
                        child: Text(
                          'Sign Up',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20), // Spacing
                  Row(
                    children: const [
                      Expanded(
                        child: Divider(color: Colors.grey, thickness: 1),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text(
                          "or",
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                      Expanded(
                        child: Divider(color: Colors.grey, thickness: 1),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Container(
                    width: 300,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _loginWithGoogle,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black87,
                        elevation: 2,
                        shadowColor: Colors.grey.withOpacity(0.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30.0),
                          side: BorderSide(color: Colors.grey[300]!, width: 1),
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 15,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Image.asset(
                              'Asset/images/google.jpg',
                              width: 24,
                              height: 24,
                              errorBuilder: (context, error, stackTrace) {
                                // Fallback to icon if image not found
                                return Icon(
                                  Icons.g_mobiledata,
                                  color: Color(0xFF4285F4),
                                  size: 24,
                                );
                              },
                            ),
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Sign in with Google',
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.25,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(
                height: 40,
              ), // Add significant spacing between the two sections

              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'TaleHive',
                    style: TextStyle(fontSize: 24, color: Colors.blue),
                  ),

                  Container(
                    width: 300,
                    child: Text(
                      'Your Premier Digital Library for Exploring Technical, Training, and IT Books',
                      style: TextStyle(fontSize: 14, color: Colors.black87),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
