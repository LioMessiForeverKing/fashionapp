import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import '../utils/constants.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  bool _isLoading = false;
  late AnimationController _fadeController;
  late AnimationController _sparkleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _sparkleAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animations
    _fadeController = AnimationController(
      duration: AppConstants.animationSlow,
      vsync: this,
    );

    _sparkleController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _sparkleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _sparkleController, curve: Curves.easeInOut),
    );

    // Start animations
    _fadeController.forward();
    _sparkleController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _sparkleController.dispose();
    super.dispose();
  }

  Future<void> _signInWithGoogle() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    // Haptic feedback
    HapticFeedback.lightImpact();

    try {
      await AuthService.signInWithGoogle();
    } catch (e) {
      if (!mounted) return;

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Sign-in failed. Please try again.',
            style: TextStyle(
              fontFamily: AppConstants.secondaryFont,
              color: AppConstants.neutralWhite,
            ),
          ),
          backgroundColor: AppConstants.accentCoral,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusM),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppConstants.primaryBlue,
              AppConstants.accentPink,
              AppConstants.accentYellow,
            ],
            stops: [0.0, 0.6, 1.0],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight:
                      screenHeight -
                      MediaQuery.of(context).padding.top -
                      MediaQuery.of(context).padding.bottom,
                ),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.spacingL,
                      vertical: AppConstants.spacingXL,
                    ),
                    child: Column(
                      children: [
                        // Top spacing
                        SizedBox(height: screenHeight * 0.08),

                        // Logo and Title Section
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Sparkle Animation
                            AnimatedBuilder(
                              animation: _sparkleAnimation,
                              builder: (context, child) {
                                return Transform.rotate(
                                  angle: _sparkleAnimation.value * 0.1,
                                  child: Container(
                                    width: 100,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: RadialGradient(
                                        colors: [
                                          AppConstants.neutralWhite.withValues(
                                            alpha: 0.3,
                                          ),
                                          AppConstants.neutralWhite.withValues(
                                            alpha: 0.1,
                                          ),
                                          Colors.transparent,
                                        ],
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.auto_awesome,
                                      size: 50,
                                      color: AppConstants.neutralWhite,
                                    ),
                                  ),
                                );
                              },
                            ),

                            const SizedBox(height: AppConstants.spacingL),

                            // App Title
                            const Text(
                              'Closet Fairy',
                              style: TextStyle(
                                fontFamily: AppConstants.primaryFont,
                                fontSize: 36,
                                fontWeight: FontWeight.w700,
                                color: AppConstants.textDark,
                                letterSpacing: -0.5,
                              ),
                            ),

                            const SizedBox(height: AppConstants.spacingM),

                            // Subtitle
                            Text(
                              'Your personal style fairy\nis here to help! 🧚‍♀️',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: AppConstants.secondaryFont,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: AppConstants.textDark.withValues(
                                  alpha: 0.8,
                                ),
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: AppConstants.spacingXL),

                        // Tagline
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppConstants.spacingL,
                            vertical: AppConstants.spacingM,
                          ),
                          decoration: BoxDecoration(
                            color: AppConstants.neutralWhite.withValues(
                              alpha: 0.2,
                            ),
                            borderRadius: BorderRadius.circular(
                              AppConstants.radiusXL,
                            ),
                            border: Border.all(
                              color: AppConstants.neutralWhite.withValues(
                                alpha: 0.3,
                              ),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            'Transform your closet\ninto endless outfits',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: AppConstants.secondaryFont,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppConstants.textDark.withValues(
                                alpha: 0.9,
                              ),
                              height: 1.3,
                            ),
                          ),
                        ),

                        const Spacer(),

                        // Google Sign In Button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _signInWithGoogle,
                            style:
                                ElevatedButton.styleFrom(
                                  backgroundColor: AppConstants.neutralWhite,
                                  foregroundColor: AppConstants.textDark,
                                  elevation: 8,
                                  shadowColor: AppConstants.textDark.withValues(
                                    alpha: 0.2,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      AppConstants.radiusL,
                                    ),
                                  ),
                                ).copyWith(
                                  overlayColor: WidgetStateProperty.all(
                                    AppConstants.primaryBlue.withValues(
                                      alpha: 0.1,
                                    ),
                                  ),
                                ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        AppConstants.textDark,
                                      ),
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      // Google Icon
                                      Container(
                                        width: 24,
                                        height: 24,
                                        decoration: const BoxDecoration(
                                          image: DecorationImage(
                                            image: NetworkImage(
                                              'https://developers.google.com/identity/images/g-logo.png',
                                            ),
                                            fit: BoxFit.contain,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(
                                        width: AppConstants.spacingM,
                                      ),
                                      Text(
                                        'Continue with Google',
                                        style: TextStyle(
                                          fontFamily:
                                              AppConstants.secondaryFont,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: AppConstants.textDark,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),

                        const SizedBox(height: AppConstants.spacingL),

                        // Privacy Notice
                        Text(
                          'By continuing, you agree to our Terms of Service\nand Privacy Policy',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: AppConstants.secondaryFont,
                            fontSize: 12,
                            color: AppConstants.textDark.withValues(alpha: 0.6),
                            height: 1.3,
                          ),
                        ),

                        const SizedBox(height: AppConstants.spacingL),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
