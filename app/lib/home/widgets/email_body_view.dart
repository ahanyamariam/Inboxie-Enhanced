import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:app/core/theme/app_colors.dart';

class EmailBodyView extends StatelessWidget {
  final String plainText;
  final String htmlContent;
  final String snippet;

  const EmailBodyView({
    super.key,
    required this.plainText,
    required this.htmlContent,
    required this.snippet,
  });

  @override
  Widget build(BuildContext context) {
    // Prefer HTML content for rich rendering (images, formatting, links)
    if (htmlContent.isNotEmpty) {
      return _buildHtmlView();
    }

    // Fallback to plain text
    final displayText = _getPlainDisplayText();

    if (displayText.isEmpty) {
      return _buildEmptyState();
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

  Widget _buildHtmlView() {
    return HtmlWidget(
      htmlContent,
      textStyle: TextStyle(
        fontSize: 14,
        color: AppColors.textPrimary,
        height: 1.6,
      ),
      onTapUrl: (url) async {
        final uri = Uri.tryParse(url);
        if (uri != null && await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
        return true;
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
          color: AppColors.textSecondary,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  String _getPlainDisplayText() {
    if (plainText.isNotEmpty) {
      return _cleanText(plainText);
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
}