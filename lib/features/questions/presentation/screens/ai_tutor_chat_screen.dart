import 'package:flutter/material.dart';

class AiTutorChatScreen extends StatefulWidget {
  const AiTutorChatScreen({super.key});

  @override
  State<AiTutorChatScreen> createState() => _AiTutorChatScreenState();
}

class _AiTutorChatScreenState extends State<AiTutorChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<_ChatMessage> _messages = <_ChatMessage>[
    const _ChatMessage(
      text:
          'Hello. I am your AI Tutor. Ask me any PYQ doubt, concept, or revision plan question.',
      isUser: false,
    ),
  ];

  final List<String> _quickPrompts = const <String>[
    'Thermodynamics quick revision',
    'How to improve mock test score?',
    'Best way to attempt PYQ daily?',
    'Make a 7-day Physics plan',
  ];

  bool _isReplying = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _sendMessage([String? preset]) async {
    final input = (preset ?? _controller.text).trim();
    if (input.isEmpty || _isReplying) return;

    setState(() {
      _messages.add(_ChatMessage(text: input, isUser: true));
      _controller.clear();
      _isReplying = true;
    });

    await Future<void>.delayed(const Duration(milliseconds: 450));

    if (!mounted) return;
    setState(() {
      _messages.add(_ChatMessage(text: _generateReply(input), isUser: false));
      _isReplying = false;
    });
  }

  String _generateReply(String input) {
    final q = input.toLowerCase();

    if (q.contains('plan') || q.contains('schedule')) {
      return 'Try this: 1) 30 min concept revision 2) 40 min PYQ solving 3) 20 min error log review. Repeat daily and track weak topics every 3 days.';
    }
    if (q.contains('mock') || q.contains('score')) {
      return 'For better mock score: attempt easy questions in first pass, mark doubtful ones, and keep last 20 minutes for review. Accuracy first, speed second.';
    }
    if (q.contains('physics') ||
        q.contains('chemistry') ||
        q.contains('math')) {
      return 'For this subject, focus on high-frequency chapters, solve recent PYQs first, and maintain a mistake notebook with formula or concept tags.';
    }

    return 'Good question. Start with chapter summary, solve 15-20 PYQs, then review wrong answers deeply. If you want, I can make a chapter-wise strategy next.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI Tutor Chatbot')),
      body: Column(
        children: [
          SizedBox(
            height: 54,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, index) {
                final prompt = _quickPrompts[index];
                return ActionChip(
                  label: Text(prompt),
                  onPressed: _isReplying ? null : () => _sendMessage(prompt),
                );
              },
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemCount: _quickPrompts.length,
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _messages.length + (_isReplying ? 1 : 0),
              itemBuilder: (context, index) {
                if (_isReplying && index == _messages.length) {
                  return const _TypingBubble();
                }
                final message = _messages[index];
                return Align(
                  alignment: message.isUser
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    constraints: const BoxConstraints(maxWidth: 320),
                    decoration: BoxDecoration(
                      color: message.isUser
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: message.isUser
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).dividerColor,
                      ),
                    ),
                    child: Text(
                      message.text,
                      style: TextStyle(
                        color: message.isUser
                            ? Colors.white
                            : Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                      decoration: const InputDecoration(
                        hintText: 'Ask your doubt...',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _isReplying ? null : () => _sendMessage(),
                    icon: const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatMessage {
  const _ChatMessage({required this.text, required this.isUser});

  final String text;
  final bool isUser;
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: const Text('AI Tutor is typing...'),
      ),
    );
  }
}
