import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:app/core/theme/app_colors.dart';
import 'package:app/home/models/email_model.dart';
import 'package:app/home/models/bucket_model.dart';
import 'package:app/home/widgets/bucket_card.dart';
import 'package:app/home/widgets/recent_email_item.dart';
import 'package:app/home/widgets/bottom_nav.dart';

class BucketsPage extends StatefulWidget {
  final String accessToken;
  final String userEmail;

  const BucketsPage({
    Key? key,
    required this.accessToken,
    required this.userEmail,
  }) : super(key: key);

  @override
  State<BucketsPage> createState() => _BucketsPageState();
}

class _BucketsPageState extends State<BucketsPage> {
  bool _isLoading = true;
  String? _error;
  List<EmailModel> _emails = [];
  final TextEditingController _searchController = TextEditingController();

  // Bucket data
  final List<BucketModel> _buckets = [
    BucketModel(
      type: BucketType.reply,
      title: 'Reply',
      subtitle: 'PRIORITY',
      count: 12,
      icon: Icons.reply_rounded,
    ),
    BucketModel(
      type: BucketType.waiting,
      title: 'Waiting',
      subtitle: 'PENDING',
      count: 5,
      icon: Icons.schedule_rounded,
    ),
    BucketModel(
      type: BucketType.finance,
      title: 'Finance',
      subtitle: 'RECEIPTS',
      count: 8,
      icon: Icons.receipt_long_rounded,
    ),
    BucketModel(
      type: BucketType.updates,
      title: 'Updates',
      subtitle: 'NEWSLETTER',
      count: 42,
      icon: Icons.campaign_rounded,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _fetchEmails();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchEmails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final messagesResponse = await http.get(
        Uri.parse('https://gmail.googleapis.com/gmail/v1/users/me/messages?maxResults=10'),
        headers: {
          'Authorization': 'Bearer ${widget.accessToken}',
        },
      );

      if (messagesResponse.statusCode != 200) {
        throw Exception('Failed to fetch messages');
      }

      final messagesData = json.decode(messagesResponse.body);
      final messages = messagesData['messages'] ?? [];

      List<EmailModel> emailList = [];

      for (var message in messages) {
        final messageId = message['id'];
        final threadId = message['threadId'];
        final messageDetailResponse = await http.get(
          Uri.parse('https://gmail.googleapis.com/gmail/v1/users/me/messages/$messageId?format=metadata&metadataHeaders=Subject&metadataHeaders=From'),
          headers: {
            'Authorization': 'Bearer ${widget.accessToken}',
          },
        );

        if (messageDetailResponse.statusCode == 200) {
          final detailData = json.decode(messageDetailResponse.body);
          final headers = detailData['payload']['headers'] as List<dynamic>;

          String subject = '';
          String from = '';

          for (var header in headers) {
            if (header['name'] == 'Subject') subject = header['value'];
            if (header['name'] == 'From') from = header['value'];
          }

          emailList.add(_convertToEmailModel(messageId, threadId, subject, from, emailList.length));
        }
      }

      setState(() {
        _emails = emailList;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  EmailModel _convertToEmailModel(String id, String threadId, String subject, String from, int index) {
    final senderName = from.contains('<') ? from.split('<')[0].trim() : from;
    final senderInitials = _getInitials(senderName);

    final priorities = [Priority.urgent, Priority.important, Priority.low, Priority.action];
    final actionTypes = [ActionType.directQuestion, ActionType.deadline, ActionType.waitingReply, ActionType.billing, ActionType.none];
    final avatarColors = [AppColors.primaryBlue, const Color(0xFFF2CB04), const Color(0xFF1565C0), const Color(0xFF0D47A1)];

    return EmailModel(
      id: id,
      threadId: threadId,
      senderName: senderName.isEmpty ? 'Unknown Sender' : senderName,
      senderInitials: senderInitials,
      subject: subject.isEmpty ? '(No Subject)' : subject,
      preview: 'This is a preview of the email content...',
      timestamp: DateTime.now().subtract(Duration(hours: index * 2)),
      priority: priorities[index % priorities.length],
      actionType: index < 3 ? actionTypes[index % actionTypes.length] : ActionType.none,
      isRead: index % 3 == 0,
      avatarColor: avatarColors[index % avatarColors.length],
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return 'U';
    final parts = name.trim().split(' ');
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Compose new email')),
          );
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
  onTap: (index) {
    if (index == 0) {
      // Navigate back to Home/Inbox
      Navigator.pop(context);
    } else if (index == 2) {
      // TODO: Navigate to Settings
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings page coming soon')),
      );
    } else if (index == 3) {
      // TODO: Navigate to Profile
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile page coming soon')),
      );
    }
  },
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
              painter: WaveAccentPainter(),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: CustomPaint(
              size: Size(MediaQuery.of(context).size.width, 280),
              painter: WaveHeaderPainter(),
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
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
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

                      // Settings
                      GestureDetector(
                        onTap: () {
                          // TODO: Open settings
                        },
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.1),
                          ),
                          child: const Icon(
                            Icons.settings_rounded,
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
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFF1F5F9),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryBlue.withOpacity(0.1),
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
                            decoration: const InputDecoration(
                              hintText: 'Search your emails...',
                              hintStyle: TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                              border: InputBorder.none,
                            ),
                            style: const TextStyle(
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
                                padding: const EdgeInsets.symmetric(horizontal: 24),
                                child: GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
                                        // TODO: Navigate to bucket detail
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Open ${_buckets[index].title} bucket'),
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
                                padding: const EdgeInsets.symmetric(horizontal: 24),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Recent',
                                      style: TextStyle(
                                        color: AppColors.primaryBlue,
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
                                          color: const Color(0xFFF8FAFC),
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(
                                            color: const Color(0xFFF1F5F9),
                                            width: 1,
                                          ),
                                        ),
                                        child: const Text(
                                          'VIEW ALL',
                                          style: TextStyle(
                                            color: Color(0xFF64748BAD),
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
                                padding: const EdgeInsets.symmetric(horizontal: 24),
                                child: _emails.isEmpty
                                    ? const Center(
                                        child: Padding(
                                          padding: EdgeInsets.all(32),
                                          child: Text(
                                            'No recent emails',
                                            style: TextStyle(
                                              color: AppColors.textSecondary,
                                              fontSize: 15,
                                            ),
                                          ),
                                        ),
                                      )
                                    : ListView.builder(
                                        shrinkWrap: true,
                                        physics: const NeverScrollableScrollPhysics(),
                                        itemCount: _emails.take(5).length,
                                        itemBuilder: (context, index) {
                                          return RecentEmailItem(
                                            email: _emails[index],
                                            onTap: () {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text('Open: ${_emails[index].subject}'),
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

// Wave Painters
class WaveHeaderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Color(0xFF083E84),
          Color(0xFF0a4da3),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path();
    path.lineTo(0, size.height);
    path.quadraticBezierTo(size.width * 0.25, size.height * 0.9, size.width * 0.5, size.height * 0.95);
    path.quadraticBezierTo(size.width * 0.75, size.height, size.width, size.height * 0.9);
    path.lineTo(size.width, 0);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class WaveAccentPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFF2CB04).withOpacity(0.2);

    final path = Path();
    path.lineTo(0, size.height * 0.7);
    path.quadraticBezierTo(size.width * 0.25, size.height * 0.6, size.width * 0.5, size.height * 0.65);
    path.quadraticBezierTo(size.width * 0.75, size.height * 0.7, size.width, size.height * 0.6);
    path.lineTo(size.width, 0);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}