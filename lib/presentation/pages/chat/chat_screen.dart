import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/utils/time_formatter.dart';
import '../../../domain/entities/chat_message.dart';
import '../../blocs/chat/chat_bloc.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _inputFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    context.read<ChatBloc>().add(const ChatStarted());
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
      );
    });
  }

  void _handleSend(ChatBloc bloc) {
    final text = _messageController.text;
    bloc.add(ChatMessageSubmitted(text: text));
    _messageController.clear();
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<ChatBloc>();
    return Scaffold(
      backgroundColor: _ChatPalette.background,
      body: SafeArea(
        child: BlocConsumer<ChatBloc, ChatState>(
          listener: (context, state) {
            if (state.messages.isNotEmpty) {
              _scrollToBottom();
            }
          },
          builder: (context, state) {
            final messages = state.messages;
            return Column(
              children: [
                _ChatHeader(isConnected: state.isConnected),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: _ChatPalette.surface,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(28),
                        topRight: Radius.circular(28),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 20,
                          offset: const Offset(0, -6),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        Column(
                          children: [
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  20,
                                  24,
                                  20,
                                  24,
                                ),
                                child: ListView.builder(
                                  controller: _scrollController,
                                  itemCount:
                                      messages.length +
                                      (state.isTyping ? 1 : 0),
                                  itemBuilder: (context, index) {
                                    if (index >= messages.length) {
                                      return const _TypingBubble();
                                    }
                                    final message = messages[index];
                                    final previous =
                                        index > 0 ? messages[index - 1] : null;
                                    final showAvatar =
                                        message.type == MessageType.bot &&
                                        (previous == null ||
                                            previous.type != MessageType.bot);
                                    return Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 18,
                                      ),
                                      child: _ChatBubble(
                                        message: message,
                                        showAvatar: showAvatar,
                                        onFavorite: (isFavorite) {
                                          bloc.add(
                                            ChatFavoriteToggled(
                                              messageId: message.id,
                                              isFavorite: isFavorite,
                                            ),
                                          );
                                        },
                                        onQuickReply:
                                            (chip) => bloc.add(
                                              ChatSuggestionPressed(chip),
                                            ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 250),
                              switchInCurve: Curves.easeOut,
                              switchOutCurve: Curves.easeIn,
                              child:
                                  state.suggestions.isEmpty
                                      ? const SizedBox(height: 8)
                                      : Padding(
                                        key: const ValueKey('suggestion_chips'),
                                        padding: const EdgeInsets.fromLTRB(
                                          20,
                                          0,
                                          20,
                                          24,
                                        ),
                                        child: _SuggestionChips(
                                          suggestions: state.suggestions,
                                          onPressed: (chip) {
                                            bloc.add(
                                              ChatSuggestionPressed(chip),
                                            );
                                          },
                                        ),
                                      ),
                            ),
                          ],
                        ),
                        if (state.status == ChatViewStatus.loading)
                          const Center(
                            child: CircularProgressIndicator(
                              color: _ChatPalette.accent,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                _InputBar(
                  controller: _messageController,
                  focusNode: _inputFocusNode,
                  isOnline: state.isConnected,
                  onSend: () => _handleSend(bloc),
                  onRetryPending:
                      state.hasPendingMessages
                          ? () => bloc.add(const ChatPendingRetryRequested())
                          : null,
                  status: state.status,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class MaikaAvatar extends StatelessWidget {
  const MaikaAvatar({super.key, this.size = 48});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: _ChatPalette.accent.withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset(
          'maika.png',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            // Fallback en caso de que la imagen no cargue
            return Container(
              color: _ChatPalette.accent,
              child: const Icon(Icons.person, color: Colors.white),
            );
          },
        ),
      ),
    );
  }
}

class _MaikaAvatarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    final haloPaint =
        Paint()
          ..shader = RadialGradient(
            colors: [
              Colors.white.withValues(alpha: 0.4),
              Colors.white.withValues(alpha: 0.05),
            ],
          ).createShader(
            Rect.fromCircle(center: center, radius: size.width / 2),
          );
    canvas.drawCircle(center, size.width / 2.6, haloPaint);

    final facePaint = Paint()..color = const Color(0xFFF4D9C7);
    final faceRect = Rect.fromCenter(
      center: Offset(center.dx, center.dy + size.height * 0.08),
      width: size.width * 0.55,
      height: size.height * 0.62,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(faceRect, Radius.circular(size.width * 0.28)),
      facePaint,
    );

    final hairPaint = Paint()..color = const Color(0xFF1C2436);
    final hairPath =
        Path()
          ..moveTo(faceRect.left, faceRect.top)
          ..quadraticBezierTo(
            center.dx,
            faceRect.top - size.height * 0.45,
            faceRect.right,
            faceRect.top,
          )
          ..quadraticBezierTo(
            faceRect.right + size.width * 0.12,
            faceRect.top + size.height * 0.55,
            center.dx,
            faceRect.bottom + size.height * 0.05,
          )
          ..quadraticBezierTo(
            faceRect.left - size.width * 0.12,
            faceRect.top + size.height * 0.55,
            faceRect.left,
            faceRect.top,
          )
          ..close();
    canvas.drawPath(hairPath, hairPaint);

    final eyePaint = Paint()..color = const Color(0xFF1B2434);
    final eyeWhite = Paint()..color = Colors.white.withValues(alpha: 0.9);
    final eyeOffsetY = faceRect.center.dy - size.height * 0.05;
    final eyeOffsetX = size.width * 0.11;

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx - eyeOffsetX, eyeOffsetY),
        width: size.width * 0.15,
        height: size.height * 0.12,
      ),
      eyeWhite,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx + eyeOffsetX, eyeOffsetY),
        width: size.width * 0.15,
        height: size.height * 0.12,
      ),
      eyeWhite,
    );
    canvas.drawCircle(
      Offset(center.dx - eyeOffsetX, eyeOffsetY),
      size.width * 0.04,
      eyePaint,
    );
    canvas.drawCircle(
      Offset(center.dx + eyeOffsetX, eyeOffsetY),
      size.width * 0.04,
      eyePaint,
    );

    final browPaint =
        Paint()
          ..color = const Color(0xFF171E2C)
          ..strokeWidth = size.height * 0.04
          ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(
        center.dx - eyeOffsetX - size.width * 0.06,
        eyeOffsetY - size.height * 0.08,
      ),
      Offset(
        center.dx - eyeOffsetX + size.width * 0.04,
        eyeOffsetY - size.height * 0.1,
      ),
      browPaint,
    );
    canvas.drawLine(
      Offset(
        center.dx + eyeOffsetX - size.width * 0.04,
        eyeOffsetY - size.height * 0.1,
      ),
      Offset(
        center.dx + eyeOffsetX + size.width * 0.06,
        eyeOffsetY - size.height * 0.08,
      ),
      browPaint,
    );

    final nosePaint =
        Paint()
          ..color = const Color(0xFFEBC3AF)
          ..strokeWidth = size.width * 0.03
          ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(center.dx, eyeOffsetY + size.height * 0.02),
      Offset(center.dx, eyeOffsetY + size.height * 0.1),
      nosePaint,
    );

    final mouthPaint =
        Paint()
          ..color = const Color(0xFFE27D7D)
          ..strokeWidth = size.height * 0.05
          ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(
        center.dx - size.width * 0.11,
        faceRect.bottom - size.height * 0.15,
      ),
      Offset(
        center.dx + size.width * 0.11,
        faceRect.bottom - size.height * 0.15,
      ),
      mouthPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ChatPalette {
  static const background = Color(0xFF0E1420);
  static const surface = Color(0xFF151C2C);
  static const messageSurface = Color(0xFF1A2233);
  static const accent = Color(0xFF7B4DFF);
  static const accentDark = Color(0xFF4328B8);
  static const success = Color(0xFF3DD598);
  static const warning = Color(0xFFFFC542);
}

