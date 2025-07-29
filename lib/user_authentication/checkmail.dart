import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'reset_password.dart'; // Import the reset password page

class CheckMail extends StatelessWidget {
  const CheckMail({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); // Navigate back
          },
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          // Wrap in SingleChildScrollView
          padding: const EdgeInsets.all(20.0), // Add padding
          child: Column(
            // Change Row to Column
            mainAxisAlignment:
                MainAxisAlignment.center, // Center content vertically
            crossAxisAlignment:
                CrossAxisAlignment.center, // Center content horizontally
            children: [
              // Add the logo at the top
              Image.asset(
                'Asset/images/logo.jpg', // Assuming the logo is here
                height: 100,
              ),
              SizedBox(height: 20), // Spacing below the logo
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment:
                    CrossAxisAlignment.center, // Center elements horizontally
                children: [
                  Text(
                    'Check your Mailbox',
                    style: TextStyle(
                      fontSize: 40,
                      color: Colors.blue,
                    ), // Adjust font size for mobile
                  ),
                  Text('Please enter the OTP to proceed'),
                  SizedBox(height: 20), // Add some spacing
                  Container(
                    width: 300, // Set a fixed width for the input field
                    child: TextFormField(
                      decoration: InputDecoration(
                        labelText: 'OTP',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30.0),
                          borderSide: BorderSide(color: Colors.lightGreen),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30.0),
                          borderSide: BorderSide(color: Colors.lightGreen),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30.0),
                          borderSide: BorderSide(
                            color: Colors.lightGreenAccent,
                            width: 2.0,
                          ),
                        ),
                      ),
                      keyboardType:
                          TextInputType.number, // Set keyboard type to number
                    ),
                  ),
                  SizedBox(height: 20), // Spacing before button
                  ElevatedButton(
                    onPressed: () {
                      // Navigate to the Reset Password page with a custom animation
                      Navigator.push(
                        context,
                        PageRouteBuilder(
                          pageBuilder:
                              (context, animation, secondaryAnimation) =>
                                  const ResetPassword(),
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
                      'VERIFY',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 40), // Spacing between sections
              // Right side: Brain Station 23 Info (now bottom section)
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment:
                    CrossAxisAlignment.center, // Center elements horizontally
                children: [
                  // Need to add the top-right blue logo if available
                  Text(
                    'TaleHive',
                    style: TextStyle(
                      fontSize: 24,
                      color: Colors.blue,
                    ), // Adjust font size
                  ),
                  Text(
                    'Library',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.black54,
                    ), // Adjust font size
                  ),
                  SizedBox(height: 10),
                  Container(
                    width: 300,
                    child: Text(
                      'Your Premier Digital Library for Exploring Technical, Training, and IT Books',
                      style: TextStyle(fontSize: 14, color: Colors.black87),
                      textAlign: TextAlign.center, // Center text
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
