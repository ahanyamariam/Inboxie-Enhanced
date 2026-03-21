import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:app/core/theme/app_colors.dart';

class EmailBodyView extends StatefulWidget {
  final String plainText;
  final String htmlContent;
  final String snippet;
  final Map<String, dynamic>? messageData;
  final String accessToken;

  const EmailBodyView({
    super.key,
    required this.plainText,
    required this.htmlContent,
    required this.snippet,
    this.messageData,
    required this.accessToken,
  });

  @override
  State<EmailBodyView> createState() => _EmailBodyViewState();
}

class _EmailBodyViewState extends State<EmailBodyView> {
  String? _processedHtml;
  bool _isLoadingImages = false;

  @override
  void initState() {
    super.initState();
    debugPrint('🔍 messageData null? ${widget.messageData == null}');
    debugPrint('🔍 accessToken: ${widget.accessToken.substring(0, 20)}...');
    debugPrint('🔍 HTML contains cid: ${widget.htmlContent.contains('cid:')}');
    if (widget.htmlContent.isNotEmpty && 
        widget.messageData != null && 
        widget.htmlContent.contains('cid:')) {
      _fetchAndProcessInlineImages();
    }
  }

  Future<void> _fetchAndProcessInlineImages() async {
    setState(() => _isLoadingImages = true);

    try {
      final inlineImages = await _getInlineAttachments();
      String processedHtml = widget.htmlContent;
      
      inlineImages.forEach((cid, base64Data) {
        processedHtml = processedHtml.replaceAll(
          'src="cid:$cid"',
          'src="data:image/jpeg;base64,$base64Data"',
        );
      });

      if (mounted) {
        setState(() {
          _processedHtml = processedHtml;
          _isLoadingImages = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _processedHtml = widget.htmlContent;
          _isLoadingImages = false;
        });
      }
    }
  }

  Future<Map<String, String>> _getInlineAttachments() async {
    if (widget.messageData == null) return {};
    
    final Map<String, String> cidToBase64 = {};
    final messageId = widget.messageData!['id']?.toString();
    if (messageId == null) return {};

    Future<void> traverseParts(dynamic part) async {
      if (part == null) return;
      
      final headers = part['headers'] as List<dynamic>?;
      String? contentId;
      
      if (headers != null) {
        for (var header in headers) {
          if (header['name']?.toString().toLowerCase() == 'content-id') {
            contentId = header['value']?.toString()
                .replaceAll('<', '')
                .replaceAll('>', '');
            break;
          }
        }
      }
      
      if (contentId != null) {
        final body = part['body'] as Map<String, dynamic>?;
        if (body != null) {
          final attachmentId = body['attachmentId']?.toString();
          final inlineData = body['data']?.toString();
          
          if (inlineData != null && inlineData.isNotEmpty) {
            String standardBase64 = inlineData
                .replaceAll('-', '+')
                .replaceAll('_', '/');
            while (standardBase64.length % 4 != 0) {
              standardBase64 += '=';
            }
            cidToBase64[contentId] = standardBase64;
          } else if (attachmentId != null) {
            try {
              final attachmentData = await _fetchAttachment(messageId, attachmentId);
              if (attachmentData != null) {
                String standardBase64 = attachmentData
                    .replaceAll('-', '+')
                    .replaceAll('_', '/');
                while (standardBase64.length % 4 != 0) {
                  standardBase64 += '=';
                }
                cidToBase64[contentId] = standardBase64;
              }
            } catch (e) {
              debugPrint('Error fetching attachment: $e');
            }
          }
        }
      }
      
      final parts = part['parts'] as List<dynamic>?;
      if (parts != null) {
        for (var subPart in parts) {
          await traverseParts(subPart);
        }
      }
    }
    
    final payload = widget.messageData!['payload'];
    await traverseParts(payload);
    
    return cidToBase64;
  }

  Future<String?> _fetchAttachment(String messageId, String attachmentId) async {
    try {
      final url = 'https://gmail.googleapis.com/gmail/v1/users/me/messages/$messageId/attachments/$attachmentId';
      final uri = Uri.parse(url);
      final httpClient = HttpClient();
      final request = await httpClient.getUrl(uri);
      request.headers.set('Authorization', 'Bearer ${widget.accessToken}');
      
      final response = await request.close();
      
      if (response.statusCode == 200) {
        final responseBody = await response.transform(utf8.decoder).join();
        final data = json.decode(responseBody);
        httpClient.close();
        return data['data']?.toString();
      }
      httpClient.close();
      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingImages) {
      return Column(
        children: [
          if (widget.htmlContent.isNotEmpty)
            _buildHtmlView(widget.htmlContent),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primaryBlue.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Loading images...',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.getTextSecondary(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    if (_processedHtml != null && _processedHtml!.isNotEmpty) {
      return _buildHtmlView(_processedHtml!);
    }

    if (widget.htmlContent.isNotEmpty) {
      return _buildHtmlView(widget.htmlContent);
    }

    final displayText = _getPlainDisplayText();
    if (displayText.isEmpty) {
      return _buildEmptyState();
    }

    return SelectableText(
      displayText,
      style: TextStyle(
        fontSize: 14,
        color: AppColors.getTextPrimary(context),
        height: 1.6,
      ),
    );
  }

  Widget _buildHtmlView(String html) {
    return HtmlWidget(
      html,
      textStyle: TextStyle(
        fontSize: 14,
        color: AppColors.getTextPrimary(context),
        height: 1.6,
      ),
      onTapUrl: (url) async {
        final uri = Uri.tryParse(url);
        if (uri != null && await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
        return true;
      },
      onErrorBuilder: (context, element, error) {
        if (element.localName == 'img') {
          return Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.broken_image_outlined,
                  size: 16,
                  color: AppColors.getTextSecondary(context),
                ),
                const SizedBox(width: 6),
                Text(
                  'Image unavailable',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.getTextSecondary(context),
                  ),
                ),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'No content available',
        style: TextStyle(
          color: AppColors.getTextSecondary(context),
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  String _getPlainDisplayText() {
    if (widget.plainText.isNotEmpty) {
      return _cleanText(widget.plainText);
    }
    return widget.snippet;
  }

  String _cleanText(String text) {
    return text
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
  }
}