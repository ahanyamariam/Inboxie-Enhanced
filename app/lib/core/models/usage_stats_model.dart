class UsageStats {
  final int totalEmailsProcessed;
  final int needsActionSurfaced;
  final int repliesSent;
  final int emailsSnoozed;
  final int emailsMarkedDone;
  final int newslettersFiltered;
  final int lowValueFiltered;
  final int deadlinesDetected;
  final int questionsDetected;
  final int minutesSaved;
  final DateTime? firstUsed;
  final DateTime? lastSync;
  final Map<String, int> dailyActions;

  const UsageStats({
    this.totalEmailsProcessed = 0,
    this.needsActionSurfaced = 0,
    this.repliesSent = 0,
    this.emailsSnoozed = 0,
    this.emailsMarkedDone = 0,
    this.newslettersFiltered = 0,
    this.lowValueFiltered = 0,
    this.deadlinesDetected = 0,
    this.questionsDetected = 0,
    this.minutesSaved = 0,
    this.firstUsed,
    this.lastSync,
    this.dailyActions = const {},
  });

  int get actionsTaken => repliesSent + emailsSnoozed + emailsMarkedDone;

  double get clearanceRate {
    if (needsActionSurfaced == 0) return 0;
    return (emailsMarkedDone + repliesSent) / needsActionSurfaced * 100;
  }

  String get formattedTimeSaved {
    if (minutesSaved < 60) return '$minutesSaved mins';
    final hours = minutesSaved ~/ 60;
    final mins = minutesSaved % 60;
    if (mins == 0) return '$hours hrs';
    return '$hours hrs $mins mins';
  }

  int get daysUsed {
    if (firstUsed == null) return 0;
    return DateTime.now().difference(firstUsed!).inDays + 1;
  }

  UsageStats copyWith({
    int? totalEmailsProcessed,
    int? needsActionSurfaced,
    int? repliesSent,
    int? emailsSnoozed,
    int? emailsMarkedDone,
    int? newslettersFiltered,
    int? lowValueFiltered,
    int? deadlinesDetected,
    int? questionsDetected,
    int? minutesSaved,
    DateTime? firstUsed,
    DateTime? lastSync,
    Map<String, int>? dailyActions,
  }) {
    return UsageStats(
      totalEmailsProcessed: totalEmailsProcessed ?? this.totalEmailsProcessed,
      needsActionSurfaced: needsActionSurfaced ?? this.needsActionSurfaced,
      repliesSent: repliesSent ?? this.repliesSent,
      emailsSnoozed: emailsSnoozed ?? this.emailsSnoozed,
      emailsMarkedDone: emailsMarkedDone ?? this.emailsMarkedDone,
      newslettersFiltered: newslettersFiltered ?? this.newslettersFiltered,
      lowValueFiltered: lowValueFiltered ?? this.lowValueFiltered,
      deadlinesDetected: deadlinesDetected ?? this.deadlinesDetected,
      questionsDetected: questionsDetected ?? this.questionsDetected,
      minutesSaved: minutesSaved ?? this.minutesSaved,
      firstUsed: firstUsed ?? this.firstUsed,
      lastSync: lastSync ?? this.lastSync,
      dailyActions: dailyActions ?? this.dailyActions,
    );
  }

  Map<String, dynamic> toJson() => {
        'totalEmailsProcessed': totalEmailsProcessed,
        'needsActionSurfaced': needsActionSurfaced,
        'repliesSent': repliesSent,
        'emailsSnoozed': emailsSnoozed,
        'emailsMarkedDone': emailsMarkedDone,
        'newslettersFiltered': newslettersFiltered,
        'lowValueFiltered': lowValueFiltered,
        'deadlinesDetected': deadlinesDetected,
        'questionsDetected': questionsDetected,
        'minutesSaved': minutesSaved,
        'firstUsed': firstUsed?.toIso8601String(),
        'lastSync': lastSync?.toIso8601String(),
        'dailyActions': dailyActions,
      };

  factory UsageStats.fromJson(Map<String, dynamic> json) {
    return UsageStats(
      totalEmailsProcessed: json['totalEmailsProcessed'] ?? 0,
      needsActionSurfaced: json['needsActionSurfaced'] ?? 0,
      repliesSent: json['repliesSent'] ?? 0,
      emailsSnoozed: json['emailsSnoozed'] ?? 0,
      emailsMarkedDone: json['emailsMarkedDone'] ?? 0,
      newslettersFiltered: json['newslettersFiltered'] ?? 0,
      lowValueFiltered: json['lowValueFiltered'] ?? 0,
      deadlinesDetected: json['deadlinesDetected'] ?? 0,
      questionsDetected: json['questionsDetected'] ?? 0,
      minutesSaved: json['minutesSaved'] ?? 0,
      firstUsed: json['firstUsed'] != null ? DateTime.parse(json['firstUsed']) : null,
      lastSync: json['lastSync'] != null ? DateTime.parse(json['lastSync']) : null,
      dailyActions: Map<String, int>.from(json['dailyActions'] ?? {}),
    );
  }
}