class NotificationSettings {
  final bool enabled;
  final bool urgentEmails;
  final bool importantEmails;
  final bool lowPriorityEmails;
  final bool needsActionReminders;
  final bool waitingFollowUps;
  final bool deadlineReminders;
  final int reminderFrequencyHours;
  final bool quietHoursEnabled;
  final String quietHoursStart;
  final String quietHoursEnd;
  final bool soundEnabled;
  final bool vibrationEnabled;
  final bool dailyDigestEnabled;
  final String dailyDigestTime;

  const NotificationSettings({
    this.enabled = true,
    this.urgentEmails = true,
    this.importantEmails = true,
    this.lowPriorityEmails = false,
    this.needsActionReminders = true,
    this.waitingFollowUps = true,
    this.deadlineReminders = true,
    this.reminderFrequencyHours = 24,
    this.quietHoursEnabled = false,
    this.quietHoursStart = '22:00',
    this.quietHoursEnd = '07:00',
    this.soundEnabled = true,
    this.vibrationEnabled = true,
    this.dailyDigestEnabled = false,
    this.dailyDigestTime = '08:00',
  });

  NotificationSettings copyWith({
    bool? enabled,
    bool? urgentEmails,
    bool? importantEmails,
    bool? lowPriorityEmails,
    bool? needsActionReminders,
    bool? waitingFollowUps,
    bool? deadlineReminders,
    int? reminderFrequencyHours,
    bool? quietHoursEnabled,
    String? quietHoursStart,
    String? quietHoursEnd,
    bool? soundEnabled,
    bool? vibrationEnabled,
    bool? dailyDigestEnabled,
    String? dailyDigestTime,
  }) {
    return NotificationSettings(
      enabled: enabled ?? this.enabled,
      urgentEmails: urgentEmails ?? this.urgentEmails,
      importantEmails: importantEmails ?? this.importantEmails,
      lowPriorityEmails: lowPriorityEmails ?? this.lowPriorityEmails,
      needsActionReminders: needsActionReminders ?? this.needsActionReminders,
      waitingFollowUps: waitingFollowUps ?? this.waitingFollowUps,
      deadlineReminders: deadlineReminders ?? this.deadlineReminders,
      reminderFrequencyHours: reminderFrequencyHours ?? this.reminderFrequencyHours,
      quietHoursEnabled: quietHoursEnabled ?? this.quietHoursEnabled,
      quietHoursStart: quietHoursStart ?? this.quietHoursStart,
      quietHoursEnd: quietHoursEnd ?? this.quietHoursEnd,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      dailyDigestEnabled: dailyDigestEnabled ?? this.dailyDigestEnabled,
      dailyDigestTime: dailyDigestTime ?? this.dailyDigestTime,
    );
  }

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'urgentEmails': urgentEmails,
        'importantEmails': importantEmails,
        'lowPriorityEmails': lowPriorityEmails,
        'needsActionReminders': needsActionReminders,
        'waitingFollowUps': waitingFollowUps,
        'deadlineReminders': deadlineReminders,
        'reminderFrequencyHours': reminderFrequencyHours,
        'quietHoursEnabled': quietHoursEnabled,
        'quietHoursStart': quietHoursStart,
        'quietHoursEnd': quietHoursEnd,
        'soundEnabled': soundEnabled,
        'vibrationEnabled': vibrationEnabled,
        'dailyDigestEnabled': dailyDigestEnabled,
        'dailyDigestTime': dailyDigestTime,
      };

  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    return NotificationSettings(
      enabled: json['enabled'] ?? true,
      urgentEmails: json['urgentEmails'] ?? true,
      importantEmails: json['importantEmails'] ?? true,
      lowPriorityEmails: json['lowPriorityEmails'] ?? false,
      needsActionReminders: json['needsActionReminders'] ?? true,
      waitingFollowUps: json['waitingFollowUps'] ?? true,
      deadlineReminders: json['deadlineReminders'] ?? true,
      reminderFrequencyHours: json['reminderFrequencyHours'] ?? 24,
      quietHoursEnabled: json['quietHoursEnabled'] ?? false,
      quietHoursStart: json['quietHoursStart'] ?? '22:00',
      quietHoursEnd: json['quietHoursEnd'] ?? '07:00',
      soundEnabled: json['soundEnabled'] ?? true,
      vibrationEnabled: json['vibrationEnabled'] ?? true,
      dailyDigestEnabled: json['dailyDigestEnabled'] ?? false,
      dailyDigestTime: json['dailyDigestTime'] ?? '08:00',
    );
  }

  String get reminderFrequencyLabel {
    switch (reminderFrequencyHours) {
      case 1:
        return '1 hour';
      case 4:
        return '4 hours';
      case 12:
        return '12 hours';
      case 24:
        return '24 hours';
      case 48:
        return '48 hours';
      default:
        return '$reminderFrequencyHours hours';
    }
  }
}