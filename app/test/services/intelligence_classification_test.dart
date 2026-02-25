import 'package:flutter_test/flutter_test.dart';
import 'package:app/services/intelligence_service.dart';
import 'package:app/models/email_label_model.dart';

void main() {
  group('IntelligenceService Classification Tests', () {
    test('Classifies Security OTP correctly', () {
      final result = IntelligenceService.analyze(
        subject: 'Your verification code is 123456',
        snippet: 'Enter this OTP to login to your account.',
        from: 'security@bank.com',
      );

      expect(result['label'], equals('security'));
      expect(result['bucket'], equals('important'));
      expect(result['priorityLabel'], equals('urgent'));
      expect(result['priorityScore'], greaterThanOrEqualTo(90));
    });

    test('Classifies Finance / Receipt correctly', () {
      final result = IntelligenceService.analyze(
        subject: 'Order Confirmation #BK-1234',
        snippet: 'Your receipt for the purchase of a new laptop.',
        from: 'orders@amazon.com',
      );

      expect(result['label'], equals('finance'));
      expect(result['bucket'], equals('transactions'));
      expect(result['priorityLabel'], equals('important'));
    });

    test('Classifies Work / Action correctly', () {
      final result = IntelligenceService.analyze(
        subject: 'Immediate action required on project X',
        snippet: 'Could you please review the latest designs?',
        from: 'boss@company.com',
      );

      expect(result['label'], equals('work'));
      expect(result['bucket'], equals('needs_reply'));
      expect(result['priorityLabel'], equals('normal'));
    });

    test('Does NOT classify snippet question mark as Needs Reply', () {
      final result = IntelligenceService.analyze(
        subject: 'Update on project',
        snippet: 'Is this the latest version?',
        from: 'colleague@company.com',
      );

      // Should be updates/general, not needs_reply/work
      expect(result['bucket'], equals('updates'));
      expect(result['label'], equals('general'));
    });

    test('Classifies subject question mark as Needs Reply', () {
      final result = IntelligenceService.analyze(
        subject: 'Can you join the call?',
        snippet: 'Meeting starting now.',
        from: 'colleague@company.com',
      );

      expect(result['bucket'], equals('needs_reply'));
    });

    test('Classifies Calendar / Meeting correctly', () {
      final result = IntelligenceService.analyze(
        subject: 'Invitation: Team Standup @ 10am',
        snippet: 'You have been invited to a Zoom meeting.',
        from: 'calendar-gmail.com',
      );

      expect(result['label'], equals('calendar'));
      expect(result['bucket'], equals('events'));
    });

    test('Classifies Marketing / Promotion correctly', () {
      final result = IntelligenceService.analyze(
        subject: '50% OFF SUMMER SALE!',
        snippet: 'Shop now for exclusive deals. Unsubscribe here.',
        from: 'news@fashion.com',
      );

      expect(result['label'], equals('marketing'));
      expect(result['bucket'], equals('promotions'));
    });

    test('Classifies expanded Promotions correctly', () {
      final result = IntelligenceService.analyze(
        subject: 'Last chance: order now!',
        snippet: 'Get an extra 20% off your next purchase.',
        from: 'deals@store.com',
      );

      expect(result['label'], equals('marketing'));
      expect(result['bucket'], equals('promotions'));
    });

    test('Classifies Social correctly', () {
      final result = IntelligenceService.analyze(
        subject: 'New connection request on LinkedIn',
        snippet: 'John Doe wants to connect with you.',
        from: 'notifications@linkedin.com',
      );

      expect(result['label'], equals('social'));
      expect(result['bucket'], equals('updates'));
    });

    test('Handles Custom Labels correctly', () {
      final customLabels = [
        const EmailLabel(
          id: 'project_delta',
          name: 'Project Delta',
          color: '#000000',
          keywords: ['delta', 'epsilon'],
          bucketId: 'important',
        ),
      ];

      final result = IntelligenceService.analyze(
        subject: 'Update on project epsilon',
        snippet: 'The files are ready for Delta members.',
        from: 'team@work.com',
        customLabels: customLabels,
      );

      expect(result['label'], equals('project_delta'));
      expect(result['bucket'], equals('important'));
    });

    test('Fallback to Personal if no match', () {
      final result = IntelligenceService.analyze(
        subject: 'Hi there',
        snippet: 'Just checking in to see how you are doing.',
        from: 'friend@gmail.com',
      );

      expect(result['label'], equals('personal'));
      expect(result['bucket'], equals('updates'));
    });
  });
}
