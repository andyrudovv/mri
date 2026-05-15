import 'package:dio/dio.dart';

/// Calls `POST /api/analysis/generate-summary` (Gemini-backed when configured on the server).
class AnalysisSummaryApi {
  static const String baseUrl = 'http://127.0.0.1:8000';

  static Map<String, dynamic> _coerceProbabilityMap(Map<String, dynamic> raw) {
    final out = <String, dynamic>{};
    for (final e in raw.entries) {
      final v = e.value;
      if (v is num) {
        out[e.key.toString()] = v.toDouble();
      } else if (v is String) {
        out[e.key.toString()] = double.tryParse(v) ?? 0.0;
      }
    }
    return out;
  }

  static Future<String?> fetchGenerativeSummary({
    required String token,
    required String predictedClass,
    required Map<String, dynamic> probabilities,
  }) async {
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        sendTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 60),
      ),
    );
    final response = await dio.post<Map<String, dynamic>>(
      '/api/analysis/generate-summary',
      data: <String, dynamic>{
        'predictedClass': predictedClass,
        'probabilities': _coerceProbabilityMap(probabilities),
      },
      options: Options(headers: <String, dynamic>{'Authorization': 'Bearer $token'}),
    );
    final data = response.data;
    if (response.statusCode == 200 && data != null) {
      return data['aiSummary'] as String?;
    }
    return null;
  }
}
