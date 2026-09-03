import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late Dio dio;
  final _storage = const FlutterSecureStorage();
  
  // Base URL for the Django production backend
  final String baseUrl = 'https://stankap.pythonanywhere.com/api';

  ApiClient._internal() {
    dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ));

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: 'access_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (DioException e, handler) async {
        if (e.response?.statusCode == 401) {
          // Token expired, try to refresh
          final refreshToken = await _storage.read(key: 'refresh_token');
          if (refreshToken != null) {
            try {
              final response = await Dio().post(
                '$baseUrl/auth/refresh/',
                data: {'refresh': refreshToken},
              );
              
              final newAccessToken = response.data['access'];
              await _storage.write(key: 'access_token', value: newAccessToken);
              
              // Retry the original request
              e.requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
              final cloneReq = await Dio().request(
                e.requestOptions.path,
                options: Options(
                  method: e.requestOptions.method,
                  headers: e.requestOptions.headers,
                ),
                data: e.requestOptions.data,
                queryParameters: e.requestOptions.queryParameters,
              );
              return handler.resolve(cloneReq);
            } catch (refreshError) {
              // Refresh failed, clear tokens
              await _storage.delete(key: 'access_token');
              await _storage.delete(key: 'refresh_token');
              await _storage.delete(key: 'current_user_id');
            }
          }
        }
        return handler.next(e);
      },
    ));
  }
}