class _TypingBubble extends StatefulWidget {
  const _TypingBubble();

  @override
  State<_TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<_TypingBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const Padding(
          padding: EdgeInsets.only(right: 12),
          child: MaikaAvatar(size: 28),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: _ChatPalette.messageSurface,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
              bottomRight: Radius.circular(16),
              bottomLeft: Radius.circular(6),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Maika esta escribiendo',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(width: 12),
              Row(
                children: List.generate(
                  3,
                  (index) => FadeTransition(
                    opacity: CurvedAnimation(
                      parent: _controller,
                      curve: Interval(
                        index * 0.2,
                        (index * 0.2) + 0.8,
                        curve: Curves.easeIn,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Colors.white70,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MessageActions extends StatelessWidget {
  const _MessageActions({required this.message, required this.onFavorite});

  final ChatMessage message;
  final ValueChanged<bool> onFavorite;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: () => onFavorite(!message.isFavorite),
          icon: Icon(
            message.isFavorite ? Icons.star : Icons.star_border,
            color:
                message.isFavorite
                    ? _ChatPalette.accent
                    : Colors.white.withValues(alpha: 0.5),
            size: 22,
          ),
          tooltip: message.isFavorite ? 'Quitar de favoritos' : 'Guardar',
        ),
        IconButton(
          onPressed: () {
            final buffer =
                StringBuffer()
                  ..writeln(message.text)
                  ..writeln()
                  ..writeln('Compartido desde Maika');
            Share.share(buffer.toString());
          },
          icon: const Icon(Icons.ios_share, color: Colors.white54, size: 20),
          tooltip: 'Compartir',
        ),
      ],
    );
  }
}

class _SuggestionChips extends StatelessWidget {
  const _SuggestionChips({required this.suggestions, required this.onPressed});

  final List<ChatActionChip> suggestions;
  final ValueChanged<ChatActionChip> onPressed;

  @override
  Widget build(BuildContext context) {
    if (suggestions.isEmpty) {
      return const SizedBox.shrink();
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children:
            suggestions
                .map(
                  (chip) => Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: ActionChip(
                      backgroundColor: Colors.white.withValues(alpha: 0.06),
                      shape: StadiumBorder(
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.12),
                        ),
                      ),
                      label: Text(
                        chip.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      onPressed: () => onPressed(chip),
                    ),
                  ),
                )
                .toList(),
      ),
    );
  }
}

