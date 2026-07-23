import 'package:dio/dio.dart';

import '../storage/secure_storage.dart';
import 'api_endpoints.dart';

class GraphQLException implements Exception {
  final String message;
  GraphQLException(this.message);

  @override
  String toString() => message;
}

class GraphQLClient {
  GraphQLClient({SecureStorage? secureStorage, Dio? dio})
      : _secureStorage = secureStorage ?? SecureStorage(),
        _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: ApiEndpoints.graphqlBaseUrl,
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 15),
                sendTimeout: const Duration(seconds: 15),
                contentType: Headers.jsonContentType,
                responseType: ResponseType.json,
              ),
            ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _secureStorage.getAccessToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
    );
  }

  final SecureStorage _secureStorage;
  final Dio _dio;

  Future<Map<String, dynamic>> query(
    String query, {
    Map<String, dynamic>? variables,
  }) async {
    final response = await _dio.post('/graphql', data: {
      'query': query,
      if (variables != null) 'variables': variables,
    });

    final errors = response.data['errors'];
    if (errors != null) {
      throw GraphQLException(errors[0]['message'] as String);
    }

    return response.data['data'] as Map<String, dynamic>;
  }
}
