import 'dart:async';
import 'dart:ui'; // Required for ImageFilter backdrop blur
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _animationController.forward();

    // ROUTING REDIRECT TRIGGER:
    Timer(const Duration(milliseconds: 3500), () {
      if (mounted) {
        // Safely navigate forward to the named route and clear the history stack
        Navigator.pushReplacementNamed(context, '/login');
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. Full Screen Mobile Background Image with BoxFit cover layout
          Positioned.fill(
            child: Image.asset(
              'assets/images/splash_background.png',
              fit: BoxFit.cover,
              // If you haven't added the image asset yet and it throws an error,
              // you can temporarily replace this Image.asset with a Solid Color container:
              // color: const Color(0xFFF4F9F8),
            ),
          ),

          // 2. BackdropFilter providing soft background blur intensity
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
              child: Container(
                color: Colors.black.withOpacity(0.0), // Invisible canvas surface requirement
              ),
            ),
          ),

          // 3. Main Dynamic Animated Layout Content Context
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(flex: 3),

                    // 4. Custom Medical Logo Stack Design with Shadow Elements
                    Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                        border: Border.all(
                          color: const Color(0xFFD4AF37), // Soft Gold Outline
                          width: 3,
                        ),
                      ),
                      child: Center(
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Icon(
                              Icons.favorite,
                              size: 85,
                              color: const Color(0xFF00796B).withOpacity(0.2),
                            ),
                            const Icon(
                              Icons.local_hospital,
                              size: 55,
                              color: Color(0xFF00796B), // Deep Teal Action Fill
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),

                    // 5. App Identity Typography Layout Headers
                    const Text(
                      'Health & Doctor\nAppointment',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A237E), // Professional Dark Navy
                        letterSpacing: 0.5,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 6. Catchy Tagline Messaging Row
                    const Text(
                      'Your Health, Your Schedule.',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF555555), // Muted Secondary Grey
                      ),
                    ),
                    const Spacer(flex: 3),

                    // 7. Contextual Baseline Progress Indicator Accent
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF00796B), width: 2),
                      ),
                      child: const Icon(
                        Icons.medical_services_outlined,
                        color: Color(0xFF00796B),
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 8. Footer Legal/Branding Metadata
                    Text(
                      'Powered by SafeCare Systems',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: Colors.grey.shade600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}