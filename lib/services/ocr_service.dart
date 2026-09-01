import 'dart:io';
import 'package:image_picker/image_picker.dart';

/// OCR Service - receipt scanning is handled via the AI service (ai_service.dart).
/// This stub is kept for compatibility.
class OCRService {
  Future<Map<String, dynamic>?> scanReceipt() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera);
    if (image == null) return null;

    return _parseReceiptFromFile(File(image.path));
  }

  Future<Map<String, dynamic>?> _parseReceiptFromFile(File file) async {
    // OCR scanning is handled by the AI service (Gemini Vision).
    // This method is a stub; use AiService.scanReceipt() directly.
    return null;
  }

  void dispose() {}
}