class _InputBar extends StatefulWidget {
  const _InputBar({
    required this.controller,
    required this.focusNode,
    required this.isOnline,
    required this.onSend,
    required this.status,
    this.onRetryPending,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isOnline;
  final VoidCallback onSend;
  final ChatViewStatus status;
  final VoidCallback? onRetryPending;

  @override
  State<_InputBar> createState() => _InputBarState();
}

class _InputBarState extends State<_InputBar> {
  bool _isComposing = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleInputChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleInputChanged);
    super.dispose();
  }

  void _handleInputChanged() {
    final composing = widget.controller.text.trim().isNotEmpty;
    if (composing != _isComposing) {
      setState(() => _isComposing = composing);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSending =
        widget.status == ChatViewStatus.sending ||
        widget.status == ChatViewStatus.receiving;
    final placeholder =
        widget.isOnline
            ? 'Escribe tu mensaje...'
            : 'Modo offline, envia para reintentar';

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      decoration: BoxDecoration(
        color: _ChatPalette.background,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!widget.isOnline)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: _ChatPalette.warning.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.wifi_off, color: _ChatPalette.warning),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Estas offline. Guardaremos tus mensajes y los enviaremos cuando regreses.',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ),
                  if (widget.onRetryPending != null)
                    TextButton(
                      onPressed: widget.onRetryPending,
                      child: const Text('Reintentar'),
                    ),
                ],
              ),
            ),
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: _ChatPalette.surface,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.05),
                    width: 1,
                  ),
                ),
                padding: const EdgeInsets.all(14),
                child: const Icon(Icons.mic_none, color: Colors.white70),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _ChatPalette.surface,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.06),
                    ),
                  ),
                  child: TextField(
                    key: const ValueKey('chat_message_field'),
                    controller: widget.controller,
                    focusNode: widget.focusNode,
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                    minLines: 1,
                    maxLines: 4,
                    autofillHints: const [AutofillHints.name],
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: placeholder,
                      hintStyle: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 14,
                      ),
                    ),
                    onSubmitted: (_) {
                      if (_isComposing) {
                        widget.onSend();
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: (_isComposing && !isSending) ? widget.onSend : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 56,
                  width: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient:
                        _isComposing && !isSending
                            ? const LinearGradient(
                              colors: [
                                _ChatPalette.accent,
                                _ChatPalette.accentDark,
                              ],
                            )
                            : LinearGradient(
                              colors: [
                                Colors.white.withValues(alpha: 0.1),
                                Colors.white.withValues(alpha: 0.05),
                              ],
                            ),
                    boxShadow: [
                      BoxShadow(
                        color: _ChatPalette.accent.withValues(
                          alpha: _isComposing ? 0.6 : 0.0,
                        ),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Icon(
                    isSending ? Icons.hourglass_top : Icons.send_rounded,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ListMessageContent extends StatelessWidget {
  const _ListMessageContent({required this.message, required this.textColor});

  final ChatMessage message;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          message.text,
          style: TextStyle(
            color: textColor,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children:
                message.listItems
                    .map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '•',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.title,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  if (item.description.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      item.description,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 13,
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                  if (item.reference != null &&
                                      item.reference!.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      item.reference!,
                                      style: TextStyle(
                                        color: _ChatPalette.accent,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
          ),
        ),
      ],
    );
  }
}

class _ImageMessageContent extends StatelessWidget {
  const _ImageMessageContent({required this.message, required this.textColor});

  final ChatMessage message;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (message.text.isNotEmpty)
          Text(
            message.text,
            style: TextStyle(
              color: textColor,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            children: [
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _ChatPalette.accent.withValues(alpha: 0.2),
                        Colors.black.withValues(alpha: 0.6),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),
              if (message.imageUrl != null && message.imageUrl!.isNotEmpty)
                Ink.image(
                  image: NetworkImage(message.imageUrl!),
                  fit: BoxFit.cover,
                  height: 180,
                  width: double.infinity,
                )
              else
                Container(
                  height: 180,
                  alignment: Alignment.center,
                  color: Colors.black.withValues(alpha: 0.4),
                  child: const Icon(
                    Icons.image,
                    size: 42,
                    color: Colors.white54,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({
    required this.message,
    required this.showAvatar,
    required this.onFavorite,
    this.onQuickReply,
  });

  final ChatMessage message;
  final bool showAvatar;
  final ValueChanged<bool> onFavorite;
  final ValueChanged<ChatActionChip>? onQuickReply;

  @override
  Widget build(BuildContext context) {
    final isUser = message.type == MessageType.user;
    final alignment = isUser ? MainAxisAlignment.end : MainAxisAlignment.start;
    final bubbleColor =
        isUser ? _ChatPalette.accent : _ChatPalette.messageSurface;
    final textColor =
        isUser ? Colors.white : Colors.white.withValues(alpha: 0.9);
    final maxWidth = min(MediaQuery.of(context).size.width * 0.75, 420.0);

    final statusIcon = isUser ? _statusIcon(message.status) : null;
    final statusColor = isUser ? _statusColor(message.status) : null;

    Widget content = Column(
      crossAxisAlignment:
          isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        if (message.contentType == MessageContentType.list)
          _ListMessageContent(message: message, textColor: textColor)
        else if (message.contentType == MessageContentType.image)
          _ImageMessageContent(message: message, textColor: textColor)
        else
          Text(
            message.text,
            style: TextStyle(color: textColor, fontSize: 15, height: 1.5),
          ),
        const SizedBox(height: 10),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (message.generated && !isUser)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.auto_awesome,
                    color: _ChatPalette.accent,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'generado',
                    style: TextStyle(
                      color: _ChatPalette.accent.withValues(alpha: 0.9),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
              ),
            Text(
              formatRelativeTime(message.timestamp),
              style: TextStyle(
                color: Colors.white70.withValues(alpha: 0.8),
                fontSize: 11,
              ),
            ),
            if (statusIcon != null) ...[
              const SizedBox(width: 8),
              Icon(statusIcon, color: statusColor, size: 14),
            ],
          ],
        ),
      ],
    );

    if (!isUser) {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          content,
          if (message.quickReplies.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children:
                  message.quickReplies
                      .map(
                        (chip) => ActionChip(
                          backgroundColor: Colors.white.withValues(alpha: 0.05),
                          shape: StadiumBorder(
                            side: BorderSide(
                              color: Colors.white.withValues(alpha: 0.12),
                            ),
                          ),
                          label: Text(
                            chip.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          onPressed:
                              onQuickReply == null
                                  ? null
                                  : () => onQuickReply!(chip),
                        ),
                      )
                      .toList(),
            ),
          ],
        ],
      );
    }

    return Row(
      mainAxisAlignment: alignment,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (!isUser)
          AnimatedOpacity(
            opacity: showAvatar ? 1 : 0,
            duration: const Duration(milliseconds: 200),
            child:
                showAvatar
                    ? const Padding(
                      padding: EdgeInsets.only(right: 12),
                      child: MaikaAvatar(size: 36),
                    )
                    : const SizedBox(width: 48),
          ),
        Flexible(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isUser ? 20 : 6),
                  bottomRight: Radius.circular(isUser ? 6 : 20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: content,
            ),
          ),
        ),
        if (isUser)
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: _ChatPalette.accent.withValues(alpha: 0.2),
              child: const Icon(Icons.person, color: Colors.white),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: _MessageActions(message: message, onFavorite: onFavorite),
          ),
      ],
    );
  }

  IconData? _statusIcon(MessageDeliveryStatus status) {
    switch (status) {
      case MessageDeliveryStatus.pending:
        return Icons.access_time_rounded;
      case MessageDeliveryStatus.sent:
        return Icons.check_rounded;
      case MessageDeliveryStatus.delivered:
        return Icons.done_all_rounded;
      case MessageDeliveryStatus.error:
        return Icons.error_outline;
    }
  }

  Color _statusColor(MessageDeliveryStatus status) {
    switch (status) {
      case MessageDeliveryStatus.pending:
        return Colors.white70;
      case MessageDeliveryStatus.sent:
        return Colors.white;
      case MessageDeliveryStatus.delivered:
        return _ChatPalette.success;
      case MessageDeliveryStatus.error:
        return _ChatPalette.warning;
    }
  }
}

class _ChatHeader extends StatelessWidget {
  const _ChatHeader({required this.isConnected});

  final bool isConnected;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _ChatPalette.background,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: Row(
        children: [
          const MaikaAvatar(size: 54),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Maika (BETA)',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Tu asistente biblico',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color:
                          isConnected
                              ? _ChatPalette.success
                              : _ChatPalette.warning,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color:
                              isConnected
                                  ? _ChatPalette.success.withValues(alpha: 0.6)
                                  : _ChatPalette.warning.withValues(alpha: 0.6),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isConnected ? 'Conectado a Rasa' : 'Sin conexion',
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            onPressed:
                () => context.read<ChatBloc>().add(
                  const ChatPendingRetryRequested(),
                ),
            icon: const Icon(Icons.sync, color: Colors.white70),
            tooltip: 'Sincronizar pendientes',
          ),
        ],
      ),
    );
  }
}
