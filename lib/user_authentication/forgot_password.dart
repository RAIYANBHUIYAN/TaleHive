import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'reset_password_confirmation.dart'; // We'll create this page

class ForgotPassword extends StatefulWidget {
  const ForgotPassword({super.key});

  @override
  State<ForgotPassword> createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPassword> {
  final _formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  bool isLoading = false;

  Future<void> _sendPasswordResetEmail() async {
    if (_formKey.currentState!.validate()) {
      setState(() => isLoading = true);
      try {
        await FirebaseAuth.instance.sendPasswordResetEmail(
          email: emailController.text.trim(),
        );

        // Navigate to confirmation page
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ResetPasswordConfirmation(
              email: emailController.text.trim(),
            ),
          ),
        );

        _showSuccess('Password reset email sent! Please check your inbox.');
      } on FirebaseAuthException catch (e) {
        String errorMessage = 'Something went wrong';
        if (e.code == 'user-not-found') {
          errorMessage = 'No account found with this email address.';
        } else if (e.code == 'invalid-email') {
          errorMessage = 'Please enter a valid email address.';
        } else if (e.code == 'too-many-requests') {
          errorMessage = 'Too many requests. Please try again later.';
        }
        _showError(errorMessage);
      } catch (e) {
        _showError('Error: $e');
      } finally {
        setState(() => isLoading = false);
      }
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
      appBar: AppBar(
        title: Text('Forgot Password'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
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
              // Logo
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
              SizedBox(height: 20),
              
              // Title and description
              Text(
                'Forgot Password',
                style: TextStyle(
                  fontSize: 40,
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 10),
              Container(
                width: 350,
                child: Text(
                  'Enter your email address and we\'ll send you a link to reset your password',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: 30),
              
              // Form
              Container(
                width: 350,
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: emailController,
                        validator: (value) => value == null || !value.contains('@') || !value.contains('.') ? 'Enter valid email' : null,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'Email Address',
                          prefixIcon: Icon(Icons.email, color: Colors.lightGreen),
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
                      SizedBox(height: 30),
                      
                      // Reset Password Button
                      ElevatedButton(
                        onPressed: isLoading ? null : _sendPasswordResetEmail,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.lightGreen,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30.0),
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: 80,
                            vertical: 15,
                          ),
                        ),
                        child: isLoading
                            ? CircularProgressIndicator(color: Colors.white)
                            : Text(
                                'SEND RESET LINK',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                      SizedBox(height: 20),
                      
                      // Back to Login
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Back to Login',
                          style: TextStyle(
                            color: Colors.blueGrey,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              SizedBox(height: 40),
              
              // TaleHive branding
              Column(
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

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }
}
