import 'dart:convert';
import 'package:app/models/email_model.dart';

class EmailDetailModel {
  final String id;
  final String threadId;
  final String subject;
  final String from;
  final String fromEmail;
  final String fromName;
  final List<String> to;
  final List<String> cc;
  final DateTime date;
  final String bodyPlain;
  final String bodyHtml;
  final String snippet;
  final List<AttachmentInfo> attachments;
  final List<String> labelIds;
  final bool isUnread;
  final bool isStarred;
  final String? messageIdHeader;
  final String? inReplyTo;
  final String? references;
  final ActionType actionType;
  final Map<String, dynamic>? rawData;
  

  EmailDetailModel({
    required this.id,
    required this.threadId,
    required this.subject,
    required this.from,
    required this.fromEmail,
    required this.fromName,
    required this.to,
    required this.cc,
    required this.date,
    required this.bodyPlain,
    required this.bodyHtml,
    required this.snippet,
    required this.attachments,
    required this.labelIds,
    required this.isUnread,
    required this.isStarred,
    this.messageIdHeader,
    this.inReplyTo,
    this.references,
    this.rawData,
    this.actionType = ActionType.none,
    
  });

  factory EmailDetailModel.fromGmailApi(Map<String, dynamic> json) {
    final payload = json['payload'] as Map<String, dynamic>? ?? {};
    final headers = payload['headers'] as List<dynamic>? ?? [];

    String getHeader(String name) {
      for (final header in headers) {
        if ((header['name'] as String).toLowerCase() == name.toLowerCase()) {
          return header['value'] as String? ?? '';
        }
      }
      return '';
    }

    final from = getHeader('From');
    final fromParts = _parseEmailAddress(from);
    
    final toRaw = getHeader('To');
    final ccRaw = getHeader('Cc');
    
    final dateStr = getHeader('Date');
    final date = _parseEmailDate(dateStr);

    final bodyResult = _extractBody(payload);
    final attachments = _extractAttachments(payload);

    final labelIds = (json['labelIds'] as List<dynamic>?)
        ?.map((l) => l as String)
        .toList() ?? [];

    return EmailDetailModel(
      id: json['id'] as String? ?? '',
      threadId: json['threadId'] as String? ?? '',
      subject: getHeader('Subject'),
      from: from,
      fromEmail: fromParts['email'] ?? '',
      fromName: fromParts['name'] ?? '',
      to: toRaw.isNotEmpty 
          ? toRaw.split(',').map((e) => e.trim()).toList() 
          : [],
      cc: ccRaw.isNotEmpty 
          ? ccRaw.split(',').map((e) => e.trim()).toList() 
          : [],
      date: date,
      bodyPlain: bodyResult['plain'] ?? '',
      bodyHtml: bodyResult['html'] ?? '',
      snippet: json['snippet'] as String? ?? '',
      attachments: attachments,
      labelIds: labelIds,
      isUnread: labelIds.contains('UNREAD'),
      isStarred: labelIds.contains('STARRED'),
      messageIdHeader: getHeader('Message-ID'),
      inReplyTo: getHeader('In-Reply-To'),
      references: getHeader('References'),
      rawData: json,
    );
  }

  static Map<String, String> _parseEmailAddress(String raw) {
    if (raw.isEmpty) {
      return {'name': 'Unknown', 'email': ''};
    }
    
    final regex = RegExp(r'^(.+?)\s*<(.+?)>$');
    final match = regex.firstMatch(raw.trim());
    
    if (match != null) {
      return {
        'name': match.group(1)?.replaceAll('"', '').trim() ?? '',
        'email': match.group(2) ?? '',
      };
    }
    
    if (raw.contains('@')) {
      return {
        'name': raw.split('@').first,
        'email': raw.trim(),
      };
    }
    
    return {'name': raw, 'email': raw};
  }

