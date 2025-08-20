import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../pages/user/author_dashboard.dart';
import '../pages/user/user_home.dart';

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
  
  String selectedRole = 'Reader';
  final List<String> roles = ['Reader', 'Author'];
  final supabase = Supabase.instance.client;

  Future<void> _registerUser() async {
    if (_formKey.currentState!.validate()) {
      try {
        setState(() => isLoading = true);

        // First check if email already exists in our tables
        final existingUser = await supabase
            .from('users')
            .select('email')
            .eq('email', emailController.text.trim())
            .maybeSingle();
        
        final existingAuthor = await supabase
            .from('authors')
            .select('email')
            .eq('email', emailController.text.trim())
            .maybeSingle();

        if (existingUser != null || existingAuthor != null) {
          _showError('This email is already registered. Please login instead.');
          return;
        }

        // Check if username already exists (for readers only)
        if (selectedRole == 'Reader') {
          final existingUsername = await supabase
              .from('users')
              .select('username')
              .eq('username', usernameController.text.trim())
              .maybeSingle();
          
          if (existingUsername != null) {
            _showError('Username already exists. Please choose a different username.');
            return;
          }
        }

        final AuthResponse response = await supabase.auth.signUp(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
          data: {
            'role': selectedRole.toLowerCase(),
            'first_name': firstNameController.text.trim(),
            'last_name': lastNameController.text.trim(),
            'contact_no': contactController.text.trim(),
            'username': usernameController.text.trim(),
            'display_name': '${firstNameController.text.trim()} ${lastNameController.text.trim()}',
          },
        );

        if (response.user != null) {
          try {
            String table = selectedRole == 'Author' ? 'authors' : 'users';
            
            // Base data that both tables have
            Map<String, dynamic> userData = {
              'id': response.user!.id,
              'email': emailController.text.trim(),
              'first_name': firstNameController.text.trim(),
              'last_name': lastNameController.text.trim(),
              'contact_no': contactController.text.trim(),
              'role': selectedRole.toLowerCase(),
            };

            // Add table-specific fields
            if (selectedRole == 'Author') {
              userData.addAll({
                'display_name': '${firstNameController.text.trim()} ${lastNameController.text.trim()}',
                'bio': 'Passionate storyteller ready to share amazing stories.',
                'books_published': 0,
                'total_views': 0,
                'total_downloads': 0,
                'verification_status': 'pending',
                'is_active': true,
              });
            } else {
              userData.addAll({
                'username': usernameController.text.trim(),
                'favorite_genres': 'Fiction, Science',
                'books_read': 0,
                'is_active': true,
              });
            }

            // Insert user data into custom table
            await supabase.from(table).insert(userData);

            // Show success message and navigate to appropriate dashboard
            _showSuccess('Account created successfully! Please check your email to verify.');
            
            // Clear form
            _clearForm();
            
            // Navigate to appropriate dashboard based on role
            Future.delayed(const Duration(seconds: 2), () {
              if (mounted) {
                if (selectedRole == 'Author') {
                  // Navigate to author dashboard
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const AuthorDashboardPage()),
                    (route) => false,
                  );
                } else {
                  // Navigate to user home for readers
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const UserHomePage()),
                    (route) => false,
                  );
                }
              }
            });

          } catch (dbError) {
            print('Database error: $dbError');
            
            // Show specific error messages
            String errorMessage = 'Failed to create profile';
            
            if (dbError.toString().contains('duplicate key value violates unique constraint')) {
              if (dbError.toString().contains('username')) {
                errorMessage = 'Username already exists. Please choose a different username.';
              } else if (dbError.toString().contains('email')) {
                errorMessage = 'Email already exists. Please use a different email.';
              } else {
                errorMessage = 'This account already exists. Please login instead.';
              }
            } else if (dbError.toString().contains('violates not-null constraint')) {
              errorMessage = 'Please fill in all required fields.';
            } else if (dbError.toString().contains('invalid input syntax')) {
              errorMessage = 'Please check your input and try again.';
            } else {
              errorMessage = 'Profile creation failed. The account was created but profile setup incomplete.';
            }
            
            _showError(errorMessage);
          }
        } else {
          _showError('Failed to create account. Please try again.');
        }
      } on AuthException catch (e) {
        print('Auth error: $e');
        String errorMessage = 'Signup failed';
        
        if (e.message.contains('rate limit') || e.message.contains('too many')) {
          errorMessage = 'Too many signup attempts. Please wait a few minutes and try again.';
        } else if (e.message.contains('already registered') || e.message.contains('already exists')) {
          errorMessage = 'This email is already registered. Please login instead.';
        } else if (e.message.contains('invalid email')) {
          errorMessage = 'Please enter a valid email address.';
        } else if (e.message.contains('weak password')) {
          errorMessage = 'Password is too weak. Please use at least 6 characters.';
        } else {
          errorMessage = e.message;
        }
        
        _showError(errorMessage);
      } catch (e) {
        print('General error: $e');
        _showError('Network error. Please check your connection and try again.');
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

  void _clearForm() {
    firstNameController.clear();
    lastNameController.clear();
    contactController.clear();
    emailController.clear();
    usernameController.clear();
    passwordController.clear();
    setState(() {
      selectedRole = 'Reader';
    });
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
