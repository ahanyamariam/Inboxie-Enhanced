import 'package:flutter/material.dart';
import 'package:app/core/theme/app_colors.dart';

class EmailBodyView extends StatelessWidget {
  final String plainText;
  final String htmlContent;
  final String snippet;

  const EmailBodyView({
    Key? key,
    required this.plainText,
    required this.htmlContent,
    required this.snippet,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // For MVP, we'll use plain text rendering
    // You can add flutter_html package later for HTML rendering
    
    final displayText = _getDisplayText();
    
    if (displayText.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'No content available',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    return SelectableText(
      displayText,
      style: TextStyle(
        fontSize: 14,
        color: AppColors.textPrimary,
        height: 1.6,
      ),
    );
  }

  String _getDisplayText() {
    // Prefer plain text for MVP (simpler and more reliable)
    if (plainText.isNotEmpty) {
      return _cleanText(plainText);
    }
    
    // If only HTML available, strip tags
    if (htmlContent.isNotEmpty) {
      return _stripHtml(htmlContent);
    }
    
    return snippet;
  }

  String _cleanText(String text) {
    return text
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
  }

  String _stripHtml(String html) {
    return html
        .replaceAll(RegExp(r'<style[^>]*>.*?</style>', dotAll: true), '')
        .replaceAll(RegExp(r'<script[^>]*>.*?</script>', dotAll: true), '')
        .replaceAll(RegExp(r'<br\s*/?>'), '\n')
        .replaceAll(RegExp(r'<p[^>]*>'), '\n')
        .replaceAll(RegExp(r'</p>'), '\n')
        .replaceAll(RegExp(r'<div[^>]*>'), '\n')
        .replaceAll(RegExp(r'</div>'), '')
        .replaceAll(RegExp(r'<[^>]+>'), '')
        .replaceAll(RegExp(r'&nbsp;'), ' ')
        .replaceAll(RegExp(r'&amp;'), '&')
        .replaceAll(RegExp(r'&lt;'), '<')
        .replaceAll(RegExp(r'&gt;'), '>')
        .replaceAll(RegExp(r'&quot;'), '"')
        .replaceAll(RegExp(r'&#39;'), "'")
        .replaceAll(RegExp(r'\n\s*\n\s*\n'), '\n\n')
        .trim();
  }
}