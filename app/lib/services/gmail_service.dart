import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';

class GmailService {
  final String accessToken;
  static const String _baseUrl = 'https://gmail.googleapis.com/gmail/v1/users/me';
  static const Duration _requestTimeout = Duration(seconds: 20);

  GmailService({required this.accessToken});

  Map<String, String> get _headers => {
    'Authorization': 'Bearer $accessToken',
    'Content-Type': 'application/json',
  };

  Future<http.Response> _get(String url) async {
    try {
      return await http.get(Uri.parse(url), headers: _headers).timeout(_requestTimeout);
    } on TimeoutException {
      throw GmailApiException('Request timed out while contacting Gmail API');
    }
  }

  Future<http.Response> _post(String url, {Object? body}) async {
    try {
      return await http
          .post(Uri.parse(url), headers: _headers, body: body)
          .timeout(_requestTimeout);
    } on TimeoutException {
      throw GmailApiException('Request timed out while contacting Gmail API');
    }
  }

  /// Fetch list of messages with metadata
  Future<List<Map<String, dynamic>>> fetchMessages({int maxResults = 20}) async {
    final response = await _get('$_baseUrl/messages?maxResults=$maxResults');

    if (response.statusCode != 200) {
      throw GmailApiException('Failed to fetch messages: ${response.statusCode}');
    }

    final data = json.decode(response.body);
    final messages = data['messages'] as List<dynamic>? ?? [];
    
    return messages.map((m) => m as Map<String, dynamic>).toList();
  }

  /// Fetch full message details
  Future<Map<String, dynamic>> fetchMessage(String messageId) async {
    final response = await _get('$_baseUrl/messages/$messageId?format=full');

    if (response.statusCode != 200) {
      throw GmailApiException('Failed to fetch message: ${response.statusCode}');
    }

    return json.decode(response.body);
  }

  /// Fetch message metadata only (lighter request)
  Future<Map<String, dynamic>> fetchMessageMetadata(String messageId) async {
    final response = await _get(
      '$_baseUrl/messages/$messageId?format=metadata'
      '&metadataHeaders=Subject'
      '&metadataHeaders=From'
      '&metadataHeaders=To'
      '&metadataHeaders=Cc'
      '&metadataHeaders=Date'
      '&metadataHeaders=Message-ID',
    );

    if (response.statusCode != 200) {
      throw GmailApiException('Failed to fetch message metadata: ${response.statusCode}');
    }

    return json.decode(response.body);
  }

  /// Fetch entire thread with all messages
  Future<Map<String, dynamic>> fetchThread(String threadId) async {
    final response = await _get('$_baseUrl/threads/$threadId?format=full');

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
    List<File>? attachments,
  }) async {
    final email = await _buildMimeMessage(
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

    final response = await _post(
      '$_baseUrl/messages/send',
      body: json.encode(requestBody),
    );

    if (response.statusCode != 200) {
      throw GmailApiException('Failed to send email: ${response.statusCode} - ${response.body}');
    }

    return json.decode(response.body);
  }

  /// Build RFC 2822 multipart/mixed MIME message with optional file attachments.
  /// Uses CRLF line endings as required by RFC 2822.
  Future<String> _buildMimeMessage({
    required String to,
    required String subject,
    required String body,
    String? inReplyTo,
    String? references,
    String? cc,
    String? bcc,
    bool isHtml = false,
    List<File>? attachments,
  }) async {
    const crlf = '\r\n';
    final buffer = StringBuffer();
    final boundary = 'mixed_${DateTime.now().millisecondsSinceEpoch}';
    final bodyHtml = isHtml ? _markdownToHtml(body) : _plainTextToHtml(body);

    // Headers (RFC 2822 requires CRLF line endings)
    buffer.write('To: $to$crlf');
    if (cc != null && cc.isNotEmpty) buffer.write('Cc: $cc$crlf');
    if (bcc != null && bcc.isNotEmpty) buffer.write('Bcc: $bcc$crlf');
    buffer.write('Subject: $subject$crlf');
    buffer.write('MIME-Version: 1.0$crlf');
    if (inReplyTo != null && inReplyTo.isNotEmpty) {
      buffer.write('In-Reply-To: $inReplyTo$crlf');
    }
    if (references != null && references.isNotEmpty) {
      buffer.write('References: $references$crlf');
    }
    buffer.write('Content-Type: multipart/mixed; boundary="$boundary"$crlf');
    buffer.write(crlf);

    // Body part (always HTML in multipart message)
    buffer.write('--$boundary$crlf');
    buffer.write('Content-Type: text/html; charset=utf-8$crlf');
    buffer.write('Content-Transfer-Encoding: 7bit$crlf');
    buffer.write(crlf);
    buffer.write('$bodyHtml$crlf');

    // Attachment parts
    for (final attachment in attachments ?? <File>[]) {
      final filename = attachment.uri.pathSegments.isNotEmpty
          ? attachment.uri.pathSegments.last
          : 'attachment';
      final safeFilename = filename.replaceAll('"', '');
      final bytes = await attachment.readAsBytes();
      final mimeType =
          lookupMimeType(attachment.path, headerBytes: bytes) ??
          'application/octet-stream';
      final base64Data = base64.encode(bytes);

      buffer.write('--$boundary$crlf');
      buffer.write('Content-Type: $mimeType; name="$safeFilename"$crlf');
      buffer.write(
        'Content-Disposition: attachment; filename="$safeFilename"$crlf',
      );
      buffer.write('Content-Transfer-Encoding: base64$crlf');
      buffer.write(crlf);
      // Split base64 data into 76-character lines as per MIME spec
      for (var i = 0; i < base64Data.length; i += 76) {
        final end = (i + 76 < base64Data.length) ? i + 76 : base64Data.length;
        buffer.write('${base64Data.substring(i, end)}$crlf');
      }
    }
    buffer.write('--$boundary--$crlf');

    return buffer.toString();
  }

  String _plainTextToHtml(String text) {
    final escaped = text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;');
    return escaped.replaceAll('\n', '<br>\n');
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
    await _post(
      '$_baseUrl/messages/$messageId/modify',
      body: json.encode({
        'removeLabelIds': ['UNREAD'],
      }),
    );
  }

  /// Mark message as unread
  Future<void> markAsUnread(String messageId) async {
    await _post(
      '$_baseUrl/messages/$messageId/modify',
      body: json.encode({
        'addLabelIds': ['UNREAD'],
      }),
    );
  }

  /// Archive message (remove from inbox)
  Future<void> archiveMessage(String messageId) async {
    final response = await _post(
      '$_baseUrl/messages/$messageId/modify',
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
    final response = await _post('$_baseUrl/messages/$messageId/trash');

    if (response.statusCode != 200) {
      throw GmailApiException('Failed to trash: ${response.statusCode}');
    }
  }

  /// Star a message
  Future<void> starMessage(String messageId) async {
    await _post(
      '$_baseUrl/messages/$messageId/modify',
      body: json.encode({
        'addLabelIds': ['STARRED'],
      }),
    );
  }

  /// Unstar a message
  Future<void> unstarMessage(String messageId) async {
    await _post(
      '$_baseUrl/messages/$messageId/modify',
      body: json.encode({
        'removeLabelIds': ['STARRED'],
      }),
    );
  }

  /// Fetch an attachment by message ID and attachment ID
  Future<String?> fetchAttachment(String messageId, String attachmentId) async {
    final response = await _get(
      '$_baseUrl/messages/$messageId/attachments/$attachmentId',
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
