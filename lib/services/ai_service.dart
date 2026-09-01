import '../core/api/api_client.dart';
import 'dart:io';
import 'package:dio/dio.dart';

class AiService {
  final ApiClient _api = ApiClient();

  Future<Map<String, dynamic>> sendChatMessage(String message) async {
    try {
      final response = await _api.dio.post('/ai/chat/', data: {
        'message': message,
      });
      return response.data;
    } catch (e) {
      return {'action': 'chat_response', 'message': "Erreur de connexion avec l'assistant."};
    }
  }

  Future<Map<String, dynamic>?> scanReceipt(File imageFile) async {
    try {
      String fileName = imageFile.path.split('/').last;
      FormData formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(imageFile.path, filename: fileName),
      });

      final response = await _api.dio.post('/ai/scan-receipt/', data: formData);
      return response.data;
    } catch (e) {
      return null;
    }
  }
}
