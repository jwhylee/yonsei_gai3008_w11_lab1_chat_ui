import 'dart:async';

import 'package:flutter/material.dart';

void main() => runApp(const ChatLabApp());

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
  final List<ChatMessage> _messages = [];

  final _controller = TextEditingController();

  /// AI 응답을 기다리는 동안에만 대기 말풍선을 보여 준다.
  bool _sending = false;
  Timer? _responseTimer;

  bool get _canSend => _controller.text.trim().isNotEmpty;
  bool get _isUserTyping => _canSend;

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
      // TIP: Scaffold의 resizeToAvoidBottomInset은 기본값이 true다.
      //      body를 SafeArea로 감싸 홈 인디케이터와 노치를 피한다.
      appBar: AppBar(title: const Text('AI Chat — 실습 1')),
      body: SafeArea(
        child: Column(
          children: [
            // ─────────────────────────────────────────────────────────
            // ✅ 할 일 1 — 완료된 부분
            //    ListView.builder + reverse: true
            //    · reverse:true면 index 0이 화면 맨 아래(최신)다.
            //    · 그래서 _messages[length - 1 - i]로 거꾸로 꺼낸다.
            // ─────────────────────────────────────────────────────────
            // ─────────────────────────────────────────────────────────
            // TODO 4 — 빈 상태
            //    ListView를 Stack으로 감싸고, 대화가 비었을 때만
            //    흐린 안내 문구를 가운데에 겹쳐 띄운다.
            // ─────────────────────────────────────────────────────────
            Expanded(
              child: Stack(
                children: [
                  ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    // 입력/전송 중 표시도 가장 최근 항목처럼 목록 맨 아래에 놓는다.
                    itemCount:
                        _messages.length +
                        (_isUserTyping ? 1 : 0) +
                        (_sending ? 1 : 0),
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

                      final statusCount =
                          (_isUserTyping ? 1 : 0) + (_sending ? 1 : 0);
                      final message =
                          _messages[_messages.length -
                              1 -
                              (index - statusCount)];
                      return _Bubble(message: message);
                    },
                  ),
                  if (_messages.isEmpty)
                    // 안내 문구가 목록 스크롤·터치를 막지 않게 한다.
                    IgnorePointer(
                      child: Center(
                        child: Text(
                          '무엇이든 물어보세요',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant
                                    .withValues(alpha: 0.6),
                              ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            _MessageComposer(
              controller: _controller,
              canSend: _canSend && !_sending,
              onChanged: (_) => setState(() {}),
              onSend: _send,
            ),
          ],
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
    required this.onChanged,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool canSend;
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
              maxLines: 4,
              decoration: InputDecoration(
                hintText: '메시지를 입력하세요',
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
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        constraints: const BoxConstraints(maxWidth: 420),
        decoration: BoxDecoration(
          color: isUser
              ? colorScheme.primaryContainer
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
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
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isUser
              ? colorScheme.primaryContainer
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
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
            width: 42,
            height: 18,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (index) {
                final phase = (_controller.value + index / 3) % 1;
                final progress = phase < 0.5
                    ? Curves.easeOut.transform(phase * 2)
                    : Curves.easeIn.transform((1 - phase) * 2);

                return Transform.translate(
                  offset: Offset(0, -3 * progress),
                  child: Opacity(
                    opacity: 0.3 + (0.7 * progress),
                    child: Container(
                      width: 5,
                      height: 5,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
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
