import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import 'package:app/core/theme/app_colors.dart';
import 'package:app/models/email_detail_model.dart';

enum ComposeMode {
  reply,
  replyAll,
  forward,
  compose, // Generic compose
}

class ComposeSheet extends StatefulWidget {
  final ComposeMode mode;
  final EmailDetailModel? replyTo;
  final String? threadId;
  final String? initialBody;
  final Function(String to, String subject, String body, {
    String? cc,
    String? bcc,
    bool isHtml,
    List<Map<String, dynamic>>? attachments,
  }) onSend;

  const ComposeSheet({
    super.key,
    required this.mode,
    this.replyTo,
    this.threadId,
    this.initialBody,
    required this.onSend,
  });

  @override
  State<ComposeSheet> createState() => _ComposeSheetState();
}

class _ComposeSheetState extends State<ComposeSheet> {
  final TextEditingController _toController = TextEditingController();
  final TextEditingController _ccController = TextEditingController();
  final TextEditingController _bccController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();
  final FocusNode _bodyFocusNode = FocusNode();
  bool _isSending = false;
  bool _showCcBcc = false;
  bool _isFormatting = false; // Whether body uses markdown formatting
  List<PlatformFile> _attachments = [];

  @override
  void initState() {
    super.initState();
    _initializeFields();
  }

  void _initializeFields() {
    if (widget.replyTo != null) {
      final msg = widget.replyTo!;

      switch (widget.mode) {
        case ComposeMode.reply:
          _toController.text = msg.fromEmail;
          _subjectController.text = msg.subject.startsWith('Re:')
              ? msg.subject
              : 'Re: ${msg.subject}';
          if (widget.initialBody != null) {
            _bodyController.text = widget.initialBody!;
          }
          break;

        case ComposeMode.replyAll:
          final allRecipients = {
            msg.fromEmail,
            ...msg.to.where((e) => !e.contains('me')),
            ...msg.cc,
          }.join(', ');

          _toController.text = allRecipients;
          _subjectController.text = msg.subject.startsWith('Re:')
              ? msg.subject
              : 'Re: ${msg.subject}';
          break;

        case ComposeMode.forward:
          _subjectController.text = msg.subject.startsWith('Fwd:')
              ? msg.subject
              : 'Fwd: ${msg.subject}';
          _bodyController.text =
              '\n\n---------- Forwarded message ----------\n'
              'From: ${msg.fromName} <${msg.fromEmail}>\n'
              'Date: ${msg.date}\n'
              'Subject: ${msg.subject}\n'
              'To: ${msg.to.join(", ")}\n\n'
              '${msg.snippet}';
          break;

        case ComposeMode.compose:
          break;
      }
    }
  }

