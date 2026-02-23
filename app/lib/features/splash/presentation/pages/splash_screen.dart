import 'package:flutter/material.dart';
import 'package:app/core/theme/app_colors.dart';
import 'package:app/features/splash/presentation/widgets/wave_clippers.dart';
import 'package:app/features/onboarding/get_started_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  
  late AnimationController _logoController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  
  late AnimationController _waveController;
  late Animation<double> _waveSlideAnimation;

  
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );

    
    _waveController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _waveSlideAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _waveController,
        curve: Curves.easeOutCubic,
      ),
    );

   
    _startAnimationSequence();
  }

  void _startAnimationSequence() async {
    
    _logoController.forward();

   
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    
    setState(() => _isLoading = false);
    _waveController.forward();

   
    await Future.delayed(const Duration(milliseconds: 1200));

    if (mounted) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, _, __) => const GetStartedScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Stack(
        children: [
         
          Center(
            child: AnimatedBuilder(
              animation: _logoController,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeAnimation.value,
                  child: Transform.scale(
                    scale: _scaleAnimation.value,
                    child: child,
                  ),
                );
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryBlue.withValues(alpha: 0.25),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.mail_outline_rounded,
                      color: AppColors.textLight,
                      size: 50,
                    ),
                  ),

                  const SizedBox(height: 30),

                  
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Inb',
                        style: TextStyle(
                          color: AppColors.primaryBlue,
                          fontSize: 42,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.0,
                        ),
                      ),
                      Container(
                        width: 30,
                        height: 30,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.primaryBlue,
                            width: 3.5,
                          ),
                        ),
                        child: Center(
                          child: Container(
                            width: 10,
                            height: 10,
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
                          fontSize: 42,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 50),

                 
                  AnimatedOpacity(
                    opacity: _isLoading ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    child: SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.accentYellow,
                        ),
                        backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.1),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          
          AnimatedBuilder(
            animation: _waveController,
            builder: (context, child) {
              return Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                
                child: Transform.translate(
                  offset: Offset(0, size.height * 0.5 * _waveSlideAnimation.value),
                  child: child,
                ),
              );
            },
            child: SizedBox(
              height: size.height * 0.5,
              child: Stack(
                children: [
                 
                  Positioned.fill(
                    child: ClipPath(
                      clipper: BottomYellowWaveClipper(),
                      child: Container(
                        color: AppColors.accentYellow,
                      ),
                    ),
                  ),
                  
                  Positioned.fill(
                    child: ClipPath(
                      clipper: BottomBlueWaveClipper(),
                      child: Container(
                        color: AppColors.primaryBlue,
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