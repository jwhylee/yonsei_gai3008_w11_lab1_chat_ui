import 'dart:async';

import 'package:flutter/material.dart';

void main() => runApp(const ChatLabApp());

/// 대화 영역 배율. 말풍선·입력 예시·타이핑 점의 글자와 여백에 곱한다.
/// 하단 입력창과 전송 버튼에는 적용하지 않는다.
const double kChatScale = 1.2;

class ChatLabApp extends StatelessWidget {
  const ChatLabApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Chat — 실습 1',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2F6FE4)),
        useMaterial3: true,
      ),
      home: const ChatPage(),
    );
  }
}

/// 대화 한 줄. 서버 없이 화면만 만들기 위한 최소 모델.
class ChatMessage {
  const ChatMessage({required this.text, required this.isUser});

  final String text;
  final bool isUser;
}

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  /// 실습용 가짜 대화 — API를 붙이기 전까지 이 목록으로 화면을 만든다.
  /// 이미 대화를 조금 나눈 것처럼 보이도록 몇 줄을 미리 넣어 둔다.
  final List<ChatMessage> _messages = [
    ChatMessage(text: '오늘 뭐 배워?', isUser: true),
    ChatMessage(text: 'AI 챗봇 화면을 만들어요. 말풍선, 입력창, 타이핑 표시까지요.', isUser: false),
    ChatMessage(text: '타이핑 점은 왜 필요해요?', isUser: true),
    ChatMessage(text: '응답이 1초를 넘으면 앱이 멈춘 것처럼 보이기 때문입니다.', isUser: false),
  ];

  final _controller = TextEditingController();

  /// AI 응답을 기다리는 동안에만 대기 말풍선을 보여 준다.
  bool _sending = false;
  Timer? _responseTimer;

  /// 대화 영역 위쪽 접이식 패널에 보여 줄 입력 예시.
  static const _suggestions = [
    '오늘 뭐 배워?',
    'Flutter 위젯이 뭐야?',
    '타이핑 점은 왜 필요해요?',
    '오늘 할 일 정리해 줘',
  ];

  /// 입력 예시 패널을 펼쳤는지. 배경을 깔끔하게 두려고 처음엔 접어 둔다.
  bool _suggestionsOpen = false;

  bool get _canSend => _controller.text.trim().isNotEmpty;
  bool get _isUserTyping => _canSend;

  /// 예시를 누르면 입력창에 채우고 패널을 접는다. 전송은 사용자가 직접 한다.
  void _fillSuggestion(String text) {
    setState(() {
      _suggestionsOpen = false;
      _controller.value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
    });
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
      _controller.clear();
      _sending = true;
    });

    // API 연결 전에는 응답을 흉내 내어 대기 애니메이션을 확인한다.
    _responseTimer?.cancel();
    _responseTimer = Timer(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      setState(() {
        _messages.add(const ChatMessage(text: '아직 미구현되었습니다.', isUser: false));
        _sending = false;
      });
    });
  }

  @override
  void dispose() {
    _responseTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // TODO 5 — 키보드가 입력창을 가리지 않게
      //    · 키보드가 올라오면 body 높이를 줄여 입력창을 키보드 위로 올린다.
      //      (기본값도 true지만 의도를 드러내려고 명시한다.)
      //    · Android는 AndroidManifest의 windowSoftInputMode="adjustResize"가 함께 필요하다.
      //    · body를 SafeArea로 감싸 홈 인디케이터와 노치를 피한다.
      resizeToAvoidBottomInset: true,
      appBar: AppBar(title: const Text('AI Chat — 실습 1')),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) =>
              _buildChat(context, constraints.maxHeight),
        ),
      ),
    );
  }

  Widget _buildChat(BuildContext context, double availableHeight) {
    // 화면이 낮을 때(가로 모드 + 키보드 등) 여러 줄 입력이 화면을 넘치지 않도록
    // 입력창이 화면 높이의 절반을 넘지 않는 만큼만 줄 수를 허용한다(최대 4줄).
    // 보통 세로 화면에서는 항상 4줄이다.
    final lineHeight = MediaQuery.textScalerOf(context).scale(16) * 1.5;
    final maxLines = ((availableHeight / 2 - 50) / lineHeight).floor().clamp(
      1,
      4,
    );
    final statusCount = (_isUserTyping ? 1 : 0) + (_sending ? 1 : 0);

    return Column(
      children: [
        // ─────────────────────────────────────────────────────────
        // ✅ 할 일 1 — 완료된 부분
        //    ListView.builder + reverse: true
        //    · reverse:true면 index 0이 화면 맨 아래(최신)다.
        //    · 그래서 _messages[length - 1 - i]로 거꾸로 꺼낸다.
        // ─────────────────────────────────────────────────────────
        // ─────────────────────────────────────────────────────────
        // TODO 4 — 빈 상태
        //    배경 문구 대신 입력창 힌트로 "무엇이든 물어보세요"를 보여 주고,
        //    대화 영역 위에 펼치고 접을 수 있는 입력 예시를 둔다.
        // ─────────────────────────────────────────────────────────
        Expanded(
          // 대화 영역(말풍선·입력 예시) 글자만 kChatScale배. 입력창은 원래 크기를 쓴다.
          // 기기 글자 크기 설정도 반영하되, 둘이 곱해져 너무 커지지 않도록
          // 기기 설정은 1.3배까지만 따른다.
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(
                MediaQuery.textScalerOf(
                      context,
                    ).clamp(maxScaleFactor: 1.3).scale(1) *
                    kChatScale,
              ),
            ),
            child: Column(
              children: [
                // 입력 예시 패널은 화면 높이의 절반까지만 차지하고,
                // 그보다 길면 패널 안에서 스크롤된다(낮은 화면에서도 넘치지 않게).
                ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: availableHeight * 0.5),
                  child: _SuggestionPanel(
                    suggestions: _suggestions,
                    isOpen: _suggestionsOpen,
                    onToggle: () =>
                        setState(() => _suggestionsOpen = !_suggestionsOpen),
                    onSelected: _fillSuggestion,
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    // 입력/전송 중 표시도 가장 최근 항목처럼 목록 맨 아래에 놓는다.
                    itemCount: _messages.length + statusCount,
                    itemBuilder: (context, index) {
                      if (_isUserTyping && index == 0) {
                        return const _TypingBubble(
                          isUser: true,
                          label: '메시지를 입력하고 있습니다',
                        );
                      }

                      final aiTypingIndex = _isUserTyping ? 1 : 0;
                      if (_sending && index == aiTypingIndex) {
                        return const _TypingBubble(
                          isUser: false,
                          label: 'AI가 응답을 작성하고 있습니다',
                        );
                      }

                      final message =
                          _messages[_messages.length -
                              1 -
                              (index - statusCount)];
                      return _Bubble(message: message);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),

        _MessageComposer(
          controller: _controller,
          canSend: _canSend && !_sending,
          maxLines: maxLines,
          onChanged: (_) => setState(() {}),
          onSend: _send,
        ),
      ],
    );
  }
}

/// 대화 영역 위쪽의 접이식 입력 예시 패널.
/// 머리줄을 누르면 펼치고 접으며, 펼치면 예시를 왼쪽에 세로로 쌓아 보여 준다.
class _SuggestionPanel extends StatelessWidget {
  const _SuggestionPanel({
    required this.suggestions,
    required this.isOpen,
    required this.onToggle,
    required this.onSelected,
  });

  final List<String> suggestions;
  final bool isOpen;
  final VoidCallback onToggle;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        border: Border(bottom: BorderSide(color: colorScheme.outlineVariant)),
      ),
      child: SingleChildScrollView(
        child: AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          alignment: Alignment.topCenter,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: onToggle,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12 * kChatScale,
                    vertical: 8 * kChatScale,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        size: 18 * kChatScale,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 6 * kChatScale),
                      Expanded(
                        child: Text(
                          '입력 예시',
                          style: textTheme.labelLarge?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      Icon(
                        isOpen ? Icons.expand_less : Icons.expand_more,
                        semanticLabel: isOpen ? '입력 예시 접기' : '입력 예시 펼치기',
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ),
              if (isOpen)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    12 * kChatScale,
                    0,
                    12 * kChatScale,
                    4 * kChatScale,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final text in suggestions)
                        Padding(
                          padding: const EdgeInsets.only(
                            bottom: 6 * kChatScale,
                          ),
                          child: ActionChip(
                            label: Text(text),
                            onPressed: () => onSelected(text),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// TODO 3 — 테마 색상을 따르는 하단 메시지 입력창.
class _MessageComposer extends StatelessWidget {
  const _MessageComposer({
    required this.controller,
    required this.canSend,
    required this.maxLines,
    required this.onChanged,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool canSend;
  final int maxLines;
  final ValueChanged<String> onChanged;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(top: BorderSide(color: colorScheme.outlineVariant)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              onSubmitted: (_) => onSend(),
              textInputAction: TextInputAction.send,
              minLines: 1,
              maxLines: maxLines,
              decoration: InputDecoration(
                hintText: '무엇이든 물어보세요',
                isDense: true,
                constraints: const BoxConstraints(minHeight: 48),
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 15,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 48,
            height: 48,
            child: IconButton.filled(
              onPressed: canSend ? onSend : null,
              tooltip: '메시지 전송',
              icon: const Icon(Icons.send_rounded),
            ),
          ),
        ],
      ),
    );
  }
}

/// ───────────────────────────────────────────────────────────────
/// TODO 2 — 말풍선 2종 (사용자 오른쪽 / AI 왼쪽)
///
/// 지금은 글자만 보이는 상자다. 다음을 채워 넣자.
///
/// TIP:
///  · Align(alignment: isUser ? Alignment.centerRight : Alignment.centerLeft)
///  · Container(
///      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
///      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
///      constraints: BoxConstraints(maxWidth: 420),
///      decoration: BoxDecoration(
///        color: isUser ? colorScheme.primaryContainer
///                      : colorScheme.surfaceContainerHighest,
///        borderRadius: BorderRadius.circular(14),
///      ),
///    )
///  · 색은 Theme.of(context).colorScheme에서 꺼내면 다크 모드에서도 안전하다.
///  · 긴 글은 자동으로 줄바꿈된다. maxWidth만 잡아 주면 된다.
/// ───────────────────────────────────────────────────────────────
class _Bubble extends StatelessWidget {
  const _Bubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isUser = message.isUser;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: 12 * kChatScale,
          vertical: 4 * kChatScale,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 12 * kChatScale,
          vertical: 10 * kChatScale,
        ),
        // 화면이 이보다 좁으면 화면 폭에 맞춰 줄바꿈된다.
        constraints: const BoxConstraints(maxWidth: 420 * kChatScale),
        decoration: BoxDecoration(
          color: isUser
              ? colorScheme.primaryContainer
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14 * kChatScale),
        ),
        child: Text(
          message.text,
          style: TextStyle(
            color: isUser
                ? colorScheme.onPrimaryContainer
                : colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

/// 메시지를 작성하거나 AI가 응답을 생성할 때 보이는 점 애니메이션 말풍선.
class _TypingBubble extends StatelessWidget {
  const _TypingBubble({required this.isUser, required this.label});

  final bool isUser;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: 12 * kChatScale,
          vertical: 4 * kChatScale,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 12 * kChatScale,
          vertical: 10 * kChatScale,
        ),
        decoration: BoxDecoration(
          color: isUser
              ? colorScheme.primaryContainer
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14 * kChatScale),
        ),
        child: _TypingDots(
          label: label,
          color: isUser
              ? colorScheme.onPrimaryContainer
              : colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _TypingDots extends StatefulWidget {
  const _TypingDots({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1050),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.label,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return SizedBox(
            width: 42 * kChatScale,
            height: 18 * kChatScale,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (index) {
                final phase = (_controller.value + index / 3) % 1;
                final progress = phase < 0.5
                    ? Curves.easeOut.transform(phase * 2)
                    : Curves.easeIn.transform((1 - phase) * 2);

                return Transform.translate(
                  offset: Offset(0, -3 * kChatScale * progress),
                  child: Opacity(
                    opacity: 0.3 + (0.7 * progress),
                    child: Container(
                      width: 5 * kChatScale,
                      height: 5 * kChatScale,
                      margin: const EdgeInsets.symmetric(
                        horizontal: 2 * kChatScale,
                      ),
                      decoration: BoxDecoration(
                        color: widget.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                );
              }),
            ),
          );
        },
      ),
    );
  }
}
