import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:app/core/theme/app_colors.dart';
import 'package:app/services/storage_service.dart';
import 'package:app/models/email_label_model.dart';

class EmailLabelManagementScreen extends StatefulWidget {
  const EmailLabelManagementScreen({super.key});

  @override
  State<EmailLabelManagementScreen> createState() =>
      _EmailLabelManagementScreenState();
}

class _EmailLabelManagementScreenState
    extends State<EmailLabelManagementScreen> {
  final StorageService _storage = StorageService();
  List<EmailLabel> _customLabels = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLabels();
  }

  void _loadLabels() {
    setState(() {
      _customLabels = _storage.getCustomLabels();
      _isLoading = false;
    });
  }

  void _triggerHaptic() {
    HapticFeedback.lightImpact();
  }

  Future<void> _addLabel() async {
    _triggerHaptic();
    final result = await _showEditLabelDialog(null);
    if (result != null) {
      await _storage.addCustomLabel(result);
      _loadLabels();
    }
  }

  Future<void> _editLabel(EmailLabel label) async {
    _triggerHaptic();
    final result = await _showEditLabelDialog(label);
    if (result != null) {
      await _storage.updateCustomLabel(result);
      _loadLabels();
    }
  }

  Future<void> _deleteLabel(EmailLabel label) async {
    _triggerHaptic();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.getSurface(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete "${label.name}"?',
          style: TextStyle(color: AppColors.getTextPrimary(context)),
        ),
        content: Text(
          'This custom label will be removed. Existing emails classified with it will keep their label.',
          style: TextStyle(color: AppColors.getTextSecondary(context)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.getTextSecondary(context)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _storage.removeCustomLabel(label.id);
      _loadLabels();
    }
  }

  Future<EmailLabel?> _showEditLabelDialog(EmailLabel? existing) async {
    final nameController =
        TextEditingController(text: existing?.name ?? '');
    final keywordsController =
        TextEditingController(text: existing?.keywords.join(', ') ?? '');
    String selectedBucket = existing?.bucketId ?? 'inbox';
    String selectedColor = existing?.color ?? '#6B7280';

    final bucketOptions = [
      'important',
      'needs_reply',
      'transactions',
      'events',
      'promotions',
      'updates',
      'inbox',
    ];

    final colorOptions = [
      '#DC2626', '#F59E0B', '#3B82F6', '#8B5CF6',
      '#EC4899', '#F97316', '#14B8A6', '#6B7280',
      '#10B981', '#EF4444', '#6366F1', '#84CC16',
    ];

    return await showDialog<EmailLabel>(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: AppColors.getSurface(context),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              existing != null ? 'Edit Label' : 'New Custom Label',
              style: TextStyle(
                color: AppColors.getTextPrimary(context),
                fontWeight: FontWeight.w700,
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Label Name',
                      labelStyle: TextStyle(
                        color: AppColors.getTextSecondary(context),
                      ),
                      filled: true,
                      fillColor: AppColors.getCard(context),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    style: TextStyle(
                      color: AppColors.getTextPrimary(context),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Keywords
                  TextField(
                    controller: keywordsController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Keywords (comma-separated)',
                      helperText:
                          'e.g.: project update, standup, sprint review',
                      helperMaxLines: 2,
                      labelStyle: TextStyle(
                        color: AppColors.getTextSecondary(context),
                      ),
                      helperStyle: TextStyle(
                        color: AppColors.getTextMuted(context),
                        fontSize: 12,
                      ),
                      filled: true,
                      fillColor: AppColors.getCard(context),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    style: TextStyle(
                      color: AppColors.getTextPrimary(context),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Bucket
                  Text(
                    'Target Bucket',
                    style: TextStyle(
                      color: AppColors.getTextSecondary(context),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.getCard(context),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedBucket,
                        isExpanded: true,
                        dropdownColor: AppColors.getSurface(context),
                        style: TextStyle(
                          color: AppColors.getTextPrimary(context),
                        ),
                        items: bucketOptions.map((b) {
                          return DropdownMenuItem(
                            value: b,
                            child: Text(_bucketDisplayName(b)),
                          );
                        }).toList(),
                        onChanged: (v) {
                          setDialogState(() => selectedBucket = v!);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Color
                  Text(
                    'Color',
                    style: TextStyle(
                      color: AppColors.getTextSecondary(context),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: colorOptions.map((hex) {
                      final isSelected = selectedColor == hex;
                      String cleanHex = hex.replaceFirst('#', '');
                      if (cleanHex.length == 6) cleanHex = 'FF$cleanHex';
                      final color =
                          Color(int.parse(cleanHex, radix: 16));

                      return GestureDetector(
                        onTap: () {
                          setDialogState(() => selectedColor = hex);
                        },
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: isSelected
                                ? Border.all(color: Colors.white, width: 3)
                                : null,
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: color.withValues(alpha: 0.5),
                                      blurRadius: 8,
                                    )
                                  ]
                                : null,
                          ),
                          child: isSelected
                              ? const Icon(Icons.check,
                                  color: Colors.white, size: 18)
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, null),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: AppColors.getTextSecondary(context),
                  ),
                ),
              ),
              FilledButton(
                onPressed: () {
                  final name = nameController.text.trim();
                  if (name.isEmpty) return;
                  final keywords = keywordsController.text
                      .split(',')
                      .map((k) => k.trim())
                      .where((k) => k.isNotEmpty)
                      .toList();
                  final id = existing?.id ??
                      name.toLowerCase().replaceAll(' ', '_');
                  Navigator.pop(
                    context,
                    EmailLabel(
                      id: id,
                      name: name,
                      color: selectedColor,
                      keywords: keywords,
                      bucketId: selectedBucket,
                      isDefault: false,
                    ),
                  );
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(existing != null ? 'Save' : 'Add'),
              ),
            ],
          );
        });
      },
    );
  }

  String _bucketDisplayName(String id) {
    switch (id) {
      case 'important': return 'Important';
      case 'needs_reply': return 'Needs Reply';
      case 'transactions': return 'Transactions';
      case 'events': return 'Events';
      case 'promotions': return 'Promotions';
      case 'updates': return 'Updates';
      case 'inbox': return 'Inbox';
      default: return id;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      body: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 16,
              left: 20,
              right: 20,
              bottom: 20,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [const Color(0xFF062E62), const Color(0xFF083E84)]
                    : [const Color(0xFF083E84), const Color(0xFF0a4da3)],
              ),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.15),
                    ),
                    child: const Icon(Icons.arrow_back_rounded,
                        color: Colors.white, size: 22),
                  ),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.category_rounded,
                    color: AppColors.accentYellow, size: 26),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Email Classifications',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Text(
                        'Manage how emails are categorized',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryBlue,
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Default labels section
                        _buildSectionHeader(
                            'Default Labels', Icons.label_rounded),
                        const SizedBox(height: 12),
                        ...DefaultLabels.all.map(
                          (label) => _buildLabelCard(label, isDefault: true),
                        ),

                        const SizedBox(height: 28),

                        // Custom labels section
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            _buildSectionHeader(
                                'Custom Labels', Icons.add_circle_rounded),
                            GestureDetector(
                              onTap: _addLabel,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryBlue,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.add_rounded,
                                        color: Colors.white, size: 18),
                                    SizedBox(width: 4),
                                    Text(
                                      'Add',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        if (_customLabels.isEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: AppColors.getCard(context),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.getDivider(context),
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.label_outline_rounded,
                                  size: 48,
                                  color: AppColors.getTextMuted(context),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'No custom labels yet',
                                  style: TextStyle(
                                    color:
                                        AppColors.getTextSecondary(context),
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Create labels to classify emails your way',
                                  style: TextStyle(
                                    color: AppColors.getTextMuted(context),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          ..._customLabels.map(
                            (label) =>
                                _buildLabelCard(label, isDefault: false),
                          ),

                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primaryBlue, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            color: AppColors.getTextPrimary(context),
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildLabelCard(EmailLabel label, {required bool isDefault}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.getCard(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.getDivider(context)),
      ),
      child: Row(
        children: [
          // Color dot
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: label.displayColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 14),

          // Label info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      label.name,
                      style: TextStyle(
                        color: AppColors.getTextPrimary(context),
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (isDefault) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'DEFAULT',
                          style: TextStyle(
                            color: AppColors.primaryBlue,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Bucket: ${_bucketDisplayName(label.bucketId)}',
                  style: TextStyle(
                    color: AppColors.getTextSecondary(context),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (label.keywords.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    label.keywords.take(4).join(', ') +
                        (label.keywords.length > 4
                            ? ' +${label.keywords.length - 4} more'
                            : ''),
                    style: TextStyle(
                      color: AppColors.getTextMuted(context),
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),

          // Actions (only for custom labels)
          if (!isDefault) ...[
            IconButton(
              icon: Icon(Icons.edit_rounded,
                  color: AppColors.getTextSecondary(context), size: 20),
              onPressed: () => _editLabel(label),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded,
                  color: Colors.red, size: 20),
              onPressed: () => _deleteLabel(label),
            ),
          ],
        ],
      ),
    );
  }
}
