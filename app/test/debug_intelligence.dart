import 'package:app/services/intelligence_service.dart';
import 'package:app/models/email_label_model.dart';
import 'package:flutter/material.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  final testCases = [
    {
      'name': 'Finance',
      'subject': 'Order Confirmation #BK-1234',
      'snippet': 'Your receipt for the purchase of a new laptop.',
      'from': 'orders@amazon.com',
    },
    {
      'name': 'Subject ?',
      'subject': 'Can you join the call?',
      'snippet': 'Meeting starting now.',
      'from': 'colleague@company.com',
    },
    {
      'name': 'Snippet ? (Should NOT be Needs Reply)',
      'subject': 'Update on project',
      'snippet': 'Is this the latest version?',
      'from': 'colleague@company.com',
    },
    {
      'name': 'Fallback',
      'subject': 'Hi there',
      'snippet': 'Just checking in to see how you are doing.',
      'from': 'friend@gmail.com',
    },
    {
      'name': 'Expanded Promo',
      'subject': 'Last chance: order now!',
      'snippet': 'Get an extra 20% off your next purchase.',
      'from': 'deals@store.com',
    }
  ];

  for (var tc in testCases) {
    print('--- Testing: ${tc['name']} ---');
    final result = IntelligenceService.analyze(
      subject: tc['subject'] as String,
      snippet: tc['snippet'] as String,
      from: tc['from'] as String,
    );
    print('Label: ${result['label']}');
    print('Bucket: ${result['bucket']}');
    print('Score: ${result['priorityScore']}');
    print('PriorityLabel: ${result['priorityLabel']}');
    print('Signals: ${result['signals']}');
    print('');
  }
}
