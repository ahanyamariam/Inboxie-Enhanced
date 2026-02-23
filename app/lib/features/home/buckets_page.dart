import 'package:flutter/material.dart';
import 'package:app/core/theme/app_colors.dart';
import 'package:app/models/email_model.dart';
import 'package:app/models/bucket_model.dart';
import 'package:app/features/home/widgets/bucket_card.dart';
import 'package:app/features/home/widgets/recent_email_item.dart';
import 'package:app/features/home/widgets/bottom_nav.dart';
import 'package:app/features/profile/screens/profile_screen.dart';
import 'package:app/services/storage_service.dart';

class BucketsPage extends StatefulWidget {
  final String accessToken;
  final String userEmail;
  final String? userDisplayName; // ADD
  final String? userPhotoUrl; // ADD

  const BucketsPage({
    super.key,
    required this.accessToken,
    required this.userEmail,
    this.userDisplayName, // ADD
    this.userPhotoUrl, // ADD
  });

  @override
  State<BucketsPage> createState() => _BucketsPageState();
}

class _BucketsPageState extends State<BucketsPage> {
  final StorageService _storage = StorageService();
  bool _isLoading = true;
  String? _error;
  List<EmailModel> _emails = [];
  final TextEditingController _searchController = TextEditingController();

  // Live bucket data
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
      _error = null;
    });

    try {
      // Load bucket counts from DB
      final counts = await _storage.getBucketCounts();

      _buckets = [
        BucketModel(
          type: BucketType.reply,
          title: 'Reply',
          subtitle: 'PRIORITY',
          count: counts['needs_reply'] ?? 0,
          icon: Icons.reply_rounded,
        ),
        BucketModel(
          type: BucketType.waiting,
          title: 'Waiting',
          subtitle: 'PENDING',
          count: counts['waiting'] ?? 0,
          icon: Icons.schedule_rounded,
        ),
        BucketModel(
          type: BucketType.finance,
          title: 'Finance',
          subtitle: 'RECEIPTS',
          count: counts['bills'] ?? 0,
          icon: Icons.receipt_long_rounded,
        ),
        BucketModel(
          type: BucketType.updates,
          title: 'Updates',
          subtitle: 'LOW VALUE',
          count: counts['low_value'] ?? 0,
          icon: Icons.campaign_rounded,
        ),
      ];

      // Load recent emails from DB
      final rawEmails = await _storage.getAllEmails();
      setState(() {
        _emails = rawEmails.map(_dbToEmailModel).toList();
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
        });
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  EmailModel _dbToEmailModel(Map<String, dynamic> data) {
    final senderName = data['senderName'] ?? 'Unknown Sender';
    final senderInitials = _getInitials(senderName);

    // Map priority label
    Priority priority;
    final label = data['priorityLabel'] as String? ?? 'low';
    final int score = data['priorityScore'] ?? 0;
    switch (label) {
      case 'urgent': priority = Priority.urgent; break;
      case 'important': priority = Priority.important; break;
      case 'normal': priority = Priority.action; break;
      default:
        if (score >= 50) priority = Priority.urgent;
        else if (score >= 25) priority = Priority.important;
        else if (score >= 10) priority = Priority.action;
        else priority = Priority.low;
    }

    // Map bucket to action type
    ActionType type = ActionType.none;
    switch (data['bucket']) {
      case 'needs_reply': type = ActionType.directQuestion; break;
      case 'bills': type = ActionType.billing; break;
      case 'waiting': type = ActionType.waitingReply; break;
      case 'calendar': type = ActionType.deadline; break;
    }

    final avatarColors = [
      AppColors.primaryBlue,
      const Color(0xFFF2CB04),
      const Color(0xFF1565C0),
      const Color(0xFF0D47A1),
    ];

    return EmailModel(
      id: data['id'] ?? '',
      threadId: data['threadId'] ?? '',
      senderName: senderName,
      senderInitials: senderInitials,
      subject: data['subject'] ?? '(No Subject)',
      preview: data['snippet'] ?? '',
      timestamp: DateTime.fromMillisecondsSinceEpoch(data['timestamp'] ?? 0),
      priority: priority,
      actionType: type,
      isRead: (data['isRead'] ?? 0) == 1,
      avatarColor: avatarColors[(data['id'] ?? '').hashCode.abs() % avatarColors.length],
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return 'U';
    final parts = name.trim().split(' ');
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
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

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Compose new email')));
        },
        backgroundColor: AppColors.primaryBlue,
        child: const Icon(
          Icons.add_rounded,
          color: AppColors.accentYellow,
          size: 32,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomNav(
        currentIndex: 1, // Buckets page is index 1
        onTap: _onBottomNavTap, // UPDATED
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
                          // Navigate to Profile
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
                              // Buckets Grid
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
                                      onTap: () {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Open ${_buckets[index].title} bucket',
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                ),
                              ),

                              const SizedBox(height: 32),

                              // Recent Section Header
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Recent',
                                      style: TextStyle(
                                        color: AppColors.getTextPrimary(
                                          context,
                                        ),
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        // TODO: View all recent
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.getCard(context),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          border: Border.all(
                                            color: AppColors.getDivider(
                                              context,
                                            ),
                                            width: 1,
                                          ),
                                        ),
                                        child: Text(
                                          'VIEW ALL',
                                          style: TextStyle(
                                            color: AppColors.getTextMuted(
                                              context,
                                            ),
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 1.5,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 16),

                              // Recent Emails List
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                ),
                                child: _emails.isEmpty
                                    ? Center(
                                        child: Padding(
                                          padding: const EdgeInsets.all(32),
                                          child: Text(
                                            'No recent emails',
                                            style: TextStyle(
                                              color: AppColors.getTextSecondary(
                                                context,
                                              ),
                                              fontSize: 15,
                                            ),
                                          ),
                                        ),
                                      )
                                    : ListView.builder(
                                        shrinkWrap: true,
                                        physics:
                                            const NeverScrollableScrollPhysics(),
                                        itemCount: _emails.take(5).length,
                                        itemBuilder: (context, index) {
                                          return RecentEmailItem(
                                            email: _emails[index],
                                            onTap: () {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    'Open: ${_emails[index].subject}',
                                                  ),
                                                ),
                                              );
                                            },
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
