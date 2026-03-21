import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:app/core/theme/app_colors.dart';

class ProfileHeader extends StatelessWidget {
  final String? displayName;
  final String? email;
  final String? photoUrl;
  final bool isConnected;

  const ProfileHeader({
    super.key,
    this.displayName,
    this.email,
    this.photoUrl,
    this.isConnected = true,
  });

  String get _initials {
    if (displayName == null || displayName!.isEmpty) return 'U';
    final parts = displayName!.trim().split(' ');
    if (parts.length == 1) {
      return parts[0][0].toUpperCase();
    }
    return '${parts[0][0]}${parts.last[0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    // We use a fixed height for the header to allow the ribbon to flow nicely
    return SizedBox(
      height: 320,
      child: Stack(
        children: [
          // 1. Background
          Container(color: Colors.white),

          // 2. Yellow Retro Ribbon (Top Left)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SizedBox(
              height: 300,
              child: ClipPath(
                clipper: _HeaderRibbonClipper(offset: 0, thickness: 80),
                child: Container(
                  color: AppColors.waveYellowLight.withValues(alpha: 0.4),
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SizedBox(
              height: 300,
              child: ClipPath(
                clipper: _HeaderRibbonClipper(offset: 30, thickness: 80),
                child: Container(
                  color: AppColors.waveYellowMedium.withValues(alpha: 0.6),
                ),
              ),
            ),
          ),

          // 3. Content
          Align(
            alignment: Alignment.center,
            child: SafeArea(
              bottom: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 10),
                  // Avatar with Border
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFE0E0E0),
                        width: 3,
                      ),
                      color: Colors.white,
                    ),
                    child: ClipOval(
                      child: photoUrl != null && photoUrl!.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: photoUrl!,
                              fit: BoxFit.cover,
                              placeholder: (context, url) =>
                                  _buildInitialsAvatar(),
                              errorWidget: (context, url, error) =>
                                  _buildInitialsAvatar(),
                            )
                          : _buildInitialsAvatar(),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Name
                  Text(
                    displayName ?? 'User',
                    style: const TextStyle(
                      color: Color(0xFF1A1A2E),
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),

                  const SizedBox(height: 4),

                  // Email
                  Text(
                    email ?? 'No email',
                    style: const TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Connection Status Pill
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isConnected
                            ? AppColors.success
                            : AppColors.error,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isConnected
                              ? Icons.check_circle_rounded
                              : Icons.error_rounded,
                          size: 14,
                          color: isConnected
                              ? AppColors.success
                              : AppColors.error,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isConnected ? 'Gmail Connected' : 'Disconnected',
                          style: TextStyle(
                            color: isConnected
                                ? AppColors.success
                                : AppColors.error,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
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

  Widget _buildInitialsAvatar() {
    return Container(
      color: const Color(0xFFF5F5F5),
      child: Center(
        child: Text(
          _initials,
          style: const TextStyle(
            color: Color(0xFF1A1A2E),
            fontSize: 36,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

// Local Clipper to ensure it works without import errors
// Matches the "Squiggle" theme but adapted slightly for a header height
class _HeaderRibbonClipper extends CustomClipper<Path> {
  final double offset;
  final double thickness;

  _HeaderRibbonClipper({this.offset = 0, this.thickness = 80});

  @override
  Path getClip(Size size) {
    var path = Path();
    // Start top left
    path.moveTo(0, size.height * 0.4 - offset);

    // Squiggle across to top right
    path.cubicTo(
      size.width * 0.3,
      size.height * 0.8, // Dip down
      size.width * 0.6,
      -50, // Go high up
      size.width,
      size.height * 0.2, // End point
    );

    // Thickness
    path.lineTo(size.width, size.height * 0.2 - thickness);

    // Return path
    path.cubicTo(
      size.width * 0.6,
      -50 - thickness,
      size.width * 0.3,
      size.height * 0.8 - thickness,
      0,
      size.height * 0.4 - offset - thickness,
    );

    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
