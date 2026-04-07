import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_error.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/token_store.dart';

final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<bool>>(
  (ref) => AuthController(ref.read(dioProvider), ref.read(tokenStoreProvider)),
);

class AuthController extends StateNotifier<AsyncValue<bool>> {
  AuthController(this._dio, this._tokenStore) : super(const AsyncValue.data(false));

  final Dio _dio;
  final TokenStore _tokenStore;

  Future<void> restoreSession() async {
    final token = await _tokenStore.read();
    state = AsyncValue.data(token != null && token.isNotEmpty);
  }

  Future<void> logout() async {
    await _tokenStore.clear();
    state = const AsyncValue.data(false);
  }

  Future<bool> login(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final res = await _dio.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      );
      await _tokenStore.save(res.data['access_token'] as String);
      state = const AsyncValue.data(true);
      return true;
    } catch (e) {
      state = AsyncValue.error(parseApiError(e), StackTrace.current);
      return false;
    }
  }

  Future<bool> register(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final res = await _dio.post(
        '/auth/register',
        data: {'email': email, 'password': password},
      );
      await _tokenStore.save(res.data['access_token'] as String);
      state = const AsyncValue.data(true);
      return true;
    } catch (e) {
      state = AsyncValue.error(parseApiError(e), StackTrace.current);
      return false;
    }
  }
}
