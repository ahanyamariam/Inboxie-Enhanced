import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:app/core/theme/app_colors.dart';
import 'package:app/services/storage_service.dart';
import 'package:app/models/notification_settings_model.dart';
import 'package:app/features/profile/widgets/settings_section.dart';
import 'package:app/features/profile/widgets/settings_tile.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  final StorageService _storage = StorageService();
  late NotificationSettings _settings;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _settings = _storage.getNotificationSettings();
      _isLoading = false;
    });
  }

  void _triggerHaptic() {
    if (_storage.prefs.getBool('haptic_feedback') ?? true) {
      HapticFeedback.lightImpact();
    }
  }

  Future<void> _updateSetting(
    NotificationSettings Function(NotificationSettings) updater,
  ) async {
    _triggerHaptic();
    final updated = updater(_settings);
    await _storage.setNotificationSettings(updated);
    setState(() {
      _settings = updated;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.getBackground(context),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

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
          'Notifications',
          style: TextStyle(
            color: AppColors.getTextPrimary(context),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Master Toggle
            _buildMasterToggle(),

            if (_settings.enabled) ...[
              const SizedBox(height: 20),

              // Email Priority Section
              SettingsSection(
                title: 'Email Priority',
                children: [
                  SettingsToggleTile(
                    icon: Icons.priority_high_rounded,
                    iconColor: Colors.red,
                    iconBackgroundColor: Colors.red.withValues(alpha: 0.1),
                    title: 'Urgent emails',
                    subtitle: 'Get notified immediately',
                    value: _settings.urgentEmails,
                    onChanged: (v) =>
                        _updateSetting((s) => s.copyWith(urgentEmails: v)),
                  ),
                  SettingsToggleTile(
                    icon: Icons.star_rounded,
                    iconColor: Colors.amber,
                    iconBackgroundColor: Colors.amber.withValues(alpha: 0.1),
                    title: 'Important emails',
                    subtitle: 'Notifications for important mail',
                    value: _settings.importantEmails,
                    onChanged: (v) =>
                        _updateSetting((s) => s.copyWith(importantEmails: v)),
                  ),
                  SettingsToggleTile(
                    icon: Icons.low_priority_rounded,
                    iconColor: Colors.blue,
                    iconBackgroundColor: Colors.blue.withValues(alpha: 0.1),
                    title: 'Low priority',
                    subtitle: 'Usually muted by default',
                    value: _settings.lowPriorityEmails,
                    onChanged: (v) =>
                        _updateSetting((s) => s.copyWith(lowPriorityEmails: v)),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Reminders Section
              SettingsSection(
                title: 'Smart Reminders',
                children: [
                  SettingsToggleTile(
                    icon: Icons.reply_rounded,
                    iconColor: Colors.orange,
                    iconBackgroundColor: Colors.orange.withValues(alpha: 0.1),
                    title: 'Needs Action',
                    subtitle: 'Remind me to reply',
                    value: _settings.needsActionReminders,
                    onChanged: (v) => _updateSetting(
                      (s) => s.copyWith(needsActionReminders: v),
                    ),
                  ),
                  SettingsToggleTile(
                    icon: Icons.hourglass_bottom_rounded,
                    iconColor: Colors.purple,
                    iconBackgroundColor: Colors.purple.withValues(alpha: 0.1),
                    title: 'Waiting for others',
                    subtitle: 'Follow-up reminders',
                    value: _settings.waitingFollowUps,
                    onChanged: (v) =>
                        _updateSetting((s) => s.copyWith(waitingFollowUps: v)),
                  ),
                  SettingsToggleTile(
                    icon: Icons.event_rounded,
                    iconColor: Colors.teal,
                    iconBackgroundColor: Colors.teal.withValues(alpha: 0.1),
                    title: 'Deadlines',
                    subtitle: 'Upcoming deadline alerts',
                    value: _settings.deadlineReminders,
                    onChanged: (v) =>
                        _updateSetting((s) => s.copyWith(deadlineReminders: v)),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Quiet Hours Section
              SettingsSection(
                title: 'Quiet Time',
                children: [
                  SettingsToggleTile(
                    icon: Icons.do_not_disturb_on_rounded,
                    iconColor: Colors.indigo,
                    iconBackgroundColor: Colors.indigo.withValues(alpha: 0.1),
                    title: 'Quiet Hours',
                    subtitle: 'Pause notifications at night',
                    value: _settings.quietHoursEnabled,
                    onChanged: (v) =>
                        _updateSetting((s) => s.copyWith(quietHoursEnabled: v)),
                  ),
                  if (_settings.quietHoursEnabled) ...[
                    SettingsSelectorTile(
                      icon: Icons.access_time_rounded,
                      title: 'Starts at',
                      value: _settings.quietHoursStart,
                      onTap: () => _selectTime(context, true),
                    ),
                    SettingsSelectorTile(
                      icon: Icons.access_time_filled_rounded,
                      title: 'Ends at',
                      value: _settings.quietHoursEnd,
                      onTap: () => _selectTime(context, false),
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 24),

              // Preferences Section
              SettingsSection(
                title: 'Preferences',
                children: [
                  SettingsToggleTile(
                    icon: Icons.volume_up_rounded,
                    title: 'Sound',
                    value: _settings.soundEnabled,
                    onChanged: (v) =>
                        _updateSetting((s) => s.copyWith(soundEnabled: v)),
                  ),
                  SettingsToggleTile(
                    icon: Icons.vibration_rounded,
                    title: 'Vibration',
                    value: _settings.vibrationEnabled,
                    onChanged: (v) =>
                        _updateSetting((s) => s.copyWith(vibrationEnabled: v)),
                  ),
                ],
              ),

              const SizedBox(height: 40),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMasterToggle() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _settings.enabled
              ? [AppColors.primaryBlue, AppColors.primaryBlue.withValues(alpha: 0.8)]
              : [Colors.grey[400]!, Colors.grey[500]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: (_settings.enabled ? AppColors.primaryBlue : Colors.grey)
                .withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Colors.white24,
              shape: BoxShape.circle,
            ),
            child: Icon(
              _settings.enabled
                  ? Icons.notifications_active_rounded
                  : Icons.notifications_off_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Push Notifications',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  _settings.enabled ? 'Currently enabled' : 'Mutually disabled',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: _settings.enabled,
            onChanged: (v) => _updateSetting((s) => s.copyWith(enabled: v)),
            activeTrackColor: Colors.white.withValues(alpha: 0.4),
            thumbColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return Colors.white;
              }
              return null;
            }),
          ),
        ],
      ),
    );
  }

  Future<void> _selectTime(BuildContext context, bool isStart) async {
    final currentTime = isStart
        ? _settings.quietHoursStart
        : _settings.quietHoursEnd;
    final parts = currentTime.split(':');
    final initialTime = TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primaryBlue,
              onPrimary: Colors.white,
              surface: AppColors.getSurface(context),
              onSurface: AppColors.getTextPrimary(context),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final formattedTime =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      _updateSetting(
        (s) => isStart
            ? s.copyWith(quietHoursStart: formattedTime)
            : s.copyWith(quietHoursEnd: formattedTime),
      );
    }
  }
}
