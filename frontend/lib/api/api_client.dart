import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:schematiq/config/app_config.dart';
import 'package:schematiq/providers/auth_provider.dart';

// This provider creates a basic, non-authenticated Dio instance.
// Its only job is to know the base URL and timeouts.
final dioProvider = Provider<Dio>((ref) {
  return Dio(BaseOptions(
    baseUrl: AppConfig.apiBaseUrl,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 30),
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
  ));
});

// THIS IS THE KEY TO THE FIX:
// A custom interceptor class that holds a reference to the provider container.
class AuthInterceptor extends Interceptor {
  final Ref _ref;

  AuthInterceptor(this._ref);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Read the current auth state dynamically from the provider.
    // We use .read() here because this is a callback, not a build method.
    // This gets the LATEST value at the moment of the request.
    final authState = _ref.read(authTokenProvider).value;
    final token = authState?.token;

    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    
    // Continue with the request.
    super.onRequest(options, handler);
  }
}