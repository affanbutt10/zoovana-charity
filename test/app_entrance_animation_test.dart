import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zoovana_charity/app/shared/widgets/app_animations.dart';

void main() {
  testWidgets('plays after its delay and reaches its resting state', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AppEntranceAnimation(
          duration: Duration(milliseconds: 200),
          delay: Duration(milliseconds: 100),
          child: Text('Animated content'),
        ),
      ),
    );

    FadeTransition fade() => tester.widget(
      find.descendant(
        of: find.byType(AppEntranceAnimation),
        matching: find.byType(FadeTransition),
      ),
    );

    expect(fade().opacity.value, 0);
    await tester.pump(const Duration(milliseconds: 100));
    expect(fade().opacity.value, 0);
    await tester.pump(const Duration(milliseconds: 100));
    expect(fade().opacity.value, greaterThan(0));
    expect(fade().opacity.value, lessThan(1));
    await tester.pumpAndSettle();
    expect(fade().opacity.value, 1);
  });

  testWidgets('replays when trigger becomes active again', (tester) async {
    final trigger = ValueNotifier(false);
    addTearDown(trigger.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: ValueListenableBuilder<bool>(
          valueListenable: trigger,
          builder: (context, active, child) =>
              AppEntranceAnimation.fade(trigger: active, child: child!),
          child: const Text('Animated content'),
        ),
      ),
    );

    FadeTransition fade() => tester.widget(
      find.descendant(
        of: find.byType(AppEntranceAnimation),
        matching: find.byType(FadeTransition),
      ),
    );

    expect(fade().opacity.value, 1);
    trigger.value = true;
    await tester.pump();
    expect(fade().opacity.value, 0);
    await tester.pumpAndSettle();
    expect(fade().opacity.value, 1);
  });

  testWidgets('skips motion when animations are disabled', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: AppEntranceAnimation(
            delay: Duration(seconds: 1),
            child: Text('Accessible content'),
          ),
        ),
      ),
    );

    final fade = tester.widget<FadeTransition>(
      find.descendant(
        of: find.byType(AppEntranceAnimation),
        matching: find.byType(FadeTransition),
      ),
    );
    expect(fade.opacity.value, 1);
  });
}
