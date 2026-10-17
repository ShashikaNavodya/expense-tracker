import 'package:expense_tracker/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('splash screen animates and opens the dashboard automatically', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ExpenseTrackerApp());

    expect(find.text('MINTLY'), findsOneWidget);
    expect(find.text('Make room for what matters.'), findsNothing);

    await tester.pumpAndSettle();

    expect(find.text('Make room for what matters.'), findsOneWidget);
  });

  testWidgets('dashboard shows spending summary and recent expenses', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const ExpenseTrackerApp());
    await tester.pumpWidget(const ExpenseTrackerApp());
    await tester.pumpAndSettle();

    expect(find.text('Make room for what matters.'), findsOneWidget);
    expect(find.text('MINTLY'), findsOneWidget);
    expect(find.text('TOTAL SPENT'), findsOneWidget);
    expect(find.text('Coffee & breakfast'), findsOneWidget);
  });

  testWidgets('user can add an expense from the dashboard', (tester) async {
    tester.view.physicalSize = const Size(1200, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const ExpenseTrackerApp());
    await tester.pumpWidget(const ExpenseTrackerApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add expense').first);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'What did you spend on?'),
      'Lunch with friends',
    );
    await tester.enterText(find.widgetWithText(TextFormField, 'Amount'), '780');
    await tester.tap(find.text('Add expense').last);
    await tester.pumpAndSettle();

    expect(find.text('Lunch with friends'), findsOneWidget);
    expect(find.textContaining('\$780'), findsOneWidget);
  });

  testWidgets('dashboard adapts to a phone-sized viewport', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const ExpenseTrackerApp());
    await tester.pumpWidget(const ExpenseTrackerApp());
    await tester.pumpAndSettle();

    expect(find.text('Make room for what matters.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
