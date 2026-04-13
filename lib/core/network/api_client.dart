import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/token_store.dart';

const baseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://pyq-app-0h48.onrender.com',
);

String _normalizedBaseUrl() {
  final trimmed = baseUrl.trim();
  if (trimmed.endsWith('/')) {
    return trimmed.substring(0, trimmed.length - 1);
  }
  return trimmed;
}

bool _isRetryable(DioException error) {
  if (error.type == DioExceptionType.connectionTimeout ||
      error.type == DioExceptionType.receiveTimeout ||
      error.type == DioExceptionType.connectionError) {
    return true;
  }
  final code = error.response?.statusCode;
  return code != null && code >= 500;
}

final tokenStoreProvider = Provider<TokenStore>((ref) => TokenStore());

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: _normalizedBaseUrl(),
      connectTimeout: const Duration(seconds: 45),
      receiveTimeout: const Duration(seconds: 60),
    ),
  );
  final tokenStore = ref.read(tokenStoreProvider);

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await tokenStore.read();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (err, handler) async {
        final retried = err.requestOptions.extra['__retried'] == true;
        if (!retried && _isRetryable(err)) {
          err.requestOptions.extra['__retried'] = true;
          try {
            final response = await dio.fetch(err.requestOptions);
            handler.resolve(response);
            return;
          } on DioException catch (_) {
            // Fall through and return original error if retry also fails.
          }
        }
        handler.next(err);
      },
    ),
  );
  return dio;
});
