import 'package:flutter_test/flutter_test.dart';
import 'package:quran/services/api_exception.dart';
import 'package:quran/services/api_response_parser.dart';

ApiException _catchParse(int status, String body) {
  try {
    ApiResponseParser.parse(status, body);
  } on ApiException catch (e) {
    return e;
  }
  fail('Expected ApiException for status $status');
}

void main() {
  group('ApiResponseParser.parse', () {
    test('returns decoded JSON on 200', () {
      final data = ApiResponseParser.parse(
        200,
        '{"token":"abc","role":"admin"}',
      );
      expect(data['token'], 'abc');
      expect(data['role'], 'admin');
    });

    test('returns decoded JSON on 201', () {
      final data = ApiResponseParser.parse(201, '{"id":1}');
      expect(data['id'], 1);
    });

    test('maps status codes to typed errors', () {
      expect(
        _catchParse(401, '{"message":"x"}').type,
        ApiErrorType.unauthorized,
      );
      expect(_catchParse(403, '{"message":"x"}').type, ApiErrorType.forbidden);
      expect(_catchParse(404, '{"message":"x"}').type, ApiErrorType.notFound);
      expect(_catchParse(422, '{"message":"x"}').type, ApiErrorType.validation);
    });

    test('keeps the status code on the exception', () {
      expect(_catchParse(401, '{"message":"x"}').statusCode, 401);
    });

    test('treats every 5xx as a server error', () {
      expect(_catchParse(500, '').type, ApiErrorType.server);
      expect(_catchParse(502, '').type, ApiErrorType.server);
      expect(_catchParse(503, '').type, ApiErrorType.server);
    });

    test('does not crash when an error body is not JSON', () {
      final e = _catchParse(404, '<html>Not Found</html>');
      expect(e.type, ApiErrorType.notFound);
    });

    test('a 200 response with invalid JSON is a parse error', () {
      expect(_catchParse(200, 'not json').type, ApiErrorType.parse);
    });

    test('unexpected status codes are unknown errors', () {
      expect(_catchParse(418, '').type, ApiErrorType.unknown);
    });
  });

  group('error message extraction', () {
    test('translates known server message keys', () {
      final e = _catchParse(401, '{"message":"messages.account_blocked"}');
      expect(e.message.contains('محظور'), isTrue);
    });

    test('translates the first validation error', () {
      final e = _catchParse(
        422,
        '{"errors":{"number":["The number field is required."]}}',
      );
      expect(e.message, 'رقم الهاتف مطلوب');
    });

    test('translates Laravel credential message', () {
      final e = _catchParse(
        401,
        '{"message":"These credentials do not match our records."}',
      );
      expect(e.message, 'بيانات الاعتماد غير صحيحة');
    });

    test('falls back to a default message when the body has no message', () {
      final e = _catchParse(422, '{}');
      expect(e.message.isNotEmpty, isTrue);
    });
  });
}
