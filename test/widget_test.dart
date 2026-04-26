import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// তোমার প্রোজেক্টের নাম যদি myapp হয়, তাহলে নিচের লাইনটি ঠিক আছে, 
// অথবা রিলেটিভ পাথ ব্যবহার করতে পারো:
import '../lib/main.dart'; 

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const KothaBookApp()); // 🚀 এখানে MyApp এর জায়গায় KothaBookApp দেওয়া হয়েছে

    // Verify that our counter starts at 0.
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    // Tap the '+' icon and trigger a frame.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    // Verify that our counter has incremented.
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });
}