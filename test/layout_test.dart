import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lab1_chat_ui/main.dart';

/// 화면 크기·키보드·기기 글자 크기를 바꿔 가며 채팅 화면이 깨지지 않는지 본다.
/// 레이아웃이 넘치면(RenderFlex overflow) 테스트 프레임워크가 예외로 잡아 실패한다.
void main() {
  const screens = {
    '작은 폰 360x640': Size(360, 640),
    '일반 폰 390x844': Size(390, 844),
    '가로 모드 844x390': Size(844, 390),
    '태블릿 1024x768': Size(1024, 768),
  };

  for (final MapEntry(key: name, value: size) in screens.entries) {
    final isLandscape = size.width > size.height;
    // 가로 모드에서는 키보드가 화면의 절반 가까이 차지한다.
    final keyboards = [0.0, isLandscape ? 170.0 : 300.0];

    for (final keyboard in keyboards) {
      for (final textScale in [1.0, 1.3]) {
        final label = '$name · 키보드 ${keyboard.toInt()} · 글자 x$textScale';

        testWidgets('$label — 빈 화면 + 입력 예시', (tester) async {
          await _pump(tester, size, keyboard, textScale);

          _expectComposerAligned(tester, size, keyboard);
          // 키보드가 없으면 입력 예시 4개가 모두 화면 안에 보여야 한다.
          if (keyboard == 0) {
            for (final chip in tester.widgetList<ActionChip>(
              find.byType(ActionChip),
            )) {
              final rect = tester.getRect(find.byWidget(chip));
              expect(rect.top, greaterThanOrEqualTo(0), reason: label);
            }
            expect(find.byType(ActionChip), findsNWidgets(4));
          }
        });

        testWidgets('$label — 긴 대화 + 여러 줄 입력 + 응답 대기', (tester) async {
          await _pump(tester, size, keyboard, textScale);

          for (var i = 0; i < 6; i++) {
            await tester.enterText(
              find.byType(TextField),
              '긴 메시지 $i ' * 20,
            );
            await tester.pump();
            await tester.tap(find.byIcon(Icons.send_rounded));
            await tester.pump(const Duration(seconds: 2));
          }

          // 여러 줄 입력 중 + AI 응답 대기 중인 상태
          await tester.enterText(find.byType(TextField), '한 줄\n두 줄\n세 줄\n네 줄');
          await tester.pump();
          await tester.tap(find.byIcon(Icons.send_rounded));
          await tester.enterText(find.byType(TextField), '다섯\n여섯\n일곱');
          await tester.pump(const Duration(milliseconds: 300));

          expect(tester.takeException(), isNull, reason: label);
          _expectAboveKeyboard(tester, size, keyboard);
          await tester.pump(const Duration(seconds: 2));
        });
      }
    }
  }
}

Future<void> _pump(
  WidgetTester tester,
  Size size,
  double keyboard,
  double textScale,
) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  tester.view.viewInsets = FakeViewPadding(bottom: keyboard);
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

  await tester.pumpWidget(const ChatLabApp());
  await tester.pump();
}

/// 레이아웃이 넘치지 않고, 입력창과 전송 버튼이 키보드 위에 있다.
void _expectComposerAligned(WidgetTester tester, Size size, double keyboard) {
  expect(tester.takeException(), isNull);
  _expectAboveKeyboard(tester, size, keyboard);
}

void _expectAboveKeyboard(WidgetTester tester, Size size, double keyboard) {
  final keyboardTop = size.height - keyboard;
  expect(
    tester.getRect(find.byType(TextField)).bottom,
    lessThanOrEqualTo(keyboardTop),
  );
  expect(
    tester.getRect(find.byType(IconButton)).bottom,
    lessThanOrEqualTo(keyboardTop),
  );
}
