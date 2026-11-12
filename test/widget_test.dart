import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lab1_chat_ui/main.dart';

void main() {
  testWidgets('앱이 뜨고 입력창에 기본 안내 문구가 보인다', (WidgetTester tester) async {
    await tester.pumpWidget(const ChatLabApp());

    // 제목
    expect(find.text('AI Chat — 실습 1'), findsOneWidget);

    // 할 일 1이 끝났다면 목록이 그려진다
    expect(find.byType(ListView), findsOneWidget);

    // 입력창에 기본 안내 문구(힌트)가 보인다
    expect(
      tester.widget<TextField>(find.byType(TextField)).decoration!.hintText,
      '무엇이든 물어보세요',
    );
    expect(find.text('무엇이든 물어보세요'), findsOneWidget);

    // 입력창에 메시지를 입력해 전송하면 사용자 말풍선으로 추가된다.
    await tester.enterText(find.byType(TextField), '직접 보낸 메시지');
    await tester.pump(); // 전송 버튼이 활성화된 화면을 그린다
    await tester.tap(find.byIcon(Icons.send_rounded));
    await tester.pump();

    // 입력창은 비워지고, 글자는 말풍선에만 남는다.
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      isEmpty,
    );
    expect(find.text('직접 보낸 메시지'), findsOneWidget);

    // 가짜 응답 타이머를 끝까지 흘려보낸다.
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('키보드가 올라와도 입력창이 가려지지 않는다', (tester) async {
    await tester.pumpWidget(const ChatLabApp());

    // 화면 아래 300(논리 픽셀)을 키보드가 차지한 상황을 흉내 낸다.
    // FakeViewPadding은 물리 픽셀 단위라 devicePixelRatio를 곱한다.
    const keyboardHeight = 300.0;
    final dpr = tester.view.devicePixelRatio;
    tester.view.viewInsets = FakeViewPadding(bottom: keyboardHeight * dpr);
    addTearDown(tester.view.resetViewInsets);
    await tester.pump();

    final screenHeight = tester.view.physicalSize.height / dpr;
    final keyboardTop = screenHeight - keyboardHeight;

    expect(
      tester.getRect(find.byType(TextField)).bottom,
      lessThanOrEqualTo(keyboardTop),
    );
    expect(
      tester.getRect(find.byIcon(Icons.send_rounded)).bottom,
      lessThanOrEqualTo(keyboardTop),
    );
  });

  testWidgets('이전 대화 흔적이 보인다', (tester) async {
    await tester.pumpWidget(const ChatLabApp());

    expect(find.text('오늘 뭐 배워?'), findsOneWidget);
    expect(find.text('타이핑 점은 왜 필요해요?'), findsOneWidget);
  });

  testWidgets('입력 예시는 펼치고 접을 수 있고, 누르면 입력창에 채워진다', (tester) async {
    await tester.pumpWidget(const ChatLabApp());

    // 처음에는 접혀 있다.
    expect(find.text('입력 예시'), findsOneWidget);
    expect(find.byType(ActionChip), findsNothing);

    // 펼치면 4개가 보인다.
    await tester.tap(find.text('입력 예시'));
    await tester.pumpAndSettle();
    expect(find.byType(ActionChip), findsNWidgets(4));

    // 다시 누르면 접힌다.
    await tester.tap(find.text('입력 예시'));
    await tester.pumpAndSettle();
    expect(find.byType(ActionChip), findsNothing);

    await tester.tap(find.text('입력 예시'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ActionChip, 'Flutter 위젯이 뭐야?'));
    await tester.pump();

    // 바로 전송되지 않고 입력창에만 채워진다.
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'Flutter 위젯이 뭐야?',
    );

    // 고르고 나면 패널은 접힌다.
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(ActionChip), findsNothing);
  });
}
