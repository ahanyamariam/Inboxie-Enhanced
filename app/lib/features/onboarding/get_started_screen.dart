import 'package:flutter/material.dart';
import 'package:app/core/theme/app_colors.dart';
import 'package:app/features/splash/presentation/widgets/wave_clippers.dart';
import 'package:app/features/auth/auth_screen.dart';

class GetStartedScreen extends StatefulWidget {
  const GetStartedScreen({super.key});

  @override
  State<GetStartedScreen> createState() => _GetStartedScreenState();
}

class _GetStartedScreenState extends State<GetStartedScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _contentController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _contentController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: Curves.easeOut,
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: Curves.easeOutCubic,
      ),
    );

    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _contentController.forward();
    });
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  void _navigateToAuth() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, _, __) => const AuthScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // Simple fade transition
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            ),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Stack(
        children: [
          // ============ TOP CONTENT ============
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 60),

                  SlideTransition(
                    position: _slideAnimation,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // App Logo Row
                          Row(
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryBlue,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(
                                  Icons.mail_outline_rounded,
                                  color: AppColors.textLight,
                                  size: 26,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Row(
                                children: [
                                  const Text(
                                    'Inb',
                                    style: TextStyle(
                                      color: AppColors.primaryBlue,
                                      fontSize: 24,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  Container(
                                    width: 18,
                                    height: 18,
                                    margin:
                                        const EdgeInsets.symmetric(horizontal: 1),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: AppColors.primaryBlue,
                                        width: 2.5,
                                      ),
                                    ),
                                    child: Center(
                                      child: Container(
                                        width: 6,
                                        height: 6,
                                        decoration: const BoxDecoration(
                                          color: AppColors.accentYellow,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const Text(
                                    'xie',
                                    style: TextStyle(
                                      color: AppColors.primaryBlue,
                                      fontSize: 24,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),

                          const SizedBox(height: 50),

                          // Main Title
                          const Text(
                            'Tame Your',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 44,
                              fontWeight: FontWeight.w800,
                              height: 1.1,
                              letterSpacing: -1.5,
                            ),
                          ),
                          Row(
                            children: [
                              const Text(
                                'Inbox ',
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 44,
                                  fontWeight: FontWeight.w800,
                                  height: 1.1,
                                  letterSpacing: -1.5,
                                ),
                              ),
                              Text(
                                'Mess.',
                                style: TextStyle(
                                  color: AppColors.accentYellow,
                                  fontSize: 44,
                                  fontWeight: FontWeight.w800,
                                  height: 1.1,
                                  letterSpacing: -1.5,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          Text(
                            'Inboxie filters the noise and highlights what actually matters. Ready to focus?',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 16,
                              height: 1.6,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ============ BOTTOM WAVES (Static) ============
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SizedBox(
              height: size.height * 0.48,
              child: Stack(
                children: [
                  // Yellow Wave
                  Positioned.fill(
                    child: ClipPath(
                      clipper: BottomYellowWaveClipper(),
                      child: Container(
                        color: AppColors.accentYellow,
                      ),
                    ),
                  ),

                  // Blue Wave with Content
                  Positioned.fill(
                    child: ClipPath(
                      clipper: BottomBlueWaveClipper(),
                      child: Container(
                        color: AppColors.primaryBlue,
                        child: SafeArea(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                // Get Started Button
                                SlideTransition(
                                  position: _slideAnimation,
                                  child: FadeTransition(
                                    opacity: _fadeAnimation,
                                    child: SizedBox(
                                      width: double.infinity,
                                      height: 56,
                                      child: ElevatedButton(
                                        onPressed: _navigateToAuth,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.textLight,
                                          foregroundColor: AppColors.primaryBlue,
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(16),
                                          ),
                                        ),
                                        child: const Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              'Get Started',
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            SizedBox(width: 8),
                                            Icon(Icons.arrow_forward_rounded,
                                                size: 22),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 16),

                                FadeTransition(
                                  opacity: _fadeAnimation,
                                  child: const Text(
                                    'Smart. Simple. Focused.',
                                    style: TextStyle(
                                      color: AppColors.textLight,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 40),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}