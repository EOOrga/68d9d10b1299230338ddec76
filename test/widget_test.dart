import 'package:dupuy_francoise/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('opens the work queue from bottom navigation', (tester) async {
    await tester.pumpWidget(
      OperationsApp(store: MemoryRecordsStore(_records), screenshotMode: false),
    );
    await tester.pumpAndSettle();

    expect(find.text('DUPUY FRANCOISE'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.view_list_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Work queue'), findsOneWidget);
    expect(find.text('Confirm reception coverage'), findsOneWidget);
  });

  testWidgets('creates a local operations record', (tester) async {
    await tester.pumpWidget(
      OperationsApp(store: MemoryRecordsStore(), screenshotMode: false),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.add_circle_outline));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('record-title-field')),
      'Restock filters',
    );
    await tester.enterText(
      find.byKey(const ValueKey('record-owner-field')),
      'Maintenance',
    );
    await tester.enterText(
      find.byKey(const ValueKey('record-location-field')),
      'Plant room',
    );
    await tester.enterText(
      find.byKey(const ValueKey('record-due-field')),
      'Tomorrow 09:00',
    );

    final saveButton = find.byKey(const ValueKey('save-record-button'));
    await tester.ensureVisible(saveButton);
    await tester.pump();
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    expect(find.text('Work queue'), findsOneWidget);
    expect(find.text('Restock filters'), findsOneWidget);
    expect(find.text('Shifts record saved'), findsOneWidget);
  });
}

final _records = [
  OperationRecord(
    id: 'test-001',
    type: WorkType.shift,
    title: 'Confirm reception coverage',
    owner: 'Operations',
    location: 'Main lobby',
    status: WorkStatus.active,
    priority: 'High',
    dueLabel: 'Today',
    notes: 'Check handover notes.',
    createdAt: DateTime(2026, 5, 12),
  ),
];
