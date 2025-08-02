import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'signup.dart'; // Import the signup page using a relative path
import 'forgot_password.dart'; // Import the forgot password page using a relative path

// Convert to StatefulWidget to manage password visibility state
class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final _formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  // State variable to toggle password visibility
  bool _isPasswordVisible = false;
  bool isLoading = false;

  Future<void> _loginWithEmail() async {
    if (_formKey.currentState!.validate()) {
      setState(() => isLoading = true);
      try {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );
        // Navigate to user-home page
        Navigator.pushReplacementNamed(context, '/user-home');
        _showSuccess('Welcome back! Login successful');
      } on FirebaseAuthException catch (e) {
        String error = 'Login failed';
        if (e.code == 'user-not-found') {
          error = 'No user found for that email.';
        } else if (e.code == 'wrong-password') {
          error = 'Incorrect password.';
        }
        _showError(error);
      } finally {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _loginWithGoogle() async {
    setState(() => isLoading = true);
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        setState(() => isLoading = false);
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await FirebaseAuth.instance
          .signInWithCredential(credential);
      final User? user = userCredential.user;

      // Save user info to Firestore
      if (user != null) {
        final userDoc = FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid);
        final docSnapshot = await userDoc.get();

        // Save only if not already exists
        if (!docSnapshot.exists) {
          await userDoc.set({
            'uid': user.uid,
            'firstName': user.displayName?.split(' ').first ?? '',
            'lastName': user.displayName?.split(' ').last ?? '',
            'email': user.email ?? '',
            'photoURL': user.photoURL ?? '',
            'provider': 'google',
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      }

      // Navigate to user-home page
      Navigator.pushReplacementNamed(context, '/user-home');
      String userName = user?.displayName ?? 'User';
      String firstName = userName.split(' ').first;
      _showSuccess('Welcome to TaleHive, $firstName! 🎉 Signed in successfully with Google');
    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? 'Google Sign-In failed');
    } catch (e) {
      String errorMessage = 'Google Sign-In failed';
      if (e.toString().contains('ApiException: 10')) {
        errorMessage = 'Google Sign-In configuration error. Please contact support.';
        print('DEBUG: SHA-1 fingerprint missing from Firebase project');
      } else {
        errorMessage = 'Error: $e';
      }
      _showError(errorMessage);
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white, size: 24),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: EdgeInsets.all(16),
        duration: Duration(seconds: 4),
        elevation: 8,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.white, size: 24),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: EdgeInsets.all(16),
        duration: Duration(seconds: 3),
        elevation: 8,
      ),
    );
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
