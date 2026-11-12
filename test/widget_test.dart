import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lab1_chat_ui/main.dart';

void main() {
  testWidgets('앱이 뜨고 빈 상태 문구가 보인다', (WidgetTester tester) async {
    await tester.pumpWidget(const ChatLabApp());

    // 제목
    expect(find.text('AI Chat — 실습 1'), findsOneWidget);

    // 할 일 1이 끝났다면 목록이 그려진다
    expect(find.byType(ListView), findsOneWidget);

    // 대화가 비어 있으면 빈 상태 문구가 보인다
    expect(find.text('무엇이든 물어보세요'), findsOneWidget);

    // 입력창에 메시지를 입력해 전송하면 사용자 말풍선으로 추가되고
    // 빈 상태 문구는 사라진다.
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
    expect(find.text('무엇이든 물어보세요'), findsNothing);

    // 가짜 응답 타이머를 끝까지 흘려보낸다.
    await tester.pump(const Duration(seconds: 2));
  });
}
