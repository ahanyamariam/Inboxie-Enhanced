import 'package:flutter/material.dart';
import 'package:app/core/theme/app_colors.dart';
import 'package:app/models/bucket_model.dart';
import 'package:app/models/bucket_config_model.dart';
import 'package:app/features/home/widgets/bucket_card.dart';
import 'package:app/features/home/widgets/bottom_nav.dart';
import 'package:app/features/home/bucket_detail_page.dart';
import 'package:app/features/profile/screens/profile_screen.dart';
import 'package:app/features/profile/screens/bucket_customization_screen.dart';
import 'package:app/services/storage_service.dart';

class BucketsPage extends StatefulWidget {
  final String accessToken;
  final String userEmail;
  final String? userDisplayName;
  final String? userPhotoUrl;

  const BucketsPage({
    super.key,
    required this.accessToken,
    required this.userEmail,
    this.userDisplayName,
    this.userPhotoUrl,
  });

  @override
  State<BucketsPage> createState() => _BucketsPageState();
}

class _BucketsPageState extends State<BucketsPage> {
  final StorageService _storage = StorageService();
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  // Live bucket data — now dynamic from config
  List<BucketModel> _buckets = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load bucket config + counts from DB
      final config = _storage.getBucketConfig();
      final counts = await _storage.getBucketCounts();

