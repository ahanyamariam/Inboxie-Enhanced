enum PrioritySensitivity { low, normal, high }

enum PrivacyMode { none, summary, full }

enum SyncFrequency { fiveMin, fifteenMin, thirtyMin, manual }

class UserSettingsModel {
  // Profile info
  final String? uid;
  final String? email;
  final String? displayName;
  final String? photoUrl;

  // Intelligence Settings
  final PrioritySensitivity prioritySensitivity;
  final bool smartDetectionEnabled;

  // Privacy Settings
  final PrivacyMode privacyMode;

  // Email Preferences
  final bool newsletterDigestEnabled;
  final bool autoArchiveEnabled;
  final SyncFrequency syncFrequency;

  // Sender Lists
  final List<String> vipSenders;
  final List<String> mutedSenders;

  // App Settings
  final String themeMode;
  final String defaultTab;
  final bool hapticFeedbackEnabled;

  const UserSettingsModel({
    this.uid,
    this.email,
    this.displayName,
    this.photoUrl,
    this.prioritySensitivity = PrioritySensitivity.normal,
    this.smartDetectionEnabled = true,
    this.privacyMode = PrivacyMode.summary,
    this.newsletterDigestEnabled = true,
    this.autoArchiveEnabled = false,
    this.syncFrequency = SyncFrequency.fifteenMin,
    this.vipSenders = const [],
    this.mutedSenders = const [],
    this.themeMode = 'system',
    this.defaultTab = 'action',
    this.hapticFeedbackEnabled = true,
  });

  UserSettingsModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoUrl,
    PrioritySensitivity? prioritySensitivity,
    bool? smartDetectionEnabled,
    PrivacyMode? privacyMode,
    bool? newsletterDigestEnabled,
    bool? autoArchiveEnabled,
    SyncFrequency? syncFrequency,
    List<String>? vipSenders,
    List<String>? mutedSenders,
    String? themeMode,
    String? defaultTab,
    bool? hapticFeedbackEnabled,
  }) {
    return UserSettingsModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      prioritySensitivity: prioritySensitivity ?? this.prioritySensitivity,
      smartDetectionEnabled: smartDetectionEnabled ?? this.smartDetectionEnabled,
      privacyMode: privacyMode ?? this.privacyMode,
      newsletterDigestEnabled: newsletterDigestEnabled ?? this.newsletterDigestEnabled,
      autoArchiveEnabled: autoArchiveEnabled ?? this.autoArchiveEnabled,
      syncFrequency: syncFrequency ?? this.syncFrequency,
      vipSenders: vipSenders ?? this.vipSenders,
      mutedSenders: mutedSenders ?? this.mutedSenders,
      themeMode: themeMode ?? this.themeMode,
      defaultTab: defaultTab ?? this.defaultTab,
      hapticFeedbackEnabled: hapticFeedbackEnabled ?? this.hapticFeedbackEnabled,
    );
  }

  // Helper methods for display
  String get prioritySensitivityLabel {
    switch (prioritySensitivity) {
      case PrioritySensitivity.low:
        return 'Low';
      case PrioritySensitivity.normal:
        return 'Normal';
      case PrioritySensitivity.high:
        return 'High';
    }
  }

  String get privacyModeLabel {
    switch (privacyMode) {
      case PrivacyMode.none:
        return 'None';
      case PrivacyMode.summary:
        return 'Summaries Only';
      case PrivacyMode.full:
        return 'Full Content';
    }
  }

  String get privacyModeDescription {
    switch (privacyMode) {
      case PrivacyMode.none:
        return 'No email content stored locally';
      case PrivacyMode.summary:
        return 'Only AI-generated summaries stored';
      case PrivacyMode.full:
        return 'Full email content cached locally';
    }
  }

  String get syncFrequencyLabel {
    switch (syncFrequency) {
      case SyncFrequency.fiveMin:
        return '5 minutes';
      case SyncFrequency.fifteenMin:
        return '15 minutes';
      case SyncFrequency.thirtyMin:
        return '30 minutes';
      case SyncFrequency.manual:
        return 'Manual only';
    }
  }

  String get themeModeLabel {
    switch (themeMode) {
      case 'light':
        return 'Light';
      case 'dark':
        return 'Dark';
      default:
        return 'System';
    }
  }

  String get defaultTabLabel {
    switch (defaultTab) {
      case 'all':
        return 'All Emails';
      case 'urgent':
        return 'Urgent';
      default:
        return 'Action';
    }
  }
}