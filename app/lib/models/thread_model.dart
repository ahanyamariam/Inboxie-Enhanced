import 'email_detail_model.dart';
export 'email_detail_model.dart';

class ThreadModel {
  final String id;
  final List<EmailDetailModel> messages;
  final String snippet;
  final int historyId;

  ThreadModel({
    required this.id,
    required this.messages,
    required this.snippet,
    this.historyId = 0,
  });

  factory ThreadModel.fromGmailApi(Map<String, dynamic> json) {
    final rawMessages = json['messages'] as List<dynamic>? ?? [];
    
    final messages = rawMessages
        .map((m) => EmailDetailModel.fromGmailApi(m as Map<String, dynamic>))
        .toList();

    // Sort messages by date (oldest first for conversation flow)
    messages.sort((a, b) => a.date.compareTo(b.date));

    return ThreadModel(
      id: json['id'] as String? ?? '',
      messages: messages,
      snippet: json['snippet'] as String? ?? '',
      historyId: int.tryParse(json['historyId']?.toString() ?? '0') ?? 0,
    );
  }

  /// Get the latest (most recent) message in thread
  EmailDetailModel get latestMessage => messages.last;

  /// Get the first (original) message
  EmailDetailModel get originalMessage => messages.first;

  /// Thread subject (from original message)
  String get subject => originalMessage.subject;

  /// Number of messages in thread
  int get messageCount => messages.length;

  /// Check if thread has multiple messages
  bool get hasMultipleMessages => messages.length > 1;

  /// Check if any message is unread
  bool get hasUnread => messages.any((m) => m.isUnread);

  /// Get all unique participants (email addresses)
  Set<String> get participants {
    final all = <String>{};
    for (final msg in messages) {
      if (msg.fromEmail.isNotEmpty) all.add(msg.fromEmail);
      all.addAll(msg.to.where((e) => e.isNotEmpty));
    }
    return all;
  }

  /// Get participant names for display
  List<String> get participantNames {
    final names = <String>{};
    for (final msg in messages) {
      if (msg.fromName.isNotEmpty) names.add(msg.fromName);
    }
    return names.toList();
  }
}