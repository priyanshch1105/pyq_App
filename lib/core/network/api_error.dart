import 'package:dio/dio.dart';

String parseApiError(Object error) {
  if (error is DioException) {
    final status = error.response?.statusCode;
    final data = error.response?.data;
    if (data is Map<String, dynamic> && data['detail'] != null) {
      return data['detail'].toString();
    }
    if (status == 401) return 'Unauthorized. Please login again.';
    if (status == 403) return 'Premium subscription required for this action.';
    if (status == 404) return 'Resource not found.';
    if (status != null) return 'Request failed with status $status.';
    return 'Network error. Check server connection.';
  }
  return 'Something went wrong.';
}
