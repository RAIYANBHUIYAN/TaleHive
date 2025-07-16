import 'package:flutter/material.dart';

class AdminResetPassword extends StatefulWidget {
  const AdminResetPassword({super.key});

  @override
  State<AdminResetPassword> createState() => _ResetPasswordState();
}

class _ResetPasswordState extends State<AdminResetPassword> {
  bool _isNewPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

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
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset('Asset/images/logo.jpg', height: 100),
              SizedBox(height: 20),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Reset Password',
                    style: TextStyle(fontSize: 40, color: Colors.blue),
                  ),
                  Text('Please enter your new password'),
                  SizedBox(height: 20),
                  Container(
                    width: 300,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          decoration: InputDecoration(
                            labelText: 'New Password',
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
                          obscureText: !_isNewPasswordVisible,
                        ),
                        SizedBox(height: 15),
                        TextFormField(
                          decoration: InputDecoration(
                            labelText: 'Confirm Password',
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
                          obscureText: !_isConfirmPasswordVisible,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.lightGreen,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                ),
                child: Text(
                  'RESET PASSWORD',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              SizedBox(height: 40),
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
                  SizedBox(height: 10),
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
