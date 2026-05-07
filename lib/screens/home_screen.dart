import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_button.dart';
import '../widgets/outline_button.dart';
import '../widgets/action_card.dart';
import '../providers/auth_provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isAuthenticated = authProvider.isAuthenticated;
    final userRole = authProvider.currentUser?.role;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: AppTheme.primaryGradient,
        ),
        child: SafeArea(
          child: isAuthenticated
              ? _buildAuthenticatedHome(context, userRole)
              : _buildUnauthenticatedHome(context),
        ),
      ),
    );
  }

  Widget _buildUnauthenticatedHome(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 40),
          // Logo/Icon Section
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 3,
              ),
            ),
            child: const Icon(
              Icons.security,
              size: 60,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 32),
          // Title
          const Text(
            'SecureGate AI',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Campus Security & Device Verification',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.white,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 60),
          // Features Cards
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                _buildFeatureItem(
                  Icons.qr_code_scanner,
                  'QR Code Verification',
                  'Quick and secure device scanning',
                ),
                const SizedBox(height: 20),
                _buildFeatureItem(
                  Icons.photo_camera,
                  'AI Image Matching',
                  'Advanced device recognition',
                ),
                const SizedBox(height: 20),
                _buildFeatureItem(
                  Icons.shield,
                  'Secure Access',
                  'Protect your campus',
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          // Action Buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                GradientButton(
                  text: 'Get Started',
                  icon: Icons.arrow_forward,
                  onPressed: () => context.go('/login'),
                ),
                const SizedBox(height: 16),
                OutlineButton(
                  text: 'Create Account',
                  icon: Icons.person_add,
                  onPressed: () => context.go('/register'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String subtitle) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAuthenticatedHome(BuildContext context, String? role) {
    final authProvider = Provider.of<AuthProvider>(context);
    
    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome Back${authProvider.currentUser?.fullName != null ? ', ${authProvider.currentUser!.fullName!.split(' ').first}' : ''}!',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Ready to get started?',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () => context.go('/profile'),
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: authProvider.currentUser?.profilePictureUrl != null
                      ? ClipOval(
                          child: CachedNetworkImage(
                            imageUrl: authProvider.currentUser!.profilePictureUrl!,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => const Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 28,
                            ),
                            errorWidget: (context, url, error) => const Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                        )
                      : const Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 28,
                        ),
                ),
              ),
            ],
          ),
        ),
        // Content
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(top: 20),
            decoration: const BoxDecoration(
              color: AppTheme.backgroundWhite,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  if (role == 'student' || role == 'staff') ...[
                    ActionCard(
                      title: 'Register Device',
                      subtitle: 'Add a new device to your account',
                      icon: Icons.add_circle_outline,
                      onTap: () => context.go('/register-device'),
                    ),
                    ActionCard(
                      title: 'My Devices',
                      subtitle: 'View all your registered devices',
                      icon: Icons.devices,
                      onTap: () => context.go('/my-devices'),
                    ),
                  ],
                  if (role == 'officer' || role == 'admin') ...[
                    ActionCard(
                      title: 'Scan QR Code',
                      subtitle: 'Verify device access',
                      icon: Icons.qr_code_scanner,
                      onTap: () => context.go('/scan'),
                    ),
                  ],
                  if (role == 'admin') ...[
                    ActionCard(
                      title: 'Dashboard',
                      subtitle: 'View system analytics',
                      icon: Icons.dashboard,
                      onTap: () => context.go('/dashboard'),
                    ),
                  ],
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
