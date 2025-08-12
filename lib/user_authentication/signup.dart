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
  
  // Add role selection
  String selectedRole = 'Reader'; // Default role
  final List<String> roles = ['Reader', 'Author'];

  Future<void> _registerUser() async {
    if (_formKey.currentState!.validate()) {
      try {
        setState(() => isLoading = true);

        // Create user in Firebase Auth
        UserCredential userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
              email: emailController.text.trim(),
              password: passwordController.text.trim(),
            );

        // Determine collection based on role
        String collection = selectedRole == 'Author' ? 'authors' : 'users';
        
        // Prepare common data
        Map<String, dynamic> userData = {
          'firstName': firstNameController.text.trim(),
          'lastName': lastNameController.text.trim(),
          'contactNo': contactController.text.trim(),
          'email': emailController.text.trim(),
          'username': usernameController.text.trim(),
          'uid': userCredential.user!.uid,
          'role': selectedRole.toLowerCase(),
          'createdAt': Timestamp.now(),
          'lastLoginAt': Timestamp.now(),
          'isActive': true,
        };

        // Add role-specific fields
        if (selectedRole == 'Author') {
          userData.addAll({
            'displayName': '${firstNameController.text.trim()} ${lastNameController.text.trim()}',
            'photoURL': '',
            'booksPublished': 0,
            'totalViews': 0,
            'totalDownloads': 0,
            'bio': 'Passionate storyteller ready to share amazing stories.',
            'specialization': [],
            'socialLinks': {
              'website': '',
              'twitter': '',
              'linkedin': '',
            },
            'verificationStatus': 'pending',
          });
        } else {
          userData.addAll({
            'booksRead': 0,
            'favoriteGenres': 'Fiction, Science',
            'photoURL': '',
          });
        }

        // Save user info in appropriate Firestore collection
        await FirebaseFirestore.instance
            .collection(collection)
            .doc(userCredential.user!.uid)
            .set(userData);

        // Show success message based on role
        String successMessage = selectedRole == 'Author' 
            ? 'Author account created successfully! Please login to start publishing'
            : 'Reader account created successfully! Please login to start reading';
        
        _showSuccess(successMessage);

        // Navigate back to login
        Navigator.pop(context);
      } on FirebaseAuthException catch (e) {
        String errorMessage = 'An error occurred';
        if (e.code == 'email-already-in-use') {
          errorMessage = 'This email is already registered. Please use a different email or try logging in instead.';
        } else if (e.code == 'weak-password') {
          errorMessage = 'Password is too weak. Please use at least 6 characters with a mix of letters and numbers.';
        } else if (e.code == 'invalid-email') {
          errorMessage = 'Please enter a valid email address.';
        } else if (e.code == 'operation-not-allowed') {
          errorMessage = 'Email/password accounts are not enabled. Please contact support.';
        } else if (e.code == 'too-many-requests') {
          errorMessage = 'Too many attempts. Please try again later.';
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
        title: Text('Sign Up'),
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
              Image.asset(
                'Asset/images/logo.jpg', // Assuming the logo is here
                height: 100,
              ),
              SizedBox(height: 20),
              Text(
                'Sign Up',
                style: TextStyle(fontSize: 40, color: Colors.blue),
              ),
              Text('Please provide your information to sign up.'),
              SizedBox(height: 20),
              
              // Role Selection Card
              Container(
                width: 450,
                margin: EdgeInsets.only(bottom: 20),
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select Your Role',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[800],
                      ),
                    ),
                    SizedBox(height: 12),
                    Row(
                      children: roles.map((role) {
                        bool isSelected = selectedRole == role;
                        Color roleColor = role == 'Author' ? Colors.purple : Colors.blue;
                        IconData roleIcon = role == 'Author' ? Icons.edit_outlined : Icons.book_outlined;
                        
                        return Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedRole = role;
                              });
                            },
                            child: Container(
                              margin: EdgeInsets.only(right: role == 'Reader' ? 8 : 0),
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isSelected ? roleColor.withOpacity(0.1) : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected ? roleColor : Colors.grey[300]!,
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    roleIcon,
                                    color: isSelected ? roleColor : Colors.grey[600],
                                    size: 32,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    role,
                                    style: TextStyle(
                                      color: isSelected ? roleColor : Colors.grey[600],
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      fontSize: 14,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    role == 'Author' ? 'Publish Stories' : 'Read Books',
                                    style: TextStyle(
                                      color: Colors.grey[500],
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              
              Container(
                width: 450,
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: firstNameController,
                              validator: (value) => value == null || value.isEmpty ? 'Enter first name' : null,
                              decoration: InputDecoration(
                                labelText: 'First Name',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(30.0),
                                  borderSide: BorderSide(
                                    color: selectedRole == 'Author' ? Colors.purple : Colors.lightGreen,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(30.0),
                                  borderSide: BorderSide(
                                    color: selectedRole == 'Author' ? Colors.purple : Colors.lightGreen,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(30.0),
                                  borderSide: BorderSide(
                                    color: selectedRole == 'Author' ? Colors.purple : Colors.lightGreenAccent,
                                    width: 2.0,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 10), // Spacing between fields
                          Expanded(
                            child: TextFormField(
                              controller: lastNameController,
                              validator: (value) => value == null || value.isEmpty ? 'Enter last name' : null,
                              decoration: InputDecoration(
                                labelText: 'Last Name',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(30.0),
                                  borderSide: BorderSide(
                                    color: selectedRole == 'Author' ? Colors.purple : Colors.lightGreen,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(30.0),
                                  borderSide: BorderSide(
                                    color: selectedRole == 'Author' ? Colors.purple : Colors.lightGreen,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(30.0),
                                  borderSide: BorderSide(
                                    color: selectedRole == 'Author' ? Colors.purple : Colors.lightGreenAccent,
                                    width: 2.0,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 15), // Spacing between rows
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: contactController,
                              validator: (value) => value == null || value.isEmpty ? 'Enter contact number' : null,
                              decoration: InputDecoration(
                                labelText: 'Contact No',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(30.0),
                                  borderSide: BorderSide(
                                    color: selectedRole == 'Author' ? Colors.purple : Colors.lightGreen,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(30.0),
                                  borderSide: BorderSide(
                                    color: selectedRole == 'Author' ? Colors.purple : Colors.lightGreen,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(30.0),
                                  borderSide: BorderSide(
                                    color: selectedRole == 'Author' ? Colors.purple : Colors.lightGreenAccent,
                                    width: 2.0,
                                  ),
                                ),
                              ),
                              keyboardType: TextInputType.phone,
                            ),
                          ),
                          SizedBox(width: 10), // Spacing between fields
                          Expanded(
                            child: TextFormField(
                              controller: emailController,
                              validator: (value) => value == null || !value.contains('@') || !value.contains('.') ? 'Enter valid email' : null,
                              decoration: InputDecoration(
                                labelText: 'Email',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(30.0),
                                  borderSide: BorderSide(
                                    color: selectedRole == 'Author' ? Colors.purple : Colors.lightGreen,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(30.0),
                                  borderSide: BorderSide(
                                    color: selectedRole == 'Author' ? Colors.purple : Colors.lightGreen,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(30.0),
                                  borderSide: BorderSide(
                                    color: selectedRole == 'Author' ? Colors.purple : Colors.lightGreenAccent,
                                    width: 2.0,
                                  ),
                                ),
                              ),
                              keyboardType: TextInputType.emailAddress,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 15), // Spacing between rows
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: usernameController,
                              validator: (value) => value == null || value.isEmpty ? 'Enter username' : null,
                              decoration: InputDecoration(
                                labelText: 'Username',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(30.0),
                                  borderSide: BorderSide(
                                    color: selectedRole == 'Author' ? Colors.purple : Colors.lightGreen,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(30.0),
                                  borderSide: BorderSide(
                                    color: selectedRole == 'Author' ? Colors.purple : Colors.lightGreen,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(30.0),
                                  borderSide: BorderSide(
                                    color: selectedRole == 'Author' ? Colors.purple : Colors.lightGreenAccent,
                                    width: 2.0,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 10), // Spacing between fields
                          Expanded(
                            child: TextFormField(
                              controller: passwordController,
                              validator: (value) => value == null || value.length < 6 ? 'Minimum 6 characters' : null,
                              decoration: InputDecoration(
                                labelText: 'Password',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(30.0),
                                  borderSide: BorderSide(
                                    color: selectedRole == 'Author' ? Colors.purple : Colors.lightGreen,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(30.0),
                                  borderSide: BorderSide(
                                    color: selectedRole == 'Author' ? Colors.purple : Colors.lightGreen,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(30.0),
                                  borderSide: BorderSide(
                                    color: selectedRole == 'Author' ? Colors.purple : Colors.lightGreenAccent,
                                    width: 2.0,
                                  ),
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _isPasswordVisible
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                    color: Colors.grey,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _isPasswordVisible = !_isPasswordVisible;
                                    });
                                  },
                                ),
                              ),
                              obscureText: !_isPasswordVisible,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20), // Spacing before button
              ElevatedButton(
                onPressed: isLoading ? null : _registerUser,
                style: ElevatedButton.styleFrom(
                  backgroundColor: selectedRole == 'Author' ? Colors.purple : Colors.lightGreen,
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
                        'SIGN UP AS ${selectedRole.toUpperCase()}', 
                        style: TextStyle(color: Colors.white)
                      ),
              ),
              SizedBox(height: 40), // Spacing before library info
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
                      selectedRole == 'Author' 
                          ? 'Your Platform to Publish and Share Amazing Stories with Thousands of Readers'
                          : 'Your Premier Digital Library for Exploring Technical, Training, and IT Books',
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
