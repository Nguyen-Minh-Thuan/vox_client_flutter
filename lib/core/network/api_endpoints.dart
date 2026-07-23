import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiEndpoints {
  static String get graphqlBaseUrl => baseUrl.replaceFirst(RegExp(r'/api/?$'), '');

  static const String login = "/v1/auth/login";
  static const String pushToken = "/v1/devices/push-token";

  static const String classTests = "/v1/class-tests";
  static String classTestById(String id) => "/v1/class-tests/$id";
  static String classTestQuestions(String id) => "/v1/class-tests/$id/questions";
  static String classTestStatus(String id) => "/v1/class-tests/$id/status";
}