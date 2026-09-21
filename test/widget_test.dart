import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sampahbank/main.dart';

void main() {
  testWidgets('App boots to App Key setup or login', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const SampahBankApp());
    await tester.pump();

    expect(
      find.byType(CircularProgressIndicator).evaluate().isNotEmpty ||
          find.text('Bank Sampah').evaluate().isNotEmpty ||
          find.text('BANK SAMPAH').evaluate().isNotEmpty,
      isTrue,
    );
  });
}
