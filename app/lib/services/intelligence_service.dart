class IntelligenceService {
  static Map<String, dynamic> analyze({
    required String subject,
    required String snippet,
    required String from,
    List<String> vipSenders = const [],
    int? emailTimestamp,
  }) {
    String bucket = 'low';
    int score = 0;
    bool isActionable = false;

    final subjectLower = subject.toLowerCase();
    final snippetLower = snippet.toLowerCase();
    final fromLower = from.toLowerCase();

    // Extract sender email for VIP matching
    String senderEmail = fromLower;
    if (fromLower.contains('<')) {
      senderEmail = fromLower.split('<').last.replaceAll('>', '').trim();
    }

    // ── SIGNAL 1: Urgency Keywords (+30) ──
    final urgentWords = ['urgent', 'asap', 'immediately', 'critical', 'emergency', 'time-sensitive'];
    for (var word in urgentWords) {
      if (subjectLower.contains(word) || snippetLower.contains(word)) {
        score += 30;
        isActionable = true;
        if (bucket == 'low') bucket = 'needs_reply';
        break;
      }
    }

    // ── SIGNAL 2: Deadline Keywords (+25) ──
    final deadlineWords = ['deadline', 'due date', 'by tomorrow', 'end of day', 'eod', 'cob', 'by friday', 'by monday', 'due by', 'expires'];
    for (var word in deadlineWords) {
      if (subjectLower.contains(word) || snippetLower.contains(word)) {
        bucket = 'needs_reply';
        score += 25;
        isActionable = true;
        break;
      }
    }

    // ── SIGNAL 3: VIP Sender Boost (+35) ──
    if (vipSenders.any((vip) => senderEmail.contains(vip.toLowerCase()))) {
      score += 35;
      isActionable = true;
      if (bucket == 'low') bucket = 'needs_reply';
    }

    // ── SIGNAL 4: Waiting Time Boost (+5 to +20) ──
    if (emailTimestamp != null && emailTimestamp > 0) {
      final emailAge = DateTime.now().difference(
        DateTime.fromMillisecondsSinceEpoch(emailTimestamp),
      );
      if (emailAge.inDays >= 7) {
        score += 20;
      } else if (emailAge.inDays >= 3) {
        score += 10;
      } else if (emailAge.inDays >= 1) {
        score += 5;
      }
    }

    // ── SIGNAL 5: Direct Questions (+20) ──
    if (subject.contains('?') || snippet.contains('?')) {
      score += 20;
      isActionable = true;
      if (bucket == 'low') bucket = 'needs_reply';
    }

    // ── SIGNAL 6: Bills & Receipts (+40) ──
    final billWords = ['invoice', 'receipt', 'payment', 'bill', 'statement', 'transaction'];
    for (var word in billWords) {
      if (subjectLower.contains(word) || snippetLower.contains(word)) {
        bucket = 'bills';
        score += 40;
        isActionable = true;
        break;
      }
    }

    // ── SIGNAL 7: Waiting on Others (+35) ──
    final waitingWords = ['following up', 'checking in', 'any update', 'status update', 'reminder'];
    for (var word in waitingWords) {
      if (subjectLower.contains(word) || snippetLower.contains(word)) {
        bucket = 'waiting';
        score += 35;
        isActionable = true;
        break;
      }
    }

    // ── SIGNAL 8: Calendar (+20) ──
    final calendarWords = ['meeting', 'invite', 'calendar', 'schedule', 'appointment'];
    for (var word in calendarWords) {
      if (subjectLower.contains(word) || snippetLower.contains(word)) {
        if (bucket == 'low') bucket = 'calendar';
        score += 20;
        isActionable = true;
        break;
      }
    }

    // ── SIGNAL 9: Low Value Override (resets score) ──
    final junkWords = ['unsubscribe', 'newsletter', 'no-reply', 'noreply', 'marketing', 'promotion'];
    for (var word in junkWords) {
      if (subjectLower.contains(word) || snippetLower.contains(word) || fromLower.contains(word)) {
        bucket = 'low';
        score = 0;
        isActionable = false;
        break;
      }
    }

    // Cap score at 100
    if (score > 100) score = 100;

    // ── Derive Priority Label ──
    String priorityLabel;
    if (score >= 70) {
      priorityLabel = 'urgent';
    } else if (score >= 40) {
      priorityLabel = 'important';
    } else {
      priorityLabel = 'low';
    }

    return {
      'bucket': bucket,
      'priorityScore': score,
      'isActionable': isActionable,
      'priorityLabel': priorityLabel,
    };
  }
}