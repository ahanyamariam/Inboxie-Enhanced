import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:app/core/theme/app_colors.dart';
import 'package:app/home/models/email_model.dart';
import 'package:app/home/widgets/header_banner.dart';
import 'package:app/home/widgets/action_card.dart';
import 'package:app/home/widgets/inbox_list_item.dart';
import 'package:app/home/widgets/bottom_nav.dart';
import 'package:app/home/buckets_page.dart';
import 'package:app/home/screens/email_details_screen.dart';


class HomeScreen extends StatefulWidget {
  final String accessToken;
  final String userEmail;

  const HomeScreen({
    Key? key,
    required this.accessToken,
    required this.userEmail,
  }) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = true;
  String? _error;
  List<EmailModel> _emails = [];
  
  // UI State
  int _selectedTabIndex = 1; // Default to "Action" tab
  int _bottomNavIndex = 0; // Default to "Home"
  int _maxResults = 10; // Email count selector

  @override
  void initState() {
    super.initState();
    _fetchEmails();
  }

  // Update _fetchEmails to pass threadId:
Future<void> _fetchEmails() async {
  setState(() {
    _isLoading = true;
    _error = null;
  });

  try {
    final messagesResponse = await http.get(
      Uri.parse('https://gmail.googleapis.com/gmail/v1/users/me/messages?maxResults=$_maxResults'),
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
      final threadId = message['threadId'];  // ← GET THREAD ID
      
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

        emailList.add(_convertToEmailModel(
          messageId, 
          threadId,  // ← PASS THREAD ID
          subject, 
          from, 
          emailList.length
        ));
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



  // Helper method to convert Gmail data to EmailModel
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
      preview: 'This is a preview of the email content...', // You can fetch snippet from API if needed
      timestamp: DateTime.now().subtract(Duration(hours: index * 2)), // Mock timestamp
      priority: priorities[index % priorities.length],
      actionType: index < 3 ? actionTypes[index % actionTypes.length] : ActionType.none,
      isRead: index % 3 == 0, // Some emails are read
      avatarColor: avatarColors[index % avatarColors.length],
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return 'U';
    final parts = name.trim().split(' ');
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }

  List<EmailModel> get _actionEmails {
    return _emails.where((email) => email.actionType != ActionType.none).toList();
  }

  List<EmailModel> get _filteredEmails {
    switch (_selectedTabIndex) {
      case 0: // All
        return _emails;
      case 1: // Action
        return _emails.where((e) => e.actionType != ActionType.none).toList();
      case 2: // Urgent
        return _emails.where((e) => e.priority == Priority.urgent).toList();
      case 3: // Important
        return _emails.where((e) => e.priority == Priority.important).toList();
      case 4: // Low
        return _emails.where((e) => e.priority == Priority.low).toList();
      default:
        return _emails;
    }
  }

  void _showEmailCountSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Number of emails to load',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 20),
              ...[10, 25, 50, 100].map((count) {
                return ListTile(
                  leading: Radio<int>(
                    value: count,
                    groupValue: _maxResults,
                    activeColor: AppColors.primaryBlue,
                    onChanged: (value) {
                      setState(() {
                        _maxResults = value!;
                      });
                      Navigator.pop(context);
                      _fetchEmails();
                    },
                  ),
                  title: Text(
                    '$count emails',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: _maxResults == count ? FontWeight.w600 : FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  onTap: () {
                    setState(() {
                      _maxResults = count;
                    });
                    Navigator.pop(context);
                    _fetchEmails();
                  },
                );
              }).toList(),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Implement compose functionality
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Compose new email')),
          );
        },
        backgroundColor: AppColors.primaryBlue,
        child: const Icon(
          Icons.edit_rounded,
          color: AppColors.accentYellow,
        ),
      ),
      bottomNavigationBar: BottomNav(
        currentIndex: _bottomNavIndex,
        onTap: (index) {
          setState(() {
            _bottomNavIndex = index;
          });
          
          // Navigate to Buckets page when index is 1
          if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BucketsPage(
                  accessToken: widget.accessToken,
                  userEmail: widget.userEmail,
                ),
              ),
            );
          } else if (index == 2) {
            // TODO: Navigate to Settings
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Settings coming soon')),
            );
          } else if (index == 3) {
            // TODO: Navigate to Profile
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Profile coming soon')),
            );
          }
        },
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryBlue))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      const Text(
                        'Error loading emails',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          _error!,
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _fetchEmails,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          foregroundColor: AppColors.textLight,
                        ),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Header Banner with Tabs
                    HeaderBanner(
                      selectedTabIndex: _selectedTabIndex,
                      onTabSelected: (index) {
                        setState(() {
                          _selectedTabIndex = index;
                        });
                      },
                      onSearchTap: () {
                        // TODO: Implement search
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Search functionality')),
                        );
                      },
                      onProfileTap: () {
                        // Show email count selector instead
                        _showEmailCountSelector();
                      },
                    ),

                    // Scrollable Content
                    Expanded(
                      child: _emails.isEmpty
                          ? const Center(
                              child: Text(
                                'No emails found',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 16,
                                ),
                              ),
                            )
                          : SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 24),

                                  // Email Count Indicator
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 20),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Showing ${_emails.length} emails',
                                          style: const TextStyle(
                                            color: AppColors.textSecondary,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: _showEmailCountSelector,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColors.primaryBlue.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  'Load: $_maxResults',
                                                  style: const TextStyle(
                                                    color: AppColors.primaryBlue,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                const SizedBox(width: 4),
                                                const Icon(
                                                  Icons.arrow_drop_down,
                                                  color: AppColors.primaryBlue,
                                                  size: 18,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  // Needs Action Section (only show if there are action emails)
                                  if (_actionEmails.isNotEmpty) ...[
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 20),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text(
                                            'Needs Action',
                                            style: TextStyle(
                                              color: AppColors.textPrimary,
                                              fontSize: 20,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          GestureDetector(
                                            onTap: () {
                                              // TODO: Navigate to all action items
                                            },
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 16,
                                                vertical: 8,
                                              ),
                                              decoration: BoxDecoration(
                                                color: AppColors.accentYellow,
                                                borderRadius: BorderRadius.circular(20),
                                              ),
                                              child: const Text(
                                                'See all',
                                                style: TextStyle(
                                                  color: AppColors.primaryBlue,
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 16),

                                    // Action Cards Carousel
                                    SizedBox(
                                      height: 180,
                                      child: ListView.builder(
                                        scrollDirection: Axis.horizontal,
                                        padding: const EdgeInsets.symmetric(horizontal: 20),
                                        itemCount: _actionEmails.length,
                                        itemBuilder: (context, index) {
                                          return ActionCard(
                                            email: _actionEmails[index],
                                            onTap: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) => EmailDetailScreen(
                                                    messageId: _actionEmails[index].id,
                                                    threadId: _actionEmails[index].threadId,
                                                    accessToken: widget.accessToken,
                                                    initialSubject: _actionEmails[index].subject,
                                                  ),
                                                ),
                                              ).then((changed) {
                                                if (changed == true) {
                                                  _fetchEmails();
                                                }
                                              });
                                            },
                                          );
                                        },
                                      ),
                                    ),
                                    const SizedBox(height: 32),
                                  ],

                                  // Recent Inbox Section
                                  const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 20),
                                    child: Text(
                                      'Recent Inbox',
                                      style: TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),

                                  // Inbox List
                                  ListView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: _filteredEmails.length,
                                    itemBuilder: (context, index) {
                                      return InboxListItem(
                                        email: _filteredEmails[index],
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => EmailDetailScreen(
                                                messageId: _filteredEmails[index].id,
                                                threadId: _filteredEmails[index].threadId,
                                                accessToken: widget.accessToken,
                                                initialSubject: _filteredEmails[index].subject,
                                              ),
                                            ),
                                          ).then((changed) {
                                            if (changed == true) {
                                              _fetchEmails();
                                            }
                                          });
                                        },
                                      );
                                    },
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