import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';

class GmailService {
  final String accessToken;
  static const String _baseUrl = 'https://gmail.googleapis.com/gmail/v1/users/me';

  GmailService({required this.accessToken});

  Map<String, String> get _headers => {
    'Authorization': 'Bearer $accessToken',
    'Content-Type': 'application/json',
  };

  /// Fetch list of messages with metadata
  Future<List<Map<String, dynamic>>> fetchMessages({int maxResults = 20}) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/messages?maxResults=$maxResults'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      throw GmailApiException('Failed to fetch messages: ${response.statusCode}');
    }

    final data = json.decode(response.body);
    final messages = data['messages'] as List<dynamic>? ?? [];
    
    return messages.map((m) => m as Map<String, dynamic>).toList();
  }

  /// Fetch full message details
  Future<Map<String, dynamic>> fetchMessage(String messageId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/messages/$messageId?format=full'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      throw GmailApiException('Failed to fetch message: ${response.statusCode}');
    }

    return json.decode(response.body);
  }

  /// Fetch message metadata only (lighter request)
  Future<Map<String, dynamic>> fetchMessageMetadata(String messageId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/messages/$messageId?format=metadata'
          '&metadataHeaders=Subject'
          '&metadataHeaders=From'
          '&metadataHeaders=To'
          '&metadataHeaders=Cc'
          '&metadataHeaders=Date'
          '&metadataHeaders=Message-ID'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      throw GmailApiException('Failed to fetch message metadata: ${response.statusCode}');
    }

    return json.decode(response.body);
  }

  /// Fetch entire thread with all messages
  Future<Map<String, dynamic>> fetchThread(String threadId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/threads/$threadId?format=full'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      throw GmailApiException('Failed to fetch thread: ${response.statusCode}');
    }

    return json.decode(response.body);
  }

  /// Send an email (supports HTML body, CC/BCC, and attachments)
  Future<Map<String, dynamic>> sendEmail({
    required String to,
    required String subject,
    required String body,
    String? threadId,
    String? inReplyTo,
    String? references,
    String? cc,
    String? bcc,
    bool isHtml = false,
    List<Map<String, dynamic>>? attachments, // [{filename, bytes, mimeType}]
  }) async {
    final email = _buildRawEmail(
      to: to,
      subject: subject,
      body: body,
      inReplyTo: inReplyTo,
      references: references,
      cc: cc,
      bcc: bcc,
      isHtml: isHtml,
      attachments: attachments,
    );

    final encodedEmail = base64Url.encode(utf8.encode(email));

    final requestBody = <String, dynamic>{
      'raw': encodedEmail,
    };
    
    if (threadId != null) {
      requestBody['threadId'] = threadId;
    }

    final response = await http.post(
      Uri.parse('$_baseUrl/messages/send'),
      headers: _headers,
      body: json.encode(requestBody),
    );

    if (response.statusCode != 200) {
      throw GmailApiException('Failed to send email: ${response.statusCode} - ${response.body}');
    }

    return json.decode(response.body);
  }

  /// Build RFC 2822 formatted email with optional MIME multipart for attachments
  String _buildRawEmail({
    required String to,
    required String subject,
    required String body,
    String? inReplyTo,
    String? references,
    String? cc,
    String? bcc,
    bool isHtml = false,
    List<Map<String, dynamic>>? attachments,
  }) {
    final buffer = StringBuffer();
    final hasAttachments = attachments != null && attachments.isNotEmpty;
    final boundary = 'boundary_${DateTime.now().millisecondsSinceEpoch}';
    
    // Common headers
    buffer.writeln('To: $to');
    if (cc != null && cc.isNotEmpty) buffer.writeln('Cc: $cc');
    if (bcc != null && bcc.isNotEmpty) buffer.writeln('Bcc: $bcc');
    buffer.writeln('Subject: $subject');
    buffer.writeln('MIME-Version: 1.0');
    
    if (inReplyTo != null && inReplyTo.isNotEmpty) {
      buffer.writeln('In-Reply-To: $inReplyTo');
    }
    if (references != null && references.isNotEmpty) {
      buffer.writeln('References: $references');
    }

    if (hasAttachments) {
      // Multipart message
      buffer.writeln('Content-Type: multipart/mixed; boundary="$boundary"');
      buffer.writeln();
      buffer.writeln('--$boundary');
      
      if (isHtml) {
        buffer.writeln('Content-Type: text/html; charset=utf-8');
        buffer.writeln('Content-Transfer-Encoding: 7bit');
        buffer.writeln();
        buffer.writeln(_markdownToHtml(body));
      } else {
        buffer.writeln('Content-Type: text/plain; charset=utf-8');
        buffer.writeln('Content-Transfer-Encoding: 7bit');
        buffer.writeln();
        buffer.writeln(body);
      }
      
      // Attachments
      for (final attachment in attachments!) {
        final filename = attachment['filename'] as String;
        final bytes = attachment['bytes'] as List<int>;
        final mimeType = attachment['mimeType'] as String? ?? 
            lookupMimeType(filename) ?? 'application/octet-stream';
        final base64Data = base64.encode(bytes);
        
        buffer.writeln();
        buffer.writeln('--$boundary');
        buffer.writeln('Content-Type: $mimeType; name="$filename"');
        buffer.writeln('Content-Disposition: attachment; filename="$filename"');
        buffer.writeln('Content-Transfer-Encoding: base64');
        buffer.writeln();
        
        // Write base64 in 76-char lines per RFC 2045
        for (var i = 0; i < base64Data.length; i += 76) {
          final end = (i + 76 < base64Data.length) ? i + 76 : base64Data.length;
          buffer.writeln(base64Data.substring(i, end));
        }
      }
      
      buffer.writeln('--$boundary--');
    } else {
      // Simple message
      if (isHtml) {
        buffer.writeln('Content-Type: text/html; charset=utf-8');
        buffer.writeln();
        buffer.writeln(_markdownToHtml(body));
      } else {
        buffer.writeln('Content-Type: text/plain; charset=utf-8');
        buffer.writeln();
        buffer.write(body);
      }
    }

    return buffer.toString();
  }

  /// Convert simple markdown formatting to HTML
  String _markdownToHtml(String markdown) {
    var html = markdown
        // Bold: **text** → <b>text</b>
        .replaceAllMapped(RegExp(r'\*\*(.+?)\*\*'), (m) => '<b>${m.group(1)}</b>')
        // Italic: _text_ → <i>text</i>
        .replaceAllMapped(RegExp(r'(?<![\w])_(.+?)_(?![\w])'), (m) => '<i>${m.group(1)}</i>')
        // Links: [text](url) → <a href="url">text</a>
        .replaceAllMapped(RegExp(r'\[(.+?)\]\((.+?)\)'), (m) => '<a href="${m.group(2)}">${m.group(1)}</a>')
        // Newlines → <br>
        .replaceAll('\n', '<br>\n');
    
    // Bullet lists: lines starting with "- " → <li>
    final lines = html.split('<br>\n');
    final processed = <String>[];
    bool inList = false;
    
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.startsWith('- ')) {
        if (!inList) {
          processed.add('<ul>');
          inList = true;
        }
        processed.add('<li>${trimmed.substring(2)}</li>');
      } else {
        if (inList) {
          processed.add('</ul>');
          inList = false;
        }
        processed.add(line);
      }
    }
    if (inList) processed.add('</ul>');
    
    return processed.join('\n');
  }

  /// Mark message as read
  Future<void> markAsRead(String messageId) async {
    await http.post(
      Uri.parse('$_baseUrl/messages/$messageId/modify'),
      headers: _headers,
      body: json.encode({
        'removeLabelIds': ['UNREAD'],
      }),
    );
  }

  /// Mark message as unread
  Future<void> markAsUnread(String messageId) async {
    await http.post(
      Uri.parse('$_baseUrl/messages/$messageId/modify'),
      headers: _headers,
      body: json.encode({
        'addLabelIds': ['UNREAD'],
      }),
    );
  }

  /// Archive message (remove from inbox)
  Future<void> archiveMessage(String messageId) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/messages/$messageId/modify'),
      headers: _headers,
      body: json.encode({
        'removeLabelIds': ['INBOX'],
      }),
    );

    if (response.statusCode != 200) {
      throw GmailApiException('Failed to archive: ${response.statusCode}');
    }
  }

  /// Move message to trash
  Future<void> trashMessage(String messageId) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/messages/$messageId/trash'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      throw GmailApiException('Failed to trash: ${response.statusCode}');
    }
  }

  /// Star a message
  Future<void> starMessage(String messageId) async {
    await http.post(
      Uri.parse('$_baseUrl/messages/$messageId/modify'),
      headers: _headers,
      body: json.encode({
        'addLabelIds': ['STARRED'],
      }),
    );
  }

  /// Unstar a message
  Future<void> unstarMessage(String messageId) async {
    await http.post(
      Uri.parse('$_baseUrl/messages/$messageId/modify'),
      headers: _headers,
      body: json.encode({
        'removeLabelIds': ['STARRED'],
      }),
    );
  }

  /// Fetch an attachment by message ID and attachment ID
  Future<String?> fetchAttachment(String messageId, String attachmentId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/messages/$messageId/attachments/$attachmentId'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      throw GmailApiException('Failed to fetch attachment: ${response.statusCode}');
    }

    final data = json.decode(response.body);
    return data['data'] as String?;
  }
}

class GmailApiException implements Exception {
  final String message;
  GmailApiException(this.message);

  @override
  String toString() => 'GmailApiException: $message';
}