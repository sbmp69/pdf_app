import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:dart_openai/dart_openai.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';

class PdfChatPage extends StatefulWidget {
  final String pdfPath;

  const PdfChatPage({super.key, required this.pdfPath});

  @override
  State<PdfChatPage> createState() => _PdfChatPageState();
}

class _PdfChatPageState extends State<PdfChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, dynamic>> _messages = []; 
  final ScrollController _scrollController = ScrollController();
  
  bool _isLoading = false;
  bool _isExtracting = true;
  String _pdfText = '';

  @override
  void initState() {
    super.initState();
    _checkApiKeyAndInit();
  }

  Future<void> _checkApiKeyAndInit() async {
    // Read from .env file
    OpenAI.apiKey = dotenv.env['OPENAI_API_KEY'] ?? '';
    OpenAI.baseUrl = "https://openrouter.ai/api"; // dart_openai appends /v1 automatically
    
    _extractPdfText();
  }



  Future<void> _extractPdfText() async {
    setState(() => _isExtracting = true);
    try {
      final file = File(widget.pdfPath);
      final bytes = await file.readAsBytes();
      final document = PdfDocument(inputBytes: bytes);
      final extractor = PdfTextExtractor(document);
      
      String extractedText = extractor.extractText();
      
      // Limit text if it's too huge to save tokens
      if (extractedText.length > 10000) {
        extractedText = extractedText.substring(0, 10000);
      }
      
      _pdfText = extractedText;
      
      // Initial prompt to summarize
      await _sendMessage("Please provide a concise summary of this document.", isInitialSummary: true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to extract text: $e')));
    } finally {
      if (mounted) setState(() => _isExtracting = false);
    }
  }

  Future<void> _sendMessage(String text, {bool isInitialSummary = false}) async {
    if (text.trim().isEmpty) return;
    
    // Check rate limit if this is a manual chat
    if (!isInitialSummary) {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      final currentMonth = '${now.year}-${now.month}';
      
      final savedMonth = prefs.getString('pdf_chat_month') ?? '';
      int chatCount = prefs.getInt('pdf_chat_count') ?? 0;
      
      if (savedMonth != currentMonth) {
        await prefs.setString('pdf_chat_month', currentMonth);
        chatCount = 0;
        await prefs.setInt('pdf_chat_count', 0);
      }
      
      if (chatCount >= 2) {
        setState(() {
          _messages.add({'role': 'user', 'text': text});
          _messages.add({
            'role': 'ai', 
            'text': 'You have reached the free tier limit of 2 chats per month. Please upgrade to Pro for unlimited access.'
          });
        });
        _messageController.clear();
        _scrollToBottom();
        return;
      }
      
      // Increment counter for allowed chat
      await prefs.setInt('pdf_chat_count', chatCount + 1);
    }
    
    if (!isInitialSummary) {
      setState(() {
        _messages.add({'role': 'user', 'text': text});
        _isLoading = true;
      });
      _messageController.clear();
      _scrollToBottom();
    } else {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final List<OpenAIChatCompletionChoiceMessageModel> apiMessages = [
        OpenAIChatCompletionChoiceMessageModel(
          role: OpenAIChatMessageRole.system,
          content: [
            OpenAIChatCompletionChoiceMessageContentItemModel.text(
              "You are an AI assistant helping a user understand a PDF document. Answer their questions based ONLY on the following text extracted from the document. If the answer is not in the text, say so.\n\nDocument Text:\n$_pdfText",
            ),
          ],
        ),
      ];

      // Only send the last 6 messages to save history tokens
      final recentMessages = _messages.length > 6 ? _messages.sublist(_messages.length - 6) : _messages;
      
      for (var msg in recentMessages) {
        apiMessages.add(
          OpenAIChatCompletionChoiceMessageModel(
            role: msg['role'] == 'user' ? OpenAIChatMessageRole.user : OpenAIChatMessageRole.assistant,
            content: [
              OpenAIChatCompletionChoiceMessageContentItemModel.text(msg['text']),
            ],
          ),
        );
      }

      if (isInitialSummary) {
         apiMessages.add(
          OpenAIChatCompletionChoiceMessageModel(
            role: OpenAIChatMessageRole.user,
            content: [
              OpenAIChatCompletionChoiceMessageContentItemModel.text(text),
            ],
          ),
        );
      }

      final chatCompletion = await OpenAI.instance.chat.create(
        model: "inclusionai/ling-3.1-flash", // Free model from OpenRouter
        messages: apiMessages,
      );

      final aiResponse = chatCompletion.choices.first.message.content?.first.text ?? 'No response generated.';

      setState(() {
        _messages.add({'role': 'ai', 'text': aiResponse});
      });
      _scrollToBottom();
    } catch (e) {
      String errorMessage = 'Sorry, an unexpected error occurred. Please try again.';
      
      if (e is RequestFailedException) {
        if (e.statusCode == 401) {
          errorMessage = 'Your OpenAI API Key is invalid or expired. Please update it in the Settings page or use a different key.';
        } else if (e.statusCode == 429) {
          errorMessage = 'You have exceeded your OpenAI quota. Please check your billing details.';
        } else {
          errorMessage = 'OpenAI Error: ${e.message}';
        }
      } else {
        errorMessage = 'Error: $e';
      }

      setState(() {
        _messages.add({'role': 'ai', 'text': errorMessage});
      });
      _scrollToBottom();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat with AI'),
      ),
      body: _isExtracting 
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Extracting text from PDF...'),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      final isUser = msg['role'] == 'user';
                      return Align(
                        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isUser 
                                ? Theme.of(context).colorScheme.primaryContainer 
                                : Theme.of(context).colorScheme.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.85,
                          ),
                          child: MarkdownBody(
                            data: msg['text'] ?? '',
                            selectable: true,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: CircularProgressIndicator(),
                  ),
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          decoration: InputDecoration(
                            hintText: 'Ask a question about the PDF...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          onSubmitted: (val) => _sendMessage(val),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FloatingActionButton(
                        mini: true,
                        onPressed: _isLoading ? null : () => _sendMessage(_messageController.text),
                        child: const Icon(Icons.send),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
