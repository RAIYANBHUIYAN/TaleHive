import 'package:flutter/material.dart';
import 'admin_forgot_password.dart'; // Import the forgot password page

// Convert to StatefulWidget to manage password visibility state
class AdminLogin extends StatefulWidget {
  const AdminLogin({super.key});

  @override
  State<AdminLogin> createState() => _LoginState();
}

class _LoginState extends State<AdminLogin> {
  // State variable to toggle password visibility
  bool _isPasswordVisible = false;

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
              // Add the logo at the top
              Image.asset(
                'Asset/images/logo.jpg', // Assuming this is the correct path to your logo asset
                height: 100, // Adjust height as needed
              ),
              SizedBox(height: 20), // Spacing below the logo
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment:
                CrossAxisAlignment.center, // Center elements horizontally
                children: [
                  Text(
                    'Welcome Admin !!',
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextFormField(
                            decoration: InputDecoration(
                              labelText: 'Username',
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
                          const AdminForgotPassword(),
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
                        onPressed: () {},
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
                          'LOG IN',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),

                    ],
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
                    'Brain Station 23',
                    style: TextStyle(fontSize: 24, color: Colors.blue),
                  ),
                  Text(
                    'Library',
                    style: TextStyle(fontSize: 18, color: Colors.black54),
                  ),
                  SizedBox(height: 10), // Spacing
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
