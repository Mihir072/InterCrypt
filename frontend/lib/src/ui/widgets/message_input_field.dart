import 'package:flutter/material.dart';

/// Message Input Field Widget - for composing and sending messages
class MessageInputField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onSendPressed;
  final VoidCallback? onAttachmentPressed;
  final VoidCallback? onEmojiPressed;
  final bool isLoading;
  final int? maxLines;
  final int? minLines;

  const MessageInputField({
    Key? key,
    required this.controller,
    required this.focusNode,
    this.onChanged,
    this.onSendPressed,
    this.onAttachmentPressed,
    this.onEmojiPressed,
    this.isLoading = false,
    this.maxLines,
    this.minLines,
  }) : super(key: key);

  @override
  State<MessageInputField> createState() => _MessageInputFieldState();
}

class _MessageInputFieldState extends State<MessageInputField> {
  late FocusNode _localFocusNode;
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _localFocusNode = FocusNode();
    _controller = widget.controller;
    _controller.addListener(_updateUI);
  }

  @override
  void dispose() {
    _controller.removeListener(_updateUI);
    _localFocusNode.dispose();
    super.dispose();
  }

  void _updateUI() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final canSend = _controller.text.trim().isNotEmpty && !widget.isLoading;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outline,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Attachment button
          IconButton(
            icon: const Icon(Icons.attach_file),
            onPressed: widget.isLoading ? null : widget.onAttachmentPressed,
            tooltip: 'Attach file',
          ),

          // Message input field
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: widget.focusNode,
              onChanged: widget.onChanged,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                suffixIcon: _controller.text.isNotEmpty
                    ? Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _controller.clear();
                            setState(() {});
                          },
                          tooltip: 'Clear',
                        ),
                      )
                    : null,
              ),
              maxLines: widget.maxLines ?? 4,
              minLines: widget.minLines ?? 1,
              textCapitalization: TextCapitalization.sentences,
              enableInteractiveSelection: true,
            ),
          ),

          // Emoji button (placeholder)
          IconButton(
            icon: const Icon(Icons.emoji_emotions_outlined),
            onPressed: widget.isLoading ? null : widget.onEmojiPressed,
            tooltip: 'Emoji',
          ),

          // Send button
          SizedBox(
            width: 40,
            child: IconButton(
              icon: widget.isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    )
                  : const Icon(Icons.send),
              onPressed: canSend ? widget.onSendPressed : null,
              tooltip: 'Send',
            ),
          ),
        ],
      ),
    );
  }
}
