import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Signup extends StatefulWidget {
  const Signup({super.key});

  @override
  State<Signup> createState() => _SignupState();
}

class _SignupState extends State<Signup> {
  final _formKey = GlobalKey<FormState>();
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final contactController = TextEditingController();
  final emailController = TextEditingController();
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool isLoading = false;

  Future<void> _registerUser() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      setState(() => isLoading = true);

      // Create Firebase Auth user
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: emailController.text.trim(),
            password: passwordController.text.trim(),
          );

      // Save user info in Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
            'firstName': firstNameController.text.trim(),
            'lastName': lastNameController.text.trim(),
            'contactNo': contactController.text.trim(),
            'email': emailController.text.trim(),
            'username': usernameController.text.trim(),
            'uid': userCredential.user!.uid,
            'createdAt': Timestamp.now(),
          });

      _showSnackBar(
        'Account created successfully! Please login to continue.',
        isError: false,
      );

      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'email-already-in-use':
          message = 'This email is already registered. Try logging in instead.';
          break;
        case 'weak-password':
          message =
              'Password is too weak. Use at least 6 characters with letters & numbers.';
          break;
        case 'invalid-email':
          message = 'Please enter a valid email address.';
          break;
        case 'operation-not-allowed':
          message = 'Email/password accounts are disabled. Contact support.';
          break;
        case 'too-many-requests':
          message = 'Too many attempts. Try again later.';
          break;
        default:
          message = 'An unknown error occurred.';
      }
      _showSnackBar(message, isError: true);
    } catch (e) {
      _showSnackBar('Error: $e', isError: true);
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(message, style: const TextStyle(fontSize: 16)),
            ),
          ],
        ),
        backgroundColor: isError ? Colors.red[600] : Colors.green[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(30.0)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30.0),
        borderSide: const BorderSide(color: Colors.lightGreen),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30.0),
        borderSide: const BorderSide(
          color: Colors.lightGreenAccent,
          width: 2.0,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign Up'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Image.asset('Asset/images/logo.jpg', height: 100),
              const SizedBox(height: 20),
              const Text(
                'Sign Up',
                style: TextStyle(fontSize: 40, color: Colors.blue),
              ),
              const Text('Please provide your information to sign up.'),
              const SizedBox(height: 20),
              SizedBox(
                width: 450,
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: firstNameController,
                              validator: (v) => v == null || v.isEmpty
                                  ? 'Enter first name'
                                  : null,
                              decoration: _inputDecoration('First Name'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: lastNameController,
                              validator: (v) => v == null || v.isEmpty
                                  ? 'Enter last name'
                                  : null,
                              decoration: _inputDecoration('Last Name'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: contactController,
                              validator: (v) => v == null || v.isEmpty
                                  ? 'Enter contact number'
                                  : null,
                              keyboardType: TextInputType.phone,
                              decoration: _inputDecoration('Contact No'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: emailController,
                              validator: (v) =>
                                  v == null ||
                                      !v.contains('@') ||
                                      !v.contains('.')
                                  ? 'Enter valid email'
                                  : null,
                              keyboardType: TextInputType.emailAddress,
                              decoration: _inputDecoration('Email'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: usernameController,
                              validator: (v) => v == null || v.isEmpty
                                  ? 'Enter username'
                                  : null,
                              decoration: _inputDecoration('Username'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: passwordController,
                              validator: (v) => v == null || v.length < 6
                                  ? 'Minimum 6 characters'
                                  : null,
                              obscureText: !_isPasswordVisible,
                              decoration: _inputDecoration('Password').copyWith(
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _isPasswordVisible
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _isPasswordVisible = !_isPasswordVisible;
                                    });
                                  },
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: isLoading ? null : _registerUser,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.lightGreen,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30.0),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 80,
                            vertical: 15,
                          ),
                        ),
                        child: isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text(
                                'SIGN UP',
                                style: TextStyle(color: Colors.white),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),
              const Text(
                'TaleHive',
                style: TextStyle(fontSize: 24, color: Colors.blue),
              ),
              const SizedBox(
                width: 300,
                child: Text(
                  'Your Premier Digital Library for Exploring Technical, Training, and IT Books',
                  style: TextStyle(fontSize: 14, color: Colors.black87),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
