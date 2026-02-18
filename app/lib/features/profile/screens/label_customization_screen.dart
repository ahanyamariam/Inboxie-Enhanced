import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:app/core/theme/app_colors.dart';
import 'package:app/services/storage_service.dart';
import 'package:app/models/label_config_model.dart';

class LabelCustomizationScreen extends StatefulWidget {
  const LabelCustomizationScreen({super.key});

  @override
  State<LabelCustomizationScreen> createState() =>
      _LabelCustomizationScreenState();
}

class _LabelCustomizationScreenState extends State<LabelCustomizationScreen> {
  final StorageService _storage = StorageService();
  late LabelConfig _config;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  void _loadConfig() {
    setState(() {
      _config = _storage.getLabelConfig();
    });
  }

  void _triggerHaptic() {
    HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      appBar: AppBar(
        backgroundColor: AppColors.getBackground(context),
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_rounded,
            color: AppColors.getTextPrimary(context),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Customize Labels',
          style: TextStyle(
            color: AppColors.getTextPrimary(context),
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.restore_rounded,
              color: AppColors.getTextSecondary(context),
            ),
            tooltip: 'Reset to defaults',
            onPressed: _showResetConfirmation,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info Card
            _buildInfoCard(),
            const SizedBox(height: 24),

            // Priority Labels Section
            _buildSectionHeader('Priority Labels', Icons.flag_rounded),
            const SizedBox(height: 12),
            _buildLabelTile(
              label: 'Urgent',
              currentValue: _config.urgentLabel,
              color: _config.getPriorityColor('urgent'),
              onLabelChanged: (value) async {
                await _storage.updatePriorityLabel('urgent', value);
                _loadConfig();
              },
              onColorChanged: (color) async {
                await _storage.updatePriorityColor(
                  'urgent',
                  LabelConfig.colorToHex(color),
                );
                _loadConfig();
              },
            ),
            _buildLabelTile(
              label: 'Important',
              currentValue: _config.importantLabel,
              color: _config.getPriorityColor('important'),
              onLabelChanged: (value) async {
                await _storage.updatePriorityLabel('important', value);
                _loadConfig();
              },
              onColorChanged: (color) async {
                await _storage.updatePriorityColor(
                  'important',
                  LabelConfig.colorToHex(color),
                );
                _loadConfig();
              },
            ),
            _buildLabelTile(
              label: 'Low',
              currentValue: _config.lowLabel,
              color: _config.getPriorityColor('low'),
              onLabelChanged: (value) async {
                await _storage.updatePriorityLabel('low', value);
                _loadConfig();
              },
              onColorChanged: (color) async {
                await _storage.updatePriorityColor(
                  'low',
                  LabelConfig.colorToHex(color),
                );
                _loadConfig();
              },
            ),

            const SizedBox(height: 32),

            // Action Labels Section
            _buildSectionHeader('Action Labels', Icons.label_rounded),
            const SizedBox(height: 12),
            _buildLabelTile(
              label: 'Needs Reply',
              currentValue: _config.needsReplyLabel,
              color: _config.getActionColor('needs_reply'),
              onLabelChanged: (value) async {
                await _storage.updateActionLabel('needs_reply', value);
                _loadConfig();
              },
              onColorChanged: (color) async {
                await _storage.updateActionColor(
                  'needs_reply',
                  LabelConfig.colorToHex(color),
                );
                _loadConfig();
              },
            ),
            _buildLabelTile(
              label: 'Waiting',
              currentValue: _config.waitingLabel,
              color: _config.getActionColor('waiting'),
              onLabelChanged: (value) async {
                await _storage.updateActionLabel('waiting', value);
                _loadConfig();
              },
              onColorChanged: (color) async {
                await _storage.updateActionColor(
                  'waiting',
                  LabelConfig.colorToHex(color),
                );
                _loadConfig();
              },
            ),
            _buildLabelTile(
              label: 'No Action',
              currentValue: _config.noActionLabel,
              color: _config.getActionColor('no_action'),
              onLabelChanged: (value) async {
                await _storage.updateActionLabel('no_action', value);
                _loadConfig();
              },
              onColorChanged: (color) async {
                await _storage.updateActionColor(
                  'no_action',
                  LabelConfig.colorToHex(color),
                );
                _loadConfig();
              },
            ),

            const SizedBox(height: 32),

            // Preview Section
            _buildSectionHeader('Preview', Icons.visibility_rounded),
            const SizedBox(height: 12),
            _buildPreviewCard(),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryBlue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryBlue.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: AppColors.primaryBlue),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Customize how labels appear throughout the app. Tap the color to change it, or tap edit to rename.',
              style: TextStyle(
                color: AppColors.getTextSecondary(context),
                fontSize: 13,
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
        Icon(icon, size: 20, color: AppColors.primaryBlue),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.getTextPrimary(context),
          ),
        ),
      ],
    );
  }

  Widget _buildLabelTile({
    required String label,
    required String currentValue,
    required Color color,
    required Function(String) onLabelChanged,
    required Function(Color) onColorChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.getSurface(context),
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppColors.isDark(context)
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: GestureDetector(
          onTap: () {
            _triggerHaptic();
            _showColorPicker(color, onColorChanged);
          },
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.colorize_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
        ),
        title: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.getTextPrimary(context),
          ),
        ),
        subtitle: Text(
          'Currently: $currentValue',
          style: TextStyle(
            color: AppColors.getTextSecondary(context),
            fontSize: 12,
          ),
        ),
        trailing: IconButton(
          icon: Icon(
            Icons.edit_rounded,
            color: AppColors.getTextSecondary(context),
          ),
          onPressed: () {
            _triggerHaptic();
            _showEditDialog(label, currentValue, onLabelChanged);
          },
        ),
      ),
    );
  }

  Widget _buildPreviewCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.getSurface(context),
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppColors.isDark(context)
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How your labels will appear:',
            style: TextStyle(
              color: AppColors.getTextSecondary(context),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildPreviewChip(
                _config.urgentLabel,
                _config.getPriorityColor('urgent'),
              ),
              _buildPreviewChip(
                _config.importantLabel,
                _config.getPriorityColor('important'),
              ),
              _buildPreviewChip(
                _config.lowLabel,
                _config.getPriorityColor('low'),
              ),
              _buildPreviewChip(
                _config.needsReplyLabel,
                _config.getActionColor('needs_reply'),
              ),
              _buildPreviewChip(
                _config.waitingLabel,
                _config.getActionColor('waiting'),
              ),
              _buildPreviewChip(
                _config.noActionLabel,
                _config.getActionColor('no_action'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  Future<void> _showEditDialog(
    String label,
    String currentValue,
    Function(String) onChanged,
  ) async {
    final controller = TextEditingController(text: currentValue);
    final isDark = AppColors.isDark(context);

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.getSurface(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Edit "$label" Label',
          style: TextStyle(color: AppColors.getTextPrimary(context)),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 20,
          textCapitalization: TextCapitalization.words,
          style: TextStyle(color: AppColors.getTextPrimary(context)),
          decoration: InputDecoration(
            labelText: 'Label name',
            labelStyle: TextStyle(color: AppColors.getTextSecondary(context)),
            hintText: 'Enter custom label',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.primaryBlue, width: 2),
            ),
            suffixIcon: IconButton(
              icon: Icon(
                Icons.clear,
                color: AppColors.getTextSecondary(context),
              ),
              onPressed: () => controller.clear(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDark ? Colors.white70 : AppColors.textSecondary,
              ),
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
      onChanged(result);
    }
  }

  void _showColorPicker(Color currentColor, Function(Color) onChanged) {
    final colors = [
      Colors.red,
      Colors.pink,
      Colors.purple,
      Colors.deepPurple,
      Colors.indigo,
      Colors.blue,
      Colors.lightBlue,
      Colors.cyan,
      Colors.teal,
      Colors.green,
      Colors.lightGreen,
      Colors.lime,
      Colors.yellow,
      Colors.amber,
      Colors.orange,
      Colors.deepOrange,
      Colors.brown,
      Colors.grey,
      Colors.blueGrey,
      AppColors.primaryBlue,
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.getSurface(context),
          borderRadius: const BorderRadius.only(
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
                  color: AppColors.isDark(context)
                      ? Colors.white24
                      : Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Choose Color',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.getTextPrimary(context),
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
              itemCount: colors.length,
              itemBuilder: (context, index) {
                final color = colors[index];
                final isSelected = color.toARGB32() == currentColor.toARGB32();

                return GestureDetector(
                  onTap: () {
                    _triggerHaptic();
                    onChanged(color);
                    Navigator.pop(context);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? Colors.white : Colors.transparent,
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: isSelected
                        ? const Icon(Icons.check_rounded, color: Colors.white)
                        : null,
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
    final isDark = AppColors.isDark(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.getSurface(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Reset to Defaults?',
          style: TextStyle(color: AppColors.getTextPrimary(context)),
        ),
        content: Text(
          'This will reset all label names and colors to their default values.',
          style: TextStyle(color: AppColors.getTextSecondary(context)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDark ? Colors.white70 : AppColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              await _storage.resetLabelConfig();
              _loadConfig();
              if (!context.mounted) return;
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Labels reset to defaults'),
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
