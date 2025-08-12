import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ResetPasswordConfirmation extends StatefulWidget {
  final String email;

  const ResetPasswordConfirmation({super.key, required this.email});

  @override
  State<ResetPasswordConfirmation> createState() =>
      _ResetPasswordConfirmationState();
}

class _ResetPasswordConfirmationState extends State<ResetPasswordConfirmation> {
  bool isResending = false;

  Future<void> _resendResetEmail() async {
    setState(() => isResending = true);
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: widget.email);
      _showSuccess('Password reset email sent again! Please check your inbox.');
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Failed to resend email';
      if (e.code == 'too-many-requests') {
        errorMessage = 'Too many requests. Please wait before trying again.';
      }
      _showError(errorMessage);
    } catch (e) {
      _showError('Error: $e');
    } finally {
      setState(() => isResending = false);
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.all(16),
        duration: Duration(seconds: 3),
        elevation: 8,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100], // light background
      appBar: AppBar(
        title: Text(
          'Check Your Email',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.teal[600],
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(25.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Email icon with shadow
              Container(
                padding: EdgeInsets.all(25),
                decoration: BoxDecoration(
                  color: Colors.teal.withOpacity(0.15),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 12,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.email_outlined,
                  size: 90,
                  color: Colors.teal[600],
                ),
              ),
              SizedBox(height: 30),

              // Title
              Text(
                'Check Your Email',
                style: TextStyle(
                  fontSize: 34,
                  color: Colors.teal[700],
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 18),

              // Description
              Container(
                width: 350,
                child: Column(
                  children: [
                    Text(
                      'We\'ve sent a password reset link to:',
                      style: TextStyle(fontSize: 18, color: Colors.grey[700]),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 12),
                    Text(
                      widget.email,
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.teal[700],
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Please check your email and click the link to reset your password. The link will expire in 24 hours.',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 35),

              // Instructions
              Container(
                width: 350,
                padding: EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.blue.withOpacity(0.2)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue, size: 35),
                    SizedBox(height: 15),
                    Text(
                      'What to do next:',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      '1. Check your email inbox\n'
                      '2. Look for an email from TaleHive\n'
                      '3. Click the "Reset Password" link\n'
                      '4. Create your new password\n'
                      '5. Return to login with new password',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[700],
                        height: 1.6,
                      ),
                      textAlign: TextAlign.left,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 35),

              // Resend email button
              TextButton.icon(
                onPressed: isResending ? null : _resendResetEmail,
                icon: isResending
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.teal,
                        ),
                      )
                    : Icon(Icons.refresh, color: Colors.teal),
                label: Text(
                  isResending ? 'Sending...' : 'Didn\'t receive email? Resend',
                  style: TextStyle(
                    color: Colors.teal[700],
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SizedBox(height: 20),

              // Back to Login button
              ElevatedButton(
                onPressed: () {
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal[600],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25.0),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 60, vertical: 18),
                  textStyle: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                child: Text('BACK TO LOGIN'),
              ),
              SizedBox(height: 50),

              // Branding
              Column(
                children: [
                  Text(
                    'TaleHive',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal[700],
                    ),
                  ),
                  SizedBox(height: 6),
                  Container(
                    width: 300,
                    child: Text(
                      'Your Premier Digital Library for Exploring Technical, Training, and IT Books',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey[800],
                        height: 1.4,
                      ),
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
