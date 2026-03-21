import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:app/core/theme/app_colors.dart';
import 'package:app/models/email_detail_model.dart';
import 'package:app/models/email_model.dart';
import 'package:app/features/home/widgets/email_body_view.dart';
import 'package:app/services/gmail_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

class ThreadMessageCard extends StatelessWidget {
  final EmailDetailModel message;
  final bool isExpanded;
  final bool isLatest;
  final VoidCallback onTap;
  final VoidCallback? onReply;
  final GmailService? gmailService;
  final String accessToken;

  const ThreadMessageCard({
    super.key,
    required this.message,
    required this.isExpanded,
    required this.isLatest,
    required this.onTap,
    this.onReply,
    this.gmailService,
    required this.accessToken,
  });

  Color get _avatarColor {
    final colors = [
      AppColors.primaryBlue,
      const Color(0xFFF2CB04),
      const Color(0xFF1565C0),
      const Color(0xFF00796B),
      const Color(0xFFC62828),
      const Color(0xFF6A1B9A),
      const Color(0xFF00838F),
    ];
    return colors[message.fromName.length % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    // Clean, minimal design - no card wrapper, just content
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sender info
          _buildHeader(),

          const SizedBox(height: 20),

          // Email body
          _buildBody(),

          // Only show attachments section if there are non-inline (downloadable) attachments
          if (message.attachments.any((a) => !a.isInline)) ...[
            const SizedBox(height: 20),
            _buildAttachments(),
          ],

          // Action chips for calendar, tracking, etc.
          if (message.actionType != ActionType.none) ...[
            const SizedBox(height: 20),
            _buildActionChips(),
          ],

          // Calendar invitation details if .ics attachment exists
          if (message.attachments.any((a) =>
              a.mimeType == 'text/calendar' ||
              a.mimeType == 'application/ics' ||
              a.filename.toLowerCase().endsWith('.ics'))) ...[
            const SizedBox(height: 12),
            _buildCalendarInvitationCard(),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Avatar
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: _avatarColor,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Center(
            child: Text(
              message.senderInitials,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),

        // Sender Info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      message.fromName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A2E),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    message.formattedDate,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF8F92A1),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              // Recipients inline
              if (message.to.isNotEmpty)
                Text(
                  'To: ${message.to.join(", ")}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF8F92A1),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 1,
      color: Colors.grey.withValues(alpha: 0.1),
    );
  }

  Widget _buildRecipients() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (message.to.isNotEmpty)
          _buildRecipientRow('To', message.to.join(', ')),
        if (message.cc.isNotEmpty)
          _buildRecipientRow('Cc', message.cc.join(', ')),
        _buildRecipientRow('Date', message.fullFormattedDate),
      ],
    );
  }

