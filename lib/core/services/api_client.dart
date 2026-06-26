import 'package:dio/dio.dart';

const _kBaseUrl = 'https://backend.wamatoestatesmanagementuganda.online';

class ApiException implements Exception {
  final int statusCode;
  final String message;
  const ApiException(this.statusCode, this.message);
  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// Singleton Dio instance — shared connection pool, cached DNS, keep-alive.
final _dio = Dio(BaseOptions(
  baseUrl: _kBaseUrl,
  connectTimeout: const Duration(seconds: 10),
  receiveTimeout: const Duration(seconds: 15),
  headers: {'Content-Type': 'application/json'},
))
  ..interceptors.add(LogInterceptor(
    requestBody: false,
    responseBody: false,
    error: true,
  ));

class ApiClient {
  final String? accessToken;

  const ApiClient({this.accessToken});

  Options get _opts => Options(
        headers: {
          if (accessToken != null) 'Authorization': 'Bearer $accessToken',
        },
      );

  Future<dynamic> get(String path, [Map<String, dynamic>? params]) async {
    try {
      final res = await _dio.get(
        path,
        queryParameters: params,
        options: _opts,
      );
      return res.data;
    } on DioException catch (e) {
      _throw(e);
    }
  }

  Future<dynamic> post(String path, Map<String, dynamic> body) async {
    try {
      final res = await _dio.post(path, data: body, options: _opts);
      return res.data;
    } on DioException catch (e) {
      _throw(e);
    }
  }

  Future<dynamic> patch(String path, Map<String, dynamic> body) async {
    try {
      final res = await _dio.patch(path, data: body, options: _opts);
      return res.data;
    } on DioException catch (e) {
      _throw(e);
    }
  }

  Future<dynamic> delete(String path) async {
    try {
      final res = await _dio.delete(path, options: _opts);
      return res.data;
    } on DioException catch (e) {
      _throw(e);
    }
  }

  Never _throw(DioException e) {
    final code = e.response?.statusCode ?? 0;
    final data = e.response?.data;
    String msg;
    if (data is Map) {
      final detail = data['detail'];
      if (detail is List && detail.isNotEmpty) {
        // FastAPI validation error — extract first human-readable message
        final first = detail.first;
        String raw = (first is Map ? first['msg'] : detail.toString()).toString();
        // FastAPI prefixes custom validators with "Value error, " — strip it
        msg = raw.replaceFirst('Value error, ', '');
      } else {
        msg = (detail ?? e.message ?? 'Request failed').toString();
      }
    } else if (code == 0) {
      msg = 'No internet connection. Please check your network.';
    } else {
      msg = e.message ?? 'Request failed';
    }
    throw ApiException(code, msg);
  }
}
