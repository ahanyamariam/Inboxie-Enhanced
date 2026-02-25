import 'package:flutter/material.dart';

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
  final Function(String to, String subject, String body) onSend;

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
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();
  bool _isSending = false;

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
            ...msg.to.where(
              (e) => !e.contains('me'),
            ), // Exclude self if possible, simplify for now
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
              '${msg.snippet}'; // Ideally full body, but using snippet for now
          break;

        case ComposeMode.compose:
          break;
      }
    }
  }

  @override
  void dispose() {
    _toController.dispose();
    _subjectController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _handleSend() async {
    if (_toController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please add a recipient')));
      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      await widget.onSend(
        _toController.text,
        _subjectController.text,
        _bodyController.text,
      );
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                Text(
                  _getTitle(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextButton(
                  onPressed: _isSending ? null : _handleSend,
                  child: _isSending
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(
                          'Send',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Fields
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: _toController,
                    decoration: const InputDecoration(
                      labelText: 'To',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                  const Divider(height: 1),
                  TextField(
                    controller: _subjectController,
                    decoration: const InputDecoration(
                      labelText: 'Subject',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                  const Divider(height: 1),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _bodyController,
                    maxLines: null,
                    minLines: 10,
                    decoration: const InputDecoration(
                      hintText: 'Compose email',
                      border: InputBorder.none,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
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
