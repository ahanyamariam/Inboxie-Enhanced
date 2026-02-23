import 'package:flutter/material.dart';
import 'package:app/core/theme/app_colors.dart';
import 'package:app/services/auth_service.dart';
import 'package:app/features/splash/presentation/widgets/wave_clippers.dart';
import 'package:app/features/home/home_page.dart';
import 'package:app/services/storage_service.dart';


class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with TickerProviderStateMixin {
  bool _isLoading = false;
  String? _error;

  // Content animation
  late AnimationController _contentController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Wave animation (rises up on enter, goes down on exit)
  late AnimationController _waveController;
  late Animation<double> _waveHeightAnimation;

  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();

    // Content animation
    _contentController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    // Wave animation: starts LOW (0.48) and rises UP (0.55)
    _waveController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _waveHeightAnimation = Tween<double>(
      begin: 0.48, // Start at same height as get_started
      end: 0.55,   // Rise up slightly higher
    ).animate(
      CurvedAnimation(
        parent: _waveController,
        curve: Curves.easeOutCubic,
      ),
    );

    // Start animations on enter
    Future.delayed(const Duration(milliseconds: 50), () {
      if (mounted) {
        _waveController.forward();
        _contentController.forward();
      }
    });
  }

  @override
  void dispose() {
    _contentController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  void _goBack() async {
    // Fade out content first
    _contentController.reverse();
    
    // Wave goes back down
    await _waveController.reverse();
    
    if (mounted) {
      Navigator.pop(context);
    }
  }

    Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await _authService.signInWithGoogle();

      if (result == null) {
        setState(() => _isLoading = false);
        return;
      }

      // Save user to SQLite
      await StorageService().saveUserProfile(
        email: result.email,
        displayName: result.displayName,
        photoUrl: result.photoUrl,
      );

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => HomeScreen(
              accessToken: result.accessToken,
              userEmail: result.email,
              userDisplayName: result.displayName,
              userPhotoUrl: result.photoUrl,
            ),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
                  const SizedBox(height: 20),

                  // Back Button
                  SlideTransition(
                    position: _slideAnimation,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: GestureDetector(
                        onTap: _goBack,
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.primaryBlue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: AppColors.primaryBlue,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Animated Content
                  SlideTransition(
                    position: _slideAnimation,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title
                          const Text(
                            'Let\'s get',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 40,
                              fontWeight: FontWeight.w800,
                              height: 1.1,
                              letterSpacing: -1.5,
                            ),
                          ),
                          Row(
                            children: [
                              const Text(
                                'you ',
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 40,
                                  fontWeight: FontWeight.w800,
                                  height: 1.1,
                                  letterSpacing: -1.5,
                                ),
                              ),
                              Text(
                                'connected.',
                                style: TextStyle(
                                  color: AppColors.accentYellow,
                                  fontSize: 40,
                                  fontWeight: FontWeight.w800,
                                  height: 1.1,
                                  letterSpacing: -1.5,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // Description
                          Text(
                            'Connect your Gmail to let Inboxie work its magic. We only read, never send without your permission.',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 15,
                              height: 1.6,
                              fontWeight: FontWeight.w500,
                            ),
                          ),

                          // Error Message
                          if (_error != null) ...[
                            const SizedBox(height: 20),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.error_outline,
                                    color: Colors.red,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      _error!,
                                      style: const TextStyle(
                                        color: Colors.red,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ============ ANIMATED BOTTOM WAVES ============
          AnimatedBuilder(
            animation: _waveController,
            builder: (context, child) {
              return Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: SizedBox(
                  height: size.height * _waveHeightAnimation.value,
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
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 32),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    // Google Sign In Button
                                    SlideTransition(
                                      position: _slideAnimation,
                                      child: FadeTransition(
                                        opacity: _fadeAnimation,
                                        child: SizedBox(
                                          width: double.infinity,
                                          height: 56,
                                          child: ElevatedButton(
                                            onPressed: _isLoading
                                                ? null
                                                : _signInWithGoogle,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  AppColors.textLight,
                                              foregroundColor:
                                                  AppColors.primaryBlue,
                                              disabledBackgroundColor:
                                                  AppColors.textLight
                                                      .withValues(alpha: 0.7),
                                              elevation: 0,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                              ),
                                            ),
                                            child: _isLoading
                                                ? const SizedBox(
                                                    width: 24,
                                                    height: 24,
                                                    child:
                                                        CircularProgressIndicator(
                                                      strokeWidth: 2.5,
                                                      color:
                                                          AppColors.primaryBlue,
                                                    ),
                                                  )
                                                : Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      // Google Icon
                                                      Container(
                                                        width: 28,
                                                        height: 28,
                                                        decoration:
                                                            BoxDecoration(
                                                          color: AppColors
                                                              .primaryBlue,
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(6),
                                                        ),
                                                        child: const Center(
                                                          child: Text(
                                                            'G',
                                                            style: TextStyle(
                                                              color: AppColors
                                                                  .textLight,
                                                              fontSize: 16,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w800,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 12),
                                                      const Text(
                                                        'Connect with Gmail',
                                                        style: TextStyle(
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                          ),
                                        ),
                                      ),
                                    ),

                                    const SizedBox(height: 16),

                                    // Privacy Text
                                    FadeTransition(
                                      opacity: _fadeAnimation,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.lock_outline_rounded,
                                            color: AppColors.textLight
                                                .withValues(alpha: 0.8),
                                            size: 16,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Privacy focused. Secure connection.',
                                            style: TextStyle(
                                              color: AppColors.textLight
                                                  .withValues(alpha: 0.8),
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
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
              );
            },
          ),
        ],
      ),
    );
  }
}