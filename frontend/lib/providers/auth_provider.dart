import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:schematiq/api/api_client.dart';

// A simple data class to hold the full authentication state.
class AuthState {
  final String? token;
  final String? tier;
  AuthState({this.token, this.tier});

  bool get isPaidUser => tier == 'paid';
}

// The FutureProvider that handles fetching the auth token.
// It depends ONLY on the basic dioProvider.
final authTokenProvider = FutureProvider<AuthState>((ref) async {
  final dio = ref.watch(dioProvider);

  try {
    // To test the "free" user experience, you can change the URL to:
    // final response = await dio.get('/auth/get_token?tier=free');
    final response = await dio.get('/auth/get_token');
    
    if (response.statusCode == 200) {
      final token = response.data['token'];
      final tier = response.data['tier'];
      return AuthState(token: token, tier: tier);
    }
    return AuthState();
  } catch (e) {
    print("Authentication failed: $e");
    return AuthState();
  }
});