  static DateTime _parseEmailDate(String dateStr) {
    if (dateStr.isEmpty) return DateTime.now();
    
    try {
      // Try to parse RFC 2822 format
      // Example: "Mon, 15 Jan 2025 10:30:00 +0000"
      final cleanDate = dateStr
          .replaceAll(RegExp(r'\([^)]*\)'), '')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
      
      // Try parsing with common patterns
      final patterns = [
        RegExp(r'(\d{1,2})\s+(\w{3})\s+(\d{4})\s+(\d{1,2}):(\d{2}):(\d{2})'),
      ];
      
      for (final pattern in patterns) {
        final match = pattern.firstMatch(cleanDate);
        if (match != null) {
          final months = {
            'Jan': 1, 'Feb': 2, 'Mar': 3, 'Apr': 4, 'May': 5, 'Jun': 6,
            'Jul': 7, 'Aug': 8, 'Sep': 9, 'Oct': 10, 'Nov': 11, 'Dec': 12,
          };
          
          final day = int.parse(match.group(1)!);
          final month = months[match.group(2)] ?? 1;
          final year = int.parse(match.group(3)!);
          final hour = int.parse(match.group(4)!);
          final minute = int.parse(match.group(5)!);
          final second = int.parse(match.group(6)!);
          
          return DateTime(year, month, day, hour, minute, second);
        }
      }
      
      return DateTime.tryParse(cleanDate) ?? DateTime.now();
    } catch (_) {
      return DateTime.now();
    }
  }

  static Map<String, String> _extractBody(Map<String, dynamic> payload) {
    String plainBody = '';
    String htmlBody = '';

    void extractFromPart(Map<String, dynamic> part) {
      final mimeType = part['mimeType'] as String? ?? '';
      final body = part['body'] as Map<String, dynamic>?;
      final data = body?['data'] as String?;

      if (data != null && data.isNotEmpty) {
        final decoded = _decodeBase64Url(data);
        
        if (mimeType == 'text/plain' && plainBody.isEmpty) {
          plainBody = decoded;
        } else if (mimeType == 'text/html' && htmlBody.isEmpty) {
          htmlBody = decoded;
        }
      }

      final parts = part['parts'] as List<dynamic>?;
      if (parts != null) {
        for (final p in parts) {
          extractFromPart(p as Map<String, dynamic>);
        }
      }
    }

    extractFromPart(payload);

    return {'plain': plainBody, 'html': htmlBody};
  }

  static String _decodeBase64Url(String data) {
    try {
      String normalized = data.replaceAll('-', '+').replaceAll('_', '/');
      
      while (normalized.length % 4 != 0) {
        normalized += '=';
      }

      final bytes = base64.decode(normalized);
      return utf8.decode(bytes, allowMalformed: true);
    } catch (e) {
      return '';
    }
  }

  static List<AttachmentInfo> _extractAttachments(Map<String, dynamic> payload) {
    final attachments = <AttachmentInfo>[];

    void extractFromPart(Map<String, dynamic> part) {
      final filename = part['filename'] as String?;
      final body = part['body'] as Map<String, dynamic>?;
      final attachmentId = body?['attachmentId'] as String?;
      final size = body?['size'] as int? ?? 0;
      final mimeType = part['mimeType'] as String?;
      final partHeaders = part['headers'] as List<dynamic>? ?? [];

      // Extract Content-ID header for inline images
      String? contentId;
      for (final header in partHeaders) {
        final name = (header['name'] as String? ?? '').toLowerCase();
        if (name == 'content-id') {
          // Content-ID is typically wrapped in angle brackets: <image001@example.com>
          contentId = (header['value'] as String? ?? '')
              .replaceAll('<', '')
              .replaceAll('>', '')
              .trim();
          break;
        }
      }

      // Include attachment if:
      // 1. It has a filename AND attachmentId (regular attachment)
      // 2. OR it has a Content-ID AND attachmentId (inline image, may have empty filename)
      final hasFilename = filename != null && filename.isNotEmpty;
      final hasContentId = contentId != null && contentId.isNotEmpty;
      final hasAttachmentId = attachmentId != null && attachmentId.isNotEmpty;

      if (hasAttachmentId && (hasFilename || hasContentId)) {
        // For inline images without filename, generate a name from mimeType
        final effectiveFilename = (filename != null && filename.isNotEmpty)
            ? filename
            : 'inline_${contentId ?? DateTime.now().millisecondsSinceEpoch}.${_getExtFromMime(mimeType)}';

        attachments.add(AttachmentInfo(
          id: attachmentId,
          filename: effectiveFilename,
          mimeType: mimeType ?? 'application/octet-stream',
          size: size,
          contentId: contentId,
        ));
      }

      final parts = part['parts'] as List<dynamic>?;
      if (parts != null) {
        for (final p in parts) {
          extractFromPart(p as Map<String, dynamic>);
        }
      }
    }

    extractFromPart(payload);
    return attachments;
  }

