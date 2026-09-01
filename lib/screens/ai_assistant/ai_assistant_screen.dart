import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../services/ai_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> with TickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final AiService _aiService = AiService();
  final ImagePicker _picker = ImagePicker();

  final List<Map<String, dynamic>> _messages = [
    {
      'isUser': false,
      'text': "Bonjour ! Je suis Stankap AI, votre assistant financier intelligent.\n\nDemandez-moi d'ajouter une transaction (ex: 'J'ai mangé au resto pour 25€') ou prenez une photo de votre ticket de caisse !",
    }
  ];
  bool _isLoading = false;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    
    setState(() {
      _messages.add({'isUser': true, 'text': text});
      _isLoading = true;
    });
    _controller.clear();
    _scrollToBottom();

    final response = await _aiService.sendChatMessage(text);
    
    setState(() {
      _isLoading = false;
      _messages.add({
        'isUser': false,
        'text': response['message'],
        'action': response['action'],
        'transaction_data': response['transaction_data'],
      });
    });
    _scrollToBottom();
  }

  Future<void> _scanReceipt() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image == null) return;

    setState(() {
      _messages.add({'isUser': true, 'text': "📸 Envoi d'un ticket de caisse..."});
      _isLoading = true;
    });
    _scrollToBottom();

    final response = await _aiService.scanReceipt(File(image.path));
    
    setState(() {
      _isLoading = false;
      if (response != null && !response.containsKey('error')) {
        _messages.add({
          'isUser': false,
          'text': "J'ai analysé votre ticket de caisse !\nMontant: ${response['amount']}€\nMarchand: ${response['merchant']}\nCatégorie: ${response['category_id']}",
          'action': 'confirm_transaction',
          'transaction_data': response,
        });
      } else {
        _messages.add({
          'isUser': false,
          'text': "Désolé, je n'ai pas pu lire ce ticket de caisse.",
        });
      }
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _confirmTransaction(Map<String, dynamic> data) {
    // Add logic to save the transaction to the database
    // via TransactionProvider or API
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Transaction ajoutée avec succès !')),
    );
    Navigator.pop(context); // Optional: close assistant or just show success
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.auto_awesome, color: AppTheme.primary),
            const SizedBox(width: 8),
            Text('Stankap AI', style: GoogleFonts.poppins(color: AppTheme.primary, fontWeight: FontWeight.bold)),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg['isUser'];
                return _buildChatBubble(msg, isUser);
              },
            ),
          ),
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FadeTransition(
                    opacity: _pulseController,
                    child: const Icon(Icons.auto_awesome, color: AppTheme.primary, size: 24),
                  ),
                  const SizedBox(width: 8),
                  Text("L'IA réfléchit...", style: TextStyle(color: AppTheme.textHint, fontStyle: FontStyle.italic)),
                ],
              ),
            ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildChatBubble(Map<String, dynamic> msg, bool isUser) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isUser ? AppTheme.primary : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isUser ? 20 : 0),
            bottomRight: Radius.circular(isUser ? 0 : 20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              msg['text'],
              style: GoogleFonts.poppins(
                color: isUser ? Colors.white : AppTheme.textPrimary,
                fontSize: 14,
              ),
            ),
            if (msg['action'] == 'confirm_transaction' && msg['transaction_data'] != null) ...[
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => _confirmTransaction(msg['transaction_data']),
                icon: const Icon(Icons.check_circle_outline, size: 18),
                label: const Text('Confirmer & Ajouter'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryLight,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  minimumSize: const Size(0, 36),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, -4),
          )
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: _scanReceipt,
            icon: const Icon(Icons.document_scanner_rounded, color: AppTheme.primary),
            tooltip: "Scanner un ticket",
          ),
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: "Écrivez une dépense...",
                hintStyle: const TextStyle(color: AppTheme.textHint),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: AppTheme.background,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              onSubmitted: _sendMessage,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.primary,
            ),
            child: IconButton(
              icon: const Icon(Icons.send_rounded, color: Colors.white),
              onPressed: () => _sendMessage(_controller.text),
            ),
          ),
        ],
      ),
    );
  }
}
