import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_error.dart';
import '../../core/network/api_client.dart';
import 'question_models.dart';

final questionRepositoryProvider = Provider<QuestionRepository>(
  (ref) => QuestionRepository(ref.read(dioProvider)),
);

class QuestionRepository {
  QuestionRepository(this._dio);
  final Dio _dio;

  Future<List<Question>> fetchQuestions({
    required String exam,
    String? subject,
    String? topic,
    int? year,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final res = await _dio.get(
        '/questions',
        queryParameters: {
          'exam': exam,
          'subject': subject,
          'topic': topic,
          'year': year,
          'limit': limit,
          'offset': offset,
        }..removeWhere((key, value) => value == null),
      );
      final data = List<Map<String, dynamic>>.from(res.data as List);
      return data.map(Question.fromJson).toList();
    } catch (e) {
      throw Exception(parseApiError(e));
    }
  }

  Future<Map<String, dynamic>> submitAttempt({
    required String questionId,
    required String selectedAnswer,
    required double timeTaken,
  }) async {
    try {
      final res = await _dio.post(
        '/attempt',
        data: {
          'question_id': questionId,
          'selected_answer': selectedAnswer,
          'time_taken': timeTaken,
        },
      );
      return Map<String, dynamic>.from(res.data as Map);
    } catch (e) {
      throw Exception(parseApiError(e));
    }
  }

  Future<Map<String, dynamic>> fetchPerformance() async {
    try {
      final res = await _dio.get('/performance');
      return Map<String, dynamic>.from(res.data as Map);
    } catch (e) {
      throw Exception(parseApiError(e));
    }
  }

  Future<List<Map<String, dynamic>>> fetchRecommendations() async {
    try {
      final res = await _dio.get('/recommendations');
      return List<Map<String, dynamic>>.from(res.data as List);
    } catch (e) {
      throw Exception(parseApiError(e));
    }
  }
}
