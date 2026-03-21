import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:app/core/theme/app_colors.dart';
import 'package:app/services/storage_service.dart';
import 'package:app/models/bucket_config_model.dart';

class BucketCustomizationScreen extends StatefulWidget {
  const BucketCustomizationScreen({super.key});

  @override
  State<BucketCustomizationScreen> createState() =>
      _BucketCustomizationScreenState();
}

class _BucketCustomizationScreenState extends State<BucketCustomizationScreen> {
  final StorageService _storage = StorageService();
  late BucketConfig _config;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  void _loadConfig() {
    setState(() {
      _config = _storage.getBucketConfig();
    });
  }

  void _triggerHaptic() {
    HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    final sortedBuckets = _config.sortedBuckets;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_rounded,
            color: Color(0xFF1A1A2E),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Customize Buckets',
          style: TextStyle(
            color: Color(0xFF1A1A2E),
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.restore_rounded,
              color: Color(0xFF6B7280),
            ),
            tooltip: 'Reset to defaults',
            onPressed: _showResetConfirmation,
          ),
        ],
      ),
      body: Column(
        children: [
          // Info Card
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFE0E0E0),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: AppColors.primaryBlue,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Drag to reorder • Tap icon to change • Toggle visibility',
                      style: TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Reorderable List
          Expanded(
            child: ReorderableListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: sortedBuckets.length,
              onReorder: (oldIndex, newIndex) async {
                _triggerHaptic();
                await _storage.reorderBuckets(oldIndex, newIndex);
                _loadConfig();
              },
              proxyDecorator: (child, index, animation) {
                return AnimatedBuilder(
                  animation: animation,
                  builder: (context, child) {
                    return Material(
                      elevation: 4,
                      borderRadius: BorderRadius.circular(12),
                      shadowColor: Colors.black.withValues(alpha: 0.2),
                      child: child,
                    );
                  },
                  child: child,
                );
              },
              itemBuilder: (context, index) {
                final bucket = sortedBuckets[index];
                return _BucketTile(
                  key: ValueKey(bucket.id),
                  bucket: bucket,
                  index: index,
                  onRename: () => _showRenameDialog(bucket),
                  onIconChange: () => _showIconPicker(bucket),
                  onToggleVisibility: () async {
                    _triggerHaptic();
                    await _storage.toggleBucketVisibility(bucket.id);
                    _loadConfig();
                  },
                );
              },
            ),
          ),

          // Preview Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(
                  color: const Color(0xFFE0E0E0),
                  width: 1,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tab Preview',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 12),
                _buildTabPreview(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabPreview() {
    final visibleBuckets = _config.visibleBuckets;

    if (visibleBuckets.isEmpty) {
      return Center(
        child: Text(
          'No buckets visible',
          style: TextStyle(color: Colors.red[400]),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: visibleBuckets.map((bucket) {
          return Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE0E0E0)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  BucketIcons.getIcon(bucket.icon),
                  size: 16,
                  color: const Color(0xFF1A1A2E),
                ),
                const SizedBox(width: 6),
                Text(
                  bucket.name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Future<void> _showRenameDialog(BucketItem bucket) async {
    _triggerHaptic();
    final controller = TextEditingController(text: bucket.name);

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Rename Bucket',
          style: TextStyle(color: Color(0xFF1A1A2E)),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 25,
          textCapitalization: TextCapitalization.words,
          style: const TextStyle(color: Color(0xFF1A1A2E)),
          decoration: InputDecoration(
            labelText: 'Bucket name',
            labelStyle: const TextStyle(color: Color(0xFF6B7280)),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.primaryBlue, width: 2),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF6B7280)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            style: TextButton.styleFrom(foregroundColor: AppColors.primaryBlue),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      await _storage.renameBucket(bucket.id, result);
      _loadConfig();
    }
  }

  void _showIconPicker(BucketItem bucket) {
    _triggerHaptic();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0E0E0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Choose Icon',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 20),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
              ),
              itemCount: BucketIcons.availableIcons.length,
              itemBuilder: (context, index) {
                final iconName = BucketIcons.availableIcons[index];
                final isSelected = bucket.icon == iconName;

                return GestureDetector(
                  onTap: () async {
                    _triggerHaptic();
                    await _storage.updateBucketIcon(bucket.id, iconName);
                    _loadConfig();
                    if (!context.mounted) return;
                    Navigator.pop(context);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primaryBlue
                          : const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primaryBlue
                            : const Color(0xFFE0E0E0),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Icon(
                      BucketIcons.getIcon(iconName),
                      color: isSelected ? Colors.white : const Color(0xFF1A1A2E),
                      size: 24,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showResetConfirmation() {
    _triggerHaptic();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Reset to Defaults?',
          style: TextStyle(color: Color(0xFF1A1A2E)),
        ),
        content: const Text(
          'This will reset all bucket names, icons, order, and visibility.',
          style: TextStyle(color: Color(0xFF6B7280)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF6B7280)),
            ),
          ),
          TextButton(
            onPressed: () async {
              await _storage.resetBucketConfig();
              _loadConfig();
              if (!context.mounted) return;
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Buckets reset to defaults'),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}

class _BucketTile extends StatelessWidget {
  final BucketItem bucket;
  final int index;
  final VoidCallback onRename;
  final VoidCallback onIconChange;
  final VoidCallback onToggleVisibility;

  const _BucketTile({
    super.key,
    required this.bucket,
    required this.index,
    required this.onRename,
    required this.onIconChange,
    required this.onToggleVisibility,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE0E0E0),
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ReorderableDragStartListener(
              index: index,
              child: const Icon(
                Icons.drag_handle_rounded,
                color: Color(0xFF6B7280),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onIconChange,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: bucket.isVisible
                      ? const Color(0xFFF5F5F5)
                      : const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFFE0E0E0),
                    width: 1,
                  ),
                ),
                child: Icon(
                  BucketIcons.getIcon(bucket.icon),
                  color: bucket.isVisible
                      ? const Color(0xFF1A1A2E)
                      : const Color(0xFF6B7280),
                ),
              ),
            ),
          ],
        ),
        title: Text(
          bucket.name,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: bucket.isVisible
                ? const Color(0xFF1A1A2E)
                : const Color(0xFF6B7280),
            decoration: bucket.isVisible ? null : TextDecoration.lineThrough,
          ),
        ),
        subtitle: Text(
          bucket.isVisible ? 'Visible in tabs' : 'Hidden',
          style: TextStyle(
            fontSize: 12,
            color: bucket.isVisible
                ? const Color(0xFF6B7280)
                : Colors.red.withValues(alpha: 0.7),
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(
                Icons.edit_rounded,
                color: Color(0xFF6B7280),
                size: 20,
              ),
              onPressed: onRename,
            ),
            Switch.adaptive(
              value: bucket.isVisible,
              onChanged: (_) => onToggleVisibility(),
              activeTrackColor: AppColors.primaryBlue,
            ),
          ],
        ),
      ),
    );
  }
}
