import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminResetPasswordConfirmation extends StatefulWidget {
  final String email;
  
  const AdminResetPasswordConfirmation({
    super.key,
    required this.email,
  });

  @override
  State<AdminResetPasswordConfirmation> createState() => _AdminResetPasswordConfirmationState();
}

class _AdminResetPasswordConfirmationState extends State<AdminResetPasswordConfirmation> {
  bool isResending = false;

  Future<void> _resendAdminResetEmail() async {
    setState(() => isResending = true);
    try {
      // Resend password reset email directly through Firebase Auth
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: widget.email,
      );
      _showSuccess('Admin password reset email sent again! Please check your inbox.');
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
        title: Text('Check Your Email'),
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
              // Email icon with admin styling
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.lightGreen.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.admin_panel_settings,
                  size: 80,
                  color: Colors.lightGreen,
                ),
              ),
              SizedBox(height: 30),
              
              // Title
              Text(
                'Check Your Email',
                style: TextStyle(
                  fontSize: 32,
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 20),
              
              // Description
              Container(
                width: 350,
                child: Column(
                  children: [
                    Text(
                      'We\'ve sent an admin password reset link to:',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 10),
                    Text(
                      widget.email,
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Please check your email and click the link to reset your admin password. The link will expire in 24 hours.',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 40),
              
              // Instructions for admin
              Container(
                width: 350,
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.blue.withOpacity(0.2)),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.security,
                      color: Colors.blue,
                      size: 30,
                    ),
                    SizedBox(height: 15),
                    Text(
                      'Admin Password Reset Steps:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      '1. Check your admin email inbox\n'
                      '2. Look for an email from TaleHive Admin\n'
                      '3. Click the "Reset Password" link\n'
                      '4. Create your new admin password\n'
                      '5. Return to admin login with new password',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[700],
                        height: 1.5,
                      ),
                      textAlign: TextAlign.left,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 30),
              
              // Resend email button
              TextButton.icon(
                onPressed: isResending ? null : _resendAdminResetEmail,
                icon: isResending 
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.lightGreen,
                        ),
                      )
                    : Icon(Icons.refresh, color: Colors.lightGreen),
                label: Text(
                  isResending ? 'Sending...' : 'Didn\'t receive email? Resend',
                  style: TextStyle(
                    color: Colors.lightGreen,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              SizedBox(height: 20),
              
              // Back to Admin Login button
              ElevatedButton(
                onPressed: () {
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.lightGreen,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: 60,
                    vertical: 15,
                  ),
                ),
                child: Text(
                  'BACK TO ADMIN LOGIN',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
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
                      'Admin Portal - Your Premier Digital Library Management System',
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
