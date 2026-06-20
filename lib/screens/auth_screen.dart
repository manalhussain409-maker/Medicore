import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../services/doctor_service.dart';
import 'admin_home.dart';
import 'doctor_home.dart';
import 'patient_home_refactored.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool isLogin = true;
  String selectedRole = 'Patient';
  bool isLoading = false;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final AuthService _authService = AuthService();
  final UserService _userService = UserService();
  final DoctorService _doctorService = DoctorService();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final name = _nameController.text.trim();

    if (isLogin) {
      final User? user = await _authService.loginWithEmail(
        email: email,
        password: password,
      );

      if (user != null) {
        final String? actualRole = await _authService.getUserRole(user.uid);

        if (actualRole == selectedRole) {
          if (!mounted) return;
          await _userService.setUserOnlineStatus(user.uid, true);

          if (actualRole == 'Patient') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const PatientHomeScreenRefactored(),
              ),
            );
          } else if (actualRole == 'Doctor') {
            final profile = await _userService.getUserById(user.uid);
            if (!mounted) return;
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => DoctorHomeScreen(
                  loggedInDoctorId: user.uid,
                  loggedInDoctorName:
                      profile?.name ?? (name.isNotEmpty ? name : 'Doctor'),
                ),
              ),
            );
          } else {
            final profile = await _userService.getUserById(user.uid);
            if (!mounted) return;
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => AdminHomeScreen(
                  loggedInDoctorId: user.uid,
                  loggedInDoctorName:
                      profile?.name ?? (name.isNotEmpty ? name : 'Admin'),
                  userRole: actualRole ?? 'Admin',
                ),
              ),
            );
          }
        } else {
          await _authService.signOut();
          if (!mounted) return;
          _showSnackBar(
            'Access denied. Your account is registered as $actualRole, not $selectedRole.',
          );
        }
      } else {
        _showSnackBar('Invalid email or password. Please try again.');
      }
    } else {
      if (selectedRole == 'Doctor') {
        final hasPending = await _doctorService.hasPendingDoctor(email);
        if (!hasPending) {
          if (mounted) {
            setState(() => isLoading = false);
            _showSnackBar(
              'You cannot register as a Doctor. Only emails added by the Admin can register.',
            );
          }
          return;
        }
      }

      final User? user = await _authService.registerWithEmail(
        name: name,
        email: email,
        password: password,
        role: selectedRole,
      );

      if (user != null) {
        _showSnackBar('Account created! Please sign in.');
        setState(() {
          isLogin = true;
          _nameController.clear();
        });
      } else {
        _showSnackBar('Registration failed. Email may already be in use.');
      }
    }

    if (mounted) setState(() => isLoading = false);
  }

  Future<void> _handleForgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showSnackBar('Enter your email address first.');
      return;
    }
    setState(() => isLoading = true);
    final success = await _authService.resetPassword(email);
    if (mounted) {
      setState(() => isLoading = false);
      _showSnackBar(
        success
            ? 'Password reset link sent to $email'
            : 'Could not send reset email. Check your address.',
      );
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF00796B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF00796B), Color(0xFF004D40)],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00796B).withOpacity(0.3),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.local_hospital_rounded,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    isLogin ? 'Welcome Back' : 'Join Medicore',
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
                        ? 'Sign in to your healthcare dashboard'
                        : 'Create an account to book appointments',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 28),
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
                        if (isLogin) _buildRoleTab('Admin'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (!isLogin) ...[
                    _buildTextField(
                      controller: _nameController,
                      hint: 'Full Name',
                      icon: Icons.person_outline,
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Enter your name' : null,
                    ),
                    const SizedBox(height: 16),
                  ],
                  _buildTextField(
                    controller: _emailController,
                    hint: 'Email Address',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Enter your email';
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                          .hasMatch(v)) {
                        return 'Enter a valid email';
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
                    validator: (v) => v == null || v.length < 6
                        ? 'Password must be at least 6 characters'
                        : null,
                  ),
                  if (isLogin)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: isLoading ? null : _handleForgotPassword,
                        child: const Text(
                          'Forgot Password?',
                          style: TextStyle(
                            color: Color(0xFF00796B),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: isLoading ? null : _handleSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00796B),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            isLogin
                                ? 'Sign In as $selectedRole'
                                : 'Register as $selectedRole',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        isLogin
                            ? "Don't have an account? "
                            : 'Already have an account? ',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      GestureDetector(
                        onTap: isLoading
                            ? null
                            : () => setState(() {
                                  isLogin = !isLogin;
                                  if (!isLogin && selectedRole == 'Admin') {
                                    selectedRole = 'Patient';
                                  }
                                  _formKey.currentState?.reset();
                                }),
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
    final isSelected = selectedRole == role;
    return Expanded(
      child: GestureDetector(
        onTap: isLoading ? null : () => setState(() => selectedRole = role),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
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
              fontSize: 13,
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
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF00796B), width: 1.5),
        ),
      ),
    );
  }
}