  Widget _buildRecipientRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 40,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return EmailBodyView(
      plainText: message.bodyPlain,
      htmlContent: message.bodyHtml,
      snippet: message.snippet,
      messageData: message.rawData,  
      accessToken: accessToken,

    );
  }

  Widget _buildAttachments() {
    // Filter out inline images - only show downloadable attachments
    final downloadableAttachments = message.attachments.where((a) => !a.isInline).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.attach_file_rounded,
              size: 16,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              'Attachments (${downloadableAttachments.length})',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: downloadableAttachments.map((attachment) {
            return Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.primaryBlue.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    attachment.icon,
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        attachment.filename.length > 20
                            ? '${attachment.filename.substring(0, 17)}...'
                            : attachment.filename,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        attachment.formattedSize,
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.download_rounded,
                    size: 16,
                    color: AppColors.primaryBlue,
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildQuickReply() {
    return GestureDetector(
      onTap: onReply,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Colors.grey.withValues(alpha: 0.15),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.reply_rounded,
              size: 18,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 10),
            Text(
              'Reply to this message...',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarInvitationCard() {
    // Extract date/time information for the invitation card
    final dateTimeInfo = _extractDateTime(
      message.bodyHtml.isNotEmpty ? message.bodyHtml : message.bodyPlain,
      message.subject,
    );

    // Get the .ics attachment
    final icsAttachment = message.attachments.firstWhere(
      (a) => a.mimeType == 'text/calendar' ||
             a.mimeType == 'application/ics' ||
             a.filename.toLowerCase().endsWith('.ics'),
    );

    return GestureDetector(
      onTap: () async {
        // Download and open the .ics file
        if (gmailService != null) {
          try {
            final attachmentData = await gmailService!.fetchAttachment(
              message.id,
              icsAttachment.id,
            );
            if (attachmentData != null) {
              // Gmail returns base64url encoded string - convert to standard base64
              final base64Str = attachmentData.replaceAll('-', '+').replaceAll('_', '/');

              // Decode and save to temp file
              final bytes = base64.decode(base64Str);
              final dir = await getTemporaryDirectory();
              final file = File('${dir.path}/${icsAttachment.filename}');
              await file.writeAsBytes(bytes);

              // Open with default calendar app
              final result = await OpenFilex.open(file.path);

              if (result.type != ResultType.done) {
                // Fallback: try to open with URL if file opening fails
                final url = Uri.file(file.path);
                await launchUrl(url, mode: LaunchMode.externalApplication);
              }
            }
          } catch (e) {
            // Silently fail or show error
            debugPrint('Failed to open calendar invitation: $e');
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: const Color(0xFFE0E0E0),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A2E).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.calendar_today_rounded,
                    size: 18,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Calendar Invitation',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A2E),
                        ),
                      ),
                      const SizedBox(height: 2),
                      if (dateTimeInfo['extractedText'] != null)
                        Text(
                          dateTimeInfo['extractedText'] as String,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF8F92A1),
                          ),
                        )
                      else
                        const Text(
                          'Tap to open invitation',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF8F92A1),
                          ),
                        ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: Color(0xFF8F92A1),
                ),
              ],
            ),
            if (dateTimeInfo['startDate'] != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.access_time_rounded,
                      size: 16,
                      color: Color(0xFF8F92A1),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatDateTimeForDisplay(dateTimeInfo['startDate'] as DateTime),
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDateTimeForDisplay(DateTime date) {
    // Format: "Thursday, March 20, 2026 at 10:00 AM"
    const weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];

    final weekday = weekdays[date.weekday - 1];
    final month = months[date.month - 1];
    final day = date.day;
    final year = date.year;

    var hour = date.hour;
    final minute = date.minute.toString().padLeft(2, '0');
    final ampm = hour >= 12 ? 'PM' : 'AM';
    if (hour > 12) hour -= 12;
    if (hour == 0) hour = 12;

    return '$weekday, $month $day, $year at $hour:$minute $ampm';
  }

  Widget _buildActionChips() {
    final List<Widget> chips = [];

    // Check for .ics calendar invitation attachment
    final calendarInvite = message.attachments.where(
      (a) => a.mimeType == 'text/calendar' ||
             a.mimeType == 'application/ics' ||
             a.filename.toLowerCase().endsWith('.ics'),
    );

    // 1. Meeting / Calendar Event
    if (message.actionType == ActionType.meeting) {
      // Extract date and time from email content
      final dateTimeInfo = _extractDateTime(
        message.bodyHtml.isNotEmpty ? message.bodyHtml : message.bodyPlain,
        message.subject,
      );

      chips.add(
        _ActionChip(
          icon: Icons.edit_calendar_rounded,
          label: calendarInvite.isNotEmpty ? 'Accept Invitation' : 'Add to Calendar',
          color: const Color(0xFF1A1A2E), // Match page - dark navy
          onTap: () async {
            final text = Uri.encodeComponent(message.subject);

            // Build detailed description
            final descriptionParts = [
              'From: ${message.fromName} (${message.fromEmail})',
            ];

            // Add extracted date/time info to description if available
            if (dateTimeInfo['extractedText'] != null) {
              descriptionParts.add('\n${dateTimeInfo['extractedText']}');
            }

            // Add email body snippet
            final bodySnippet = message.snippet.isNotEmpty
                ? message.snippet
                : message.bodyPlain.substring(0, message.bodyPlain.length > 200 ? 200 : message.bodyPlain.length);
            descriptionParts.add('\n\n$bodySnippet');

            final details = Uri.encodeComponent(descriptionParts.join('\n'));

            // Build Google Calendar URL with date/time if available
            var calendarUrl = 'https://calendar.google.com/calendar/render?action=TEMPLATE&text=$text&details=$details';

            if (dateTimeInfo['startDate'] != null) {
              final startDate = dateTimeInfo['startDate'] as DateTime;
              final endDate = dateTimeInfo['endDate'] as DateTime? ?? startDate.add(const Duration(hours: 1));

              // Format: 20250320T100000Z (ISO 8601 basic format)
              final startFormatted = _formatDateForCalendar(startDate);
              final endFormatted = _formatDateForCalendar(endDate);

              calendarUrl += '&dates=$startFormatted/$endFormatted';
            }

            final url = Uri.parse(calendarUrl);
            try {
              await launchUrl(url, mode: LaunchMode.externalApplication);
            } catch (e) {
              // Silently fail - user feedback should be from parent screen
            }
          },
        ),
      );
    }

    // 2. Shipping / Tracking
    if (message.actionType == ActionType.tracking) {
      chips.add(
        _ActionChip(
          icon: Icons.local_shipping_rounded,
          label: 'Track Package',
          color: const Color(0xFF1A1A2E), // Match page - dark navy
          onTap: () async {
            final trackingUrl = _extractUrl(
              message.bodyHtml.isNotEmpty ? message.bodyHtml : message.bodyPlain,
              ['track', 'shipping', 'delivery'],
            );
            if (trackingUrl != null) {
              try {
                await launchUrl(Uri.parse(trackingUrl), mode: LaunchMode.externalApplication);
              } catch (e) {
                // Silently fail
              }
            }
          },
        ),
      );
    }

    // 3. Travel / Flight
    if (message.actionType == ActionType.travel) {
      chips.add(
        _ActionChip(
          icon: Icons.flight_takeoff_rounded,
          label: 'Check In',
          color: const Color(0xFF1A1A2E), // Match page - dark navy
          onTap: () async {
            final travelUrl = _extractUrl(
              message.bodyHtml.isNotEmpty ? message.bodyHtml : message.bodyPlain,
              ['check-in', 'checkin', 'boarding', 'itinerary'],
            );
            if (travelUrl != null) {
              try {
                await launchUrl(Uri.parse(travelUrl), mode: LaunchMode.externalApplication);
              } catch (e) {
                // Silently fail
              }
            }
          },
        ),
      );
    }

    if (chips.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: chips,
    );
  }

  /// Extract date/time information from email content
  Map<String, dynamic> _extractDateTime(String content, String subject) {
    final result = <String, dynamic>{};

    // Remove HTML tags for easier parsing
    final cleanContent = content.replaceAll(RegExp(r'<[^>]*>'), ' ');
    final fullText = '$subject\n$cleanContent';

    // Common date/time patterns (ordered by specificity)
    final patterns = [
      // "Monday, March 20, 2026 at 10:00 AM" or "Mon, Mar 20 2026 10:00 AM"
      RegExp(
        r'(?:\w+,?\s+)?(\w+)\s+(\d{1,2}),?\s+(\d{4})\s+(?:at\s+)?(\d{1,2}):(\d{2})\s*([AP]M)',
        caseSensitive: false,
      ),
      // "20 March 2026, 10:00" or "20 Mar 2026 10:00"
      RegExp(
        r'(\d{1,2})\s+(\w+)\s+(\d{4})[,\s]+(\d{1,2}):(\d{2})',
        caseSensitive: false,
      ),
      // "2026-03-20T10:00:00" or "2026-03-20 10:00"
      RegExp(
        r'(\d{4})-(\d{2})-(\d{2})[T\s]+(\d{1,2}):(\d{2})',
      ),
      // "03/20/2026 at 10:00 AM" or "3/20/2026 10:00am"
      RegExp(
        r'(\d{1,2})/(\d{1,2})/(\d{4})\s+(?:at\s+)?(\d{1,2}):(\d{2})\s*([AP]M)?',
        caseSensitive: false,
      ),
      // "March 20 at 10:00 AM" (current or next year)
      RegExp(
        r'(\w+)\s+(\d{1,2})\s+(?:at\s+)?(\d{1,2}):(\d{2})\s*([AP]M)',
        caseSensitive: false,
      ),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(fullText);
      if (match != null) {
        try {
          DateTime? date;
          String? extractedText;

          // Parse based on pattern
          if (pattern.pattern.contains(r'(\w+)\s+(\d{1,2}),?\s+(\d{4})')) {
            // "March 20, 2026 at 10:00 AM"
            final monthStr = match.group(1)!;
            final day = int.parse(match.group(2)!);
            final year = int.parse(match.group(3)!);
            var hour = int.parse(match.group(4)!);
            final minute = int.parse(match.group(5)!);
            final ampm = match.group(6)?.toUpperCase();

            if (ampm == 'PM' && hour < 12) hour += 12;
            if (ampm == 'AM' && hour == 12) hour = 0;

            final month = _parseMonth(monthStr);
            if (month != null) {
              date = DateTime(year, month, day, hour, minute);
              extractedText = match.group(0);
            }
          } else if (pattern.pattern.contains(r'(\d{1,2})\s+(\w+)\s+(\d{4})')) {
            // "20 March 2026, 10:00"
            final day = int.parse(match.group(1)!);
            final monthStr = match.group(2)!;
            final year = int.parse(match.group(3)!);
            final hour = int.parse(match.group(4)!);
            final minute = int.parse(match.group(5)!);

            final month = _parseMonth(monthStr);
            if (month != null) {
              date = DateTime(year, month, day, hour, minute);
              extractedText = match.group(0);
            }
          } else if (pattern.pattern.contains(r'(\d{4})-(\d{2})-(\d{2})')) {
            // "2026-03-20 10:00"
            final year = int.parse(match.group(1)!);
            final month = int.parse(match.group(2)!);
            final day = int.parse(match.group(3)!);
            final hour = int.parse(match.group(4)!);
            final minute = int.parse(match.group(5)!);
            date = DateTime(year, month, day, hour, minute);
            extractedText = match.group(0);
          } else if (pattern.pattern.contains(r'(\d{1,2})/(\d{1,2})/(\d{4})')) {
            // "03/20/2026 at 10:00 AM"
            final month = int.parse(match.group(1)!);
            final day = int.parse(match.group(2)!);
            final year = int.parse(match.group(3)!);
            var hour = int.parse(match.group(4)!);
            final minute = int.parse(match.group(5)!);
            final ampm = match.group(6)?.toUpperCase();

            if (ampm == 'PM' && hour < 12) hour += 12;
            if (ampm == 'AM' && hour == 12) hour = 0;

            date = DateTime(year, month, day, hour, minute);
            extractedText = match.group(0);
          } else if (pattern.pattern.contains(r'(\w+)\s+(\d{1,2})\s+(?:at\s+)?(\d{1,2}):(\d{2})')) {
            // "March 20 at 10:00 AM" (assume current or next year)
            final monthStr = match.group(1)!;
            final day = int.parse(match.group(2)!);
            var hour = int.parse(match.group(3)!);
            final minute = int.parse(match.group(4)!);
            final ampm = match.group(5)?.toUpperCase();

            if (ampm == 'PM' && hour < 12) hour += 12;
            if (ampm == 'AM' && hour == 12) hour = 0;

            final month = _parseMonth(monthStr);
            if (month != null) {
              final now = DateTime.now();
              var year = now.year;

              // If the date has passed this year, assume next year
              final testDate = DateTime(year, month, day);
              if (testDate.isBefore(now)) {
                year++;
              }

              date = DateTime(year, month, day, hour, minute);
              extractedText = match.group(0);
            }
          }

          if (date != null) {
            result['startDate'] = date;
            result['endDate'] = date.add(const Duration(hours: 1)); // Default 1 hour duration
            result['extractedText'] = extractedText;

            // Debug logging
            debugPrint('📅 Extracted date: $date from text: "$extractedText"');
            debugPrint('📅 Formatted for calendar: ${_formatDateForCalendar(date)}');

            break;
          }
        } catch (e) {
          debugPrint('⚠️ Error parsing date pattern: $e');
          // Continue to next pattern
        }
      }
    }

    if (result.isEmpty) {
      debugPrint('⚠️ No date found in email. Subject: $subject');
      debugPrint('⚠️ First 200 chars of content: ${cleanContent.substring(0, cleanContent.length > 200 ? 200 : cleanContent.length)}');
    }

    return result;
  }

  int? _parseMonth(String monthStr) {
    const months = {
      'january': 1, 'jan': 1,
      'february': 2, 'feb': 2,
      'march': 3, 'mar': 3,
      'april': 4, 'apr': 4,
      'may': 5,
      'june': 6, 'jun': 6,
      'july': 7, 'jul': 7,
      'august': 8, 'aug': 8,
      'september': 9, 'sep': 9, 'sept': 9,
      'october': 10, 'oct': 10,
      'november': 11, 'nov': 11,
      'december': 12, 'dec': 12,
    };
    return months[monthStr.toLowerCase()];
  }

  String _formatDateForCalendar(DateTime date) {
    // Format: 20260320T100000Z (ISO 8601 basic format for Google Calendar)
    // Convert to UTC if not already
    final utcDate = date.toUtc();
    final year = utcDate.year.toString().padLeft(4, '0');
    final month = utcDate.month.toString().padLeft(2, '0');
    final day = utcDate.day.toString().padLeft(2, '0');
    final hour = utcDate.hour.toString().padLeft(2, '0');
    final minute = utcDate.minute.toString().padLeft(2, '0');
    final second = utcDate.second.toString().padLeft(2, '0');
    return '$year$month${day}T$hour$minute${second}Z';
  }

  String? _extractUrl(String content, List<String> keywords) {
    // Simple URL extraction - look for http/https links near keywords
    final urlPattern = RegExp(r'https?://[^\s<>"]+', caseSensitive: false);
    final matches = urlPattern.allMatches(content);

    final contentLower = content.toLowerCase();
    for (final keyword in keywords) {
      final keywordIndex = contentLower.indexOf(keyword);
      if (keywordIndex != -1) {
        // Find URL near this keyword
        for (final match in matches) {
          if ((match.start - keywordIndex).abs() < 500) {
            return match.group(0);
          }
        }
      }
    }

    // Return first URL if any
    return matches.isNotEmpty ? matches.first.group(0) : null;
  }
}

// Action chip widget for suggested actions
class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: const Color(0xFFE0E0E0), // Light gray border
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}