      _buckets = config.visibleBuckets.map((item) {
        return BucketModel(
          type: _bucketTypeFromId(item.id),
          title: item.name,
          subtitle: _subtitleForBucket(item.id),
          count: counts[item.id] ?? 0,
          icon: BucketIcons.getIcon(item.icon),
        );
      }).toList();
    } catch (e) {
      if (mounted) {
        // Log error silently for now since _error is unused in UI
        print('Error loading buckets: $e');
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  BucketType _bucketTypeFromId(String id) {
    switch (id) {
      case 'important': return BucketType.important;
      case 'needs_reply': return BucketType.reply;
      case 'transactions': return BucketType.transactions;
      case 'events': return BucketType.events;
      case 'promotions': return BucketType.promotions;
      case 'updates': return BucketType.updates;
      case 'handled': return BucketType.handled;
      case 'inbox': return BucketType.inbox;
      default: return BucketType.inbox;
    }
  }

  String _subtitleForBucket(String id) {
    switch (id) {
      case 'important': return 'URGENT';
      case 'needs_reply': return 'ACTION';
      case 'transactions': return 'FINANCE';
      case 'events': return 'CALENDAR';
      case 'promotions': return 'DEALS';
      case 'updates': return 'INFO';
      case 'handled': return 'COMPLETED';
      case 'inbox': return 'GENERAL';
      default: return '';
    }
  }

  String _bucketIdFromType(BucketType type) {
    switch (type) {
      case BucketType.important: return 'important';
      case BucketType.reply: return 'needs_reply';
      case BucketType.transactions: return 'transactions';
      case BucketType.events: return 'events';
      case BucketType.promotions: return 'promotions';
      case BucketType.updates: return 'updates';
      case BucketType.handled: return 'handled';
      case BucketType.inbox: return 'inbox';
    }
  }



  // ============ NAVIGATION ============
  void _onBottomNavTap(int index) {
    switch (index) {
      case 0:
        // Go back to Home
        Navigator.pop(context);
        break;
      case 1:
        // Already on Buckets - do nothing
        break;
      case 2:
        // Navigate to Profile
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ProfileScreen(
              displayName:
                  widget.userDisplayName ?? widget.userEmail.split('@').first,
              email: widget.userEmail,
              photoUrl: widget.userPhotoUrl,
              accessToken: widget.accessToken,
            ),
          ),
        );
        break;
    }
  }

  void _showCustomization() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const BucketCustomizationScreen(),
      ),
    ).then((_) {
      _loadData();
    });
  }

  void _openBucket(BucketModel bucket) {
    final bucketId = _bucketIdFromType(bucket.type);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BucketDetailPage(
          bucketId: bucketId,
          bucketName: bucket.title,
          bucketIcon: bucket.icon,
          accessToken: widget.accessToken,
          userEmail: widget.userEmail,
        ),
      ),
    ).then((_) => _loadData()); // Refresh on return
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCustomization,
        backgroundColor: AppColors.primaryBlue,
        shape: const CircleBorder(),
        child: const Icon(
          Icons.tune_rounded,
          color: AppColors.accentYellow,
          size: 28,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: BottomNav(
        currentIndex: 1, // Buckets page is index 1
        onTap: _onBottomNavTap,
      ),
      body: Stack(
        children: [
          // Wave decorations
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: CustomPaint(
              size: Size(MediaQuery.of(context).size.width, 320),
              painter: WaveAccentPainter(
                color: AppColors.accentYellow.withValues(alpha: isDark ? 0.1 : 0.2),
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: CustomPaint(
              size: Size(MediaQuery.of(context).size.width, 280),
              painter: WaveHeaderPainter(isDark: isDark),
            ),
          ),

          // Content
          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Profile Avatar
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProfileScreen(
                                displayName:
                                    widget.userDisplayName ??
                                    widget.userEmail.split('@').first,
                                email: widget.userEmail,
                                photoUrl: widget.userPhotoUrl,
                                accessToken: widget.accessToken,
                              ),
                            ),
                          );
                        },
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                              width: 2,
                            ),
                            gradient: const LinearGradient(
                              colors: [
                                AppColors.accentYellow,
                                AppColors.waveYellowDark,
                              ],
                            ),
                          ),
                          child: const Icon(
                            Icons.person_rounded,
                            color: AppColors.primaryBlue,
                            size: 22,
                          ),
                        ),
                      ),

                      // Title
                      const Text(
                        'Buckets',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),

                      // Back to Home
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                          child: const Icon(
                            Icons.home_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Search Bar
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.getSurface(context),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.getDivider(context),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryBlue.withValues(alpha: 0.1),
                          blurRadius: 30,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(left: 20, right: 12),
                          child: Icon(
                            Icons.search_rounded,
                            color: AppColors.primaryBlue,
                            size: 22,
                          ),
                        ),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Search your emails...',
                              hintStyle: TextStyle(
                                color: AppColors.getTextMuted(context),
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                              border: InputBorder.none,
                            ),
                            style: TextStyle(
                              color: AppColors.getTextPrimary(context),
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Scrollable content
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primaryBlue,
                          ),
                        )
                      : SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Buckets Grid — now dynamic
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                ),
                                child: GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 2,
                                        crossAxisSpacing: 16,
                                        mainAxisSpacing: 16,
                                        childAspectRatio: 0.95,
                                      ),
                                  itemCount: _buckets.length,
                                  itemBuilder: (context, index) {
                                    return BucketCard(
                                      bucket: _buckets[index],
                                      onTap: () => _openBucket(_buckets[index]),
                                    );
                                  },
                                ),
                              ),


                              const SizedBox(height: 100),
                            ],
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Wave Painters (unchanged)
class WaveHeaderPainter extends CustomPainter {
  final bool isDark;

  WaveHeaderPainter({this.isDark = false});

  @override
  void paint(Canvas canvas, Size size) {
    final colors = isDark
        ? [const Color(0xFF062E62), const Color(0xFF083E84)]
        : [const Color(0xFF083E84), const Color(0xFF0a4da3)];

    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: colors,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path();
    path.lineTo(0, size.height);
    path.quadraticBezierTo(
      size.width * 0.25,
      size.height * 0.9,
      size.width * 0.5,
      size.height * 0.95,
    );
    path.quadraticBezierTo(
      size.width * 0.75,
      size.height,
      size.width,
      size.height * 0.9,
    );
    path.lineTo(size.width, 0);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class WaveAccentPainter extends CustomPainter {
  final Color color;

  WaveAccentPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;

    final path = Path();
    path.lineTo(0, size.height * 0.7);
    path.quadraticBezierTo(
      size.width * 0.25,
      size.height * 0.6,
      size.width * 0.5,
      size.height * 0.65,
    );
    path.quadraticBezierTo(
      size.width * 0.75,
      size.height * 0.7,
      size.width,
      size.height * 0.6,
    );
    path.lineTo(size.width, 0);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
