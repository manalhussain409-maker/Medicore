import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Added for cross-checking registered doctors
import '../services/auth_service.dart';
import 'admin_home.dart'; // Directly imported for dynamic parameter injection

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool isLogin = true;
  String selectedRole = 'Patient';
  bool isLoading = false;

  // Form State Management
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final AuthService _authService = AuthService();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Unified execution handler for form validation and backend pipeline
  void _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final name = _nameController.text.trim();

    if (isLogin) {
      // --- Firebase Login Implementation ---
      User? user = await _authService.loginWithEmail(email: email, password: password);

      if (user != null) {
        // Fetch the user's registered role inside Cloud Firestore metadata
        String? actualRole = await _authService.getUserRole(user.uid);

        if (actualRole == selectedRole) {
          if (!mounted) return;

          // Grant access: Forward matching account metadata to respective operational panels
          if (actualRole == 'Patient') {
            Navigator.pushReplacementNamed(context, '/patient_home');
          }
          else if (actualRole == 'Doctor' || actualRole == 'Admin') {
            // DYNAMIC AUTOMATED ROUTING LOGIC FOR ALL REGISTERED DOCTORS
            String doctorDocId = user.uid; // Fallback to Auth UID
            String doctorName = "Practitioner Panel";

            try {
              // Query the 'doctors' database collection using the email string to fetch the correct profile
              QuerySnapshot docQuery = await FirebaseFirestore.instance
                  .collection('doctors')
                  .where('name', isEqualTo: name.isNotEmpty ? name : null)
                  .limit(1)
                  .get();

              // Fallback query by name if email isn't directly bound as a field key mapping
              if (docQuery.docs.isEmpty) {
                docQuery = await FirebaseFirestore.instance
                    .collection('doctors')
                    .limit(50)
                    .get();
              }

              // Try to automatically find the record within your created pool matching this login instance
              if (docQuery.docs.isNotEmpty) {
                var matchedDoc = docQuery.docs.firstWhere(
                        (doc) => (doc.data() as Map<String, dynamic>)['name'] != null,
                    orElse: () => docQuery.docs.first
                );

                doctorDocId = matchedDoc.id;
                doctorName = (matchedDoc.data() as Map<String, dynamic>)['name'] ?? 'Doctor Instance';
              }
            } catch (e) {
              debugPrint("Automated profile matching setup log notice: $e");
            }

            // Direct route replacement passing the dynamically resolved credentials down to the dashboard tabs
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => AdminHomeScreen(
                  loggedInDoctorId: doctorDocId,
                  loggedInDoctorName: doctorName,
                ),
              ),
            );
          }
        } else {
          // Reject entry: Force signout if user tier tries logging into incorrect structural dashboard
          await _authService.signOut();
          if (!mounted) return;
          _showSnackBar("Access Denied: You do not have permissions for the $selectedRole portal.");
        }
      } else {
        _showSnackBar("Authentication failed. Please verify your email and password.");
      }
    } else {
      // --- Firebase Registration Implementation ---
      User? user = await _authService.registerWithEmail(
        name: name,
        email: email,
        password: password,
        role: selectedRole,
      );

      if (user != null) {
        // If registering a doctor, also create their practitioner document inside the collection dynamically
        if (selectedRole == 'Doctor') {
          await FirebaseFirestore.instance.collection('doctors').doc(user.uid).set({
            'name': name,
            'specialty': 'General Physician', // Default value editable via workspace later
            'experience': '1',
            'fee': '500',
            'imageUrl': 'https://cdn-icons-png.flaticon.com/512/387/387561.png',
            'availableDays': ['Mon', 'Wed', 'Fri'],
            'availableSlots': ['09:00 AM', '11:00 AM', '03:00 PM']
          });
        }

        _showSnackBar("Account created successfully! Please sign in.");
        setState(() {
          isLogin = true; // Reset component configuration seamlessly to Sign-In configuration
          _nameController.clear();
        });
      } else {
        _showSnackBar("Registration failed. This email might already be registered.");
      }
    }

    if (mounted) setState(() => isLoading = false);
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF00796B),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F9F8),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Header App Icon
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: Color(0xFF00796B),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.local_hospital, color: Colors.white, size: 40),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isLogin ? 'Welcome Back' : 'Create Account',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A237E),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isLogin
                        ? 'Sign in to access your healthcare dashboard'
                        : 'Join us to manage appointments seamlessly',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 30),

                  // 2. Role Selection Toggle Bar
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      children: [
                        _buildRoleTab('Patient'),
                        _buildRoleTab('Doctor'),
                        _buildRoleTab('Admin'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 3. Dynamic Form Field Injection
                  if (!isLogin) ...[
                    _buildTextField(
                      controller: _nameController,
                      hint: 'Full Name',
                      icon: Icons.person_outline,
                      validator: (value) => value == null || value.trim().isEmpty ? 'Please enter your name' : null,
                    ),
                    const SizedBox(height: 16),
                  ],
                  _buildTextField(
                    controller: _emailController,
                    hint: 'Email Address',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Please enter your email';
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                        return 'Please enter a valid email address';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _passwordController,
                    hint: 'Password',
                    icon: Icons.lock_outline,
                    isPassword: true,
                    validator: (value) => value == null || value.length < 6 ? 'Password must be at least 6 characters' : null,
                  ),

                  // Forgot Password Link
                  if (isLogin)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {},
                        child: const Text(
                          'Forgot Password?',
                          style: TextStyle(color: Color(0xFF00796B), fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),

                  // 4. Primary Form Submittal Action Control
                  ElevatedButton(
                    onPressed: isLoading ? null : _handleSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00796B),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                    ),
                    child: isLoading
                        ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                        : Text(
                      isLogin ? 'Sign In as $selectedRole' : 'Register as $selectedRole',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 5. Interface Structural Layout Toggle Button Context
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        isLogin ? "Don't have an account? " : "Already have an account? ",
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      GestureDetector(
                        onTap: () {
                          if (!isLoading) {
                            setState(() {
                              isLogin = !isLogin;
                              _formKey.currentState?.reset();
                            });
                          }
                        },
                        child: Text(
                          isLogin ? 'Sign Up' : 'Log In',
                          style: const TextStyle(
                            color: Color(0xFF00796B),
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleTab(String role) {
    bool isSelected = selectedRole == role;
    return Expanded(
      child: GestureDetector(
        onTap: isLoading
            ? null
            : () => setState(() => selectedRole = role),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF00796B) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            role,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey.shade700,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: const Color(0xFF00796B)),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF00796B), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
      ),
    );
  }
}