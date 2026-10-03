import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttergo_demo_tutorial/main.dart';

void main() {
  testWidgets('App boots to splash', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: FlutterGoApp()));
    expect(find.text('Habits Demo'), findsWidgets);
  });
}