  @override
  void dispose() {
    _toController.dispose();
    _ccController.dispose();
    _bccController.dispose();
    _subjectController.dispose();
    _bodyController.dispose();
    _bodyFocusNode.dispose();
    super.dispose();
  }

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.any,
    );

    if (result != null) {
      setState(() {
        _attachments.addAll(result.files);
      });
    }
  }

  void _removeAttachment(int index) {
    setState(() {
      _attachments.removeAt(index);
    });
  }

  void _insertFormatting(String prefix, String suffix) {
    final text = _bodyController.text;
    final selection = _bodyController.selection;

    if (selection.isValid && selection.start != selection.end) {
      // Wrap selection
      final selected = text.substring(selection.start, selection.end);
      final newText = text.replaceRange(
        selection.start,
        selection.end,
        '$prefix$selected$suffix',
      );
      _bodyController.text = newText;
      _bodyController.selection = TextSelection.collapsed(
        offset: selection.start + prefix.length + selected.length + suffix.length,
      );
    } else {
      // Insert at cursor
      final cursorPos = selection.isValid ? selection.start : text.length;
      final newText = text.replaceRange(cursorPos, cursorPos, '$prefix$suffix');
      _bodyController.text = newText;
      _bodyController.selection = TextSelection.collapsed(
        offset: cursorPos + prefix.length,
      );
    }
    _isFormatting = true;
    _bodyFocusNode.requestFocus();
  }

  void _showInsertLinkDialog() {
    final linkTextController = TextEditingController();
    final linkUrlController = TextEditingController();

    // Pre-fill with selected text
    final selection = _bodyController.selection;
    if (selection.isValid && selection.start != selection.end) {
      linkTextController.text = _bodyController.text.substring(
        selection.start,
        selection.end,
      );
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Insert Link'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: linkTextController,
              decoration: const InputDecoration(
                labelText: 'Display text',
                hintText: 'Click here',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: linkUrlController,
              decoration: const InputDecoration(
                labelText: 'URL',
                hintText: 'https://example.com',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.url,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final text = linkTextController.text.isNotEmpty
                  ? linkTextController.text
                  : linkUrlController.text;
              final url = linkUrlController.text;

              if (url.isNotEmpty) {
                final markdown = '[$text]($url)';
                final bodyText = _bodyController.text;
                final sel = _bodyController.selection;

                if (sel.isValid && sel.start != sel.end) {
                  _bodyController.text = bodyText.replaceRange(
                    sel.start,
                    sel.end,
                    markdown,
                  );
                } else {
                  final pos = sel.isValid ? sel.start : bodyText.length;
                  _bodyController.text = bodyText.replaceRange(pos, pos, markdown);
                }
                _isFormatting = true;
              }
              Navigator.pop(context);
            },
            child: const Text('Insert'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSend() async {
    if (_toController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add a recipient')),
      );
      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      // Prepare attachments
      List<Map<String, dynamic>>? attachmentData;
      if (_attachments.isNotEmpty) {
        attachmentData = [];
        for (final file in _attachments) {
          if (file.bytes != null) {
            attachmentData.add({
              'filename': file.name,
              'bytes': file.bytes!,
              'mimeType': null, // Will be detected by GmailService
            });
          } else if (file.path != null) {
            // Read from path
            final fileData = await File(file.path!).readAsBytes();
            attachmentData.add({
              'filename': file.name,
              'bytes': fileData,
              'mimeType': null,
            });
          }
        }
      }

      await widget.onSend(
        _toController.text,
        _subjectController.text,
        _bodyController.text,
        cc: _ccController.text.isNotEmpty ? _ccController.text : null,
        bcc: _bccController.text.isNotEmpty ? _bccController.text : null,
        isHtml: _isFormatting,
        attachments: attachmentData,
      );
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: AppColors.getSurface(context),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Header
          _buildHeader(),
          const Divider(height: 1),

          // Fields + Body
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  _buildRecipientField('To', _toController),
                  
                  // CC/BCC toggle
                  if (!_showCcBcc)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => setState(() => _showCcBcc = true),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          minimumSize: const Size(0, 32),
                        ),
                        child: Text(
                          'Cc/Bcc',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.primaryBlue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  
                  if (_showCcBcc) ...[
                    _buildRecipientField('Cc', _ccController),
                    _buildRecipientField('Bcc', _bccController),
                  ],
                  
                  const Divider(height: 1),
                  
                  // Subject
                  TextField(
                    controller: _subjectController,
                    style: TextStyle(
                      fontSize: 15,
                      color: AppColors.getTextPrimary(context),
                    ),
                    decoration: InputDecoration(
                      labelText: 'Subject',
                      labelStyle: TextStyle(
                        color: AppColors.getTextSecondary(context),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                  const Divider(height: 1),
                  const SizedBox(height: 8),

                  // Body
                  TextField(
                    controller: _bodyController,
                    focusNode: _bodyFocusNode,
                    maxLines: null,
                    minLines: 8,
                    style: TextStyle(
                      fontSize: 15,
                      color: AppColors.getTextPrimary(context),
                      height: 1.5,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Compose email...',
                      hintStyle: TextStyle(
                        color: AppColors.getTextSecondary(context).withValues(alpha: 0.5),
                      ),
                      border: InputBorder.none,
                    ),
                  ),

                  // Attachments
                  if (_attachments.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _buildAttachmentList(),
                  ],
                ],
              ),
            ),
          ),

          // Formatting Toolbar
          _buildFormattingToolbar(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              Icons.close_rounded,
              color: AppColors.getTextPrimary(context),
            ),
          ),
          Text(
            _getTitle(),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.getTextPrimary(context),
            ),
          ),
          _isSending
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : IconButton(
                  onPressed: _handleSend,
                  icon: Icon(
                    Icons.send_rounded,
                    color: AppColors.primaryBlue,
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildRecipientField(String label, TextEditingController controller) {
    return Row(
      children: [
        SizedBox(
          width: 36,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.getTextSecondary(context),
            ),
          ),
        ),
        Expanded(
          child: TextField(
            controller: controller,
            style: TextStyle(
              fontSize: 15,
              color: AppColors.getTextPrimary(context),
            ),
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              isDense: true,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAttachmentList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Attachments (${_attachments.length})',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.getTextSecondary(context),
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _attachments.asMap().entries.map((entry) {
            final index = entry.key;
            final file = entry.value;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                  Icon(
                    _getFileIcon(file.extension ?? ''),
                    size: 18,
                    color: AppColors.primaryBlue,
                  ),
                  const SizedBox(width: 8),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 150),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          file.name,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.getTextPrimary(context),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          _formatFileSize(file.size),
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.getTextSecondary(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () => _removeAttachment(index),
                    child: Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: AppColors.getTextSecondary(context),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  IconData _getFileIcon(String ext) {
    final e = ext.toLowerCase();
    if (['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(e)) return Icons.image_rounded;
    if (e == 'pdf') return Icons.picture_as_pdf_rounded;
    if (['doc', 'docx'].contains(e)) return Icons.description_rounded;
    if (['xls', 'xlsx'].contains(e)) return Icons.table_chart_rounded;
    if (['zip', 'rar', '7z'].contains(e)) return Icons.folder_zip_rounded;
    return Icons.attach_file_rounded;
  }

  Widget _buildFormattingToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.getSurface(context),
        border: Border(
          top: BorderSide(
            color: AppColors.getTextSecondary(context).withValues(alpha: 0.15),
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            _ToolbarButton(
              icon: Icons.format_bold_rounded,
              tooltip: 'Bold',
              onTap: () => _insertFormatting('**', '**'),
            ),
            _ToolbarButton(
              icon: Icons.format_italic_rounded,
              tooltip: 'Italic',
              onTap: () => _insertFormatting('_', '_'),
            ),
            _ToolbarButton(
              icon: Icons.format_list_bulleted_rounded,
              tooltip: 'Bullet List',
              onTap: () => _insertFormatting('\n- ', ''),
            ),
            _ToolbarButton(
              icon: Icons.link_rounded,
              tooltip: 'Insert Link',
              onTap: _showInsertLinkDialog,
            ),
            const SizedBox(width: 4),
            Container(
              width: 1,
              height: 24,
              color: AppColors.getTextSecondary(context).withValues(alpha: 0.2),
            ),
            const SizedBox(width: 4),
            _ToolbarButton(
              icon: Icons.attach_file_rounded,
              tooltip: 'Attach File',
              onTap: _pickFiles,
            ),
            if (_attachments.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${_attachments.length}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            const Spacer(),
            // Formatting indicator
            if (_isFormatting)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Rich text',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryBlue,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _getTitle() {
    switch (widget.mode) {
      case ComposeMode.reply:
        return 'Reply';
      case ComposeMode.replyAll:
        return 'Reply All';
      case ComposeMode.forward:
        return 'Forward';
      case ComposeMode.compose:
        return 'New Message';
    }
  }
}

class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _ToolbarButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(
            icon,
            size: 20,
            color: AppColors.getTextSecondary(context),
          ),
        ),
      ),
    );
  }
}