  /// Get file extension from MIME type
  static String _getExtFromMime(String? mimeType) {
    if (mimeType == null) return 'bin';
    if (mimeType.contains('jpeg') || mimeType.contains('jpg')) return 'jpg';
    if (mimeType.contains('png')) return 'png';
    if (mimeType.contains('gif')) return 'gif';
    if (mimeType.contains('webp')) return 'webp';
    if (mimeType.contains('bmp')) return 'bmp';
    if (mimeType.contains('pdf')) return 'pdf';
    return 'bin';
  }

  String get formattedDate {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    
    return '${date.day}/${date.month}/${date.year}';
  }

  String get fullFormattedDate {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final hour = date.hour > 12 ? date.hour - 12 : date.hour;
    final ampm = date.hour >= 12 ? 'PM' : 'AM';
    final minute = date.minute.toString().padLeft(2, '0');
    
    return '${months[date.month - 1]} ${date.day}, ${date.year} at $hour:$minute $ampm';
  }

  String get senderInitials {
    if (fromName.isEmpty) return 'U';
    final parts = fromName.trim().split(' ');
    if (parts.length == 1) {
      return parts[0].isNotEmpty ? parts[0][0].toUpperCase() : 'U';
    }
    return '${parts[0][0]}${parts.last[0]}'.toUpperCase();
  }

  String get displayBody {
    if (bodyPlain.isNotEmpty) return bodyPlain;
    if (bodyHtml.isNotEmpty) return _stripHtml(bodyHtml);
    return snippet;
  }

  static String _stripHtml(String html) {
    return html
        .replaceAll(RegExp(r'<br\s*/?>'), '\n')
        .replaceAll(RegExp(r'<p[^>]*>'), '\n')
        .replaceAll(RegExp(r'</p>'), '\n')
        .replaceAll(RegExp(r'<[^>]+>'), '')
        .replaceAll(RegExp(r'&nbsp;'), ' ')
        .replaceAll(RegExp(r'&amp;'), '&')
        .replaceAll(RegExp(r'&lt;'), '<')
        .replaceAll(RegExp(r'&gt;'), '>')
        .replaceAll(RegExp(r'\n\s*\n'), '\n\n')
        .trim();
  }
}

class AttachmentInfo {
  final String id;
  final String filename;
  final String mimeType;
  final int size;
  final String? contentId; // For inline images (cid: references)

  AttachmentInfo({
    required this.id,
    required this.filename,
    required this.mimeType,
    required this.size,
    this.contentId,
  });

  /// Check if this is an inline image (has Content-ID for cid: reference)
  bool get isInline => contentId != null && contentId!.isNotEmpty;

  String get formattedSize {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String get icon {
    final ext = filename.split('.').last.toLowerCase();
    
    if (['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'].contains(ext)) return '🖼️';
    if (ext == 'pdf') return '📄';
    if (['doc', 'docx'].contains(ext)) return '📝';
    if (['xls', 'xlsx'].contains(ext)) return '📊';
    if (['ppt', 'pptx'].contains(ext)) return '📽️';
    if (['zip', 'rar', '7z', 'tar', 'gz'].contains(ext)) return '📦';
    if (['mp3', 'wav', 'ogg', 'm4a'].contains(ext)) return '🎵';
    if (['mp4', 'mov', 'avi', 'mkv'].contains(ext)) return '🎬';
    if (['txt', 'rtf'].contains(ext)) return '📃';
    
    return '📎';
  }
}