import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:schematiq/api/api_service.dart';
import 'package:schematiq/config/app_config.dart';
import 'package:schematiq/models/plan_model.dart';
import 'package:schematiq/providers/auth_provider.dart';

// A simple data class to represent a single message in the chat.
class ChatMessage {
  final String text;
  final bool isFromUser;
  ChatMessage({required this.text, this.isFromUser = false});
}

class ChatModal extends ConsumerStatefulWidget {
  final PlanStep step;
  const ChatModal({super.key, required this.step});

  @override
  ConsumerState<ChatModal> createState() => _ChatModalState();
}

class _ChatModalState extends ConsumerState<ChatModal> {
  final _controller = TextEditingController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Add an initial greeting/prompt from the AI.
    _messages.add(ChatMessage(text: "Ask me anything about this step. For example: 'How can I do this with no budget?' or 'What's the first thing I should do?'"));
    // Request focus for the text field when the modal appears.
    WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // Helper method to auto-scroll to the latest message.
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final userMessage = _controller.text.trim();
    if (userMessage.isEmpty || _isLoading) return;
    
    _controller.clear();
    FocusScope.of(context).unfocus();

    setState(() {
      _messages.add(ChatMessage(text: userMessage, isFromUser: true));
      _isLoading = true;
    });
    _scrollToBottom();

    final apiService = ref.read(apiServiceProvider);
    final response = await apiService.askAiOnStep(
      stepDescription: widget.step.title,
      userQuestion: userMessage,
    );

    setState(() {
      _messages.add(ChatMessage(text: response ?? "Sorry, an error occurred. Please try again."));
      _isLoading = false;
    });
    _scrollToBottom();
  }
  
  @override
  Widget build(BuildContext context) {
    // Using Padding with viewInsets is the correct way to handle the keyboard.
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16, right: 16, top: 20,
      ),
      child: Column(
        // Use MainAxisSize.min with Flexible to prevent the modal from taking full screen height initially.
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Text(
            'Chat about: "${widget.step.title}"',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const Divider(height: 24, color: Colors.white24),
          
          // Chat messages area
          Flexible(
            child: ListView.builder(
              controller: _scrollController,
              shrinkWrap: true,
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return Align(
                  alignment: message.isFromUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                    margin: const EdgeInsets.symmetric(vertical: 5),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: message.isFromUser ? AppColors.primary : AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      message.text,
                      style: TextStyle(
                        color: message.isFromUser ? AppColors.background : AppColors.text,
                        fontWeight: message.isFromUser ? FontWeight.w500 : FontWeight.normal,
                        height: 1.4,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // "AI is typing..." indicator
          if (_isLoading)
            const Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text("SchematIQ is typing...", style: TextStyle(color: AppColors.textSecondary, fontStyle: FontStyle.italic)),
              ),
            ),
          
          // Input area
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  decoration: const InputDecoration(hintText: "Ask a follow-up..."),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.send_rounded, color: AppColors.primary),
                onPressed: _sendMessage,
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.primary.withOpacity(0.2),
                  padding: const EdgeInsets.all(12),
                ),
              )
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}