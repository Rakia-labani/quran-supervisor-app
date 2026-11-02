import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:quran/constants/constants.dart';
import 'package:quran/services/api_exception.dart';

void main() {
  group('ApiException.from', () {
    test('keeps an ApiException as is', () {
      const original = ApiException(ApiErrorType.forbidden, 'x');
      expect(identical(ApiException.from(original), original), isTrue);
    });

    test('TimeoutException becomes a timeout error', () {
      expect(
        ApiException.from(TimeoutException('t')).type,
        ApiErrorType.timeout,
      );
    });

    test('SocketException becomes a network error', () {
      expect(
        ApiException.from(const SocketException('no route')).type,
        ApiErrorType.network,
      );
    });

    test('FormatException becomes a parse error', () {
      expect(
        ApiException.from(const FormatException('bad')).type,
        ApiErrorType.parse,
      );
    });

    test(
      'other exceptions become unknown and drop the "Exception:" prefix',
      () {
        final e = ApiException.from(Exception('boom'));
        expect(e.type, ApiErrorType.unknown);
        expect(e.message, 'boom');
      },
    );
  });

  group('retry policy', () {
    test('only network and timeout errors are retryable', () {
      expect(const ApiException(ApiErrorType.network, '').isRetryable, isTrue);
      expect(const ApiException(ApiErrorType.timeout, '').isRetryable, isTrue);
      expect(
        const ApiException(ApiErrorType.unauthorized, '').isRetryable,
        isFalse,
      );
      expect(
        const ApiException(ApiErrorType.validation, '').isRetryable,
        isFalse,
      );
      expect(const ApiException(ApiErrorType.server, '').isRetryable, isFalse);
    });
  });

  group('userMessageFor', () {
    test(
      'uses the app strings for network, timeout, auth and server errors',
      () {
        expect(
          userMessageFor(const SocketException('x')),
          AppStrings.networkError,
        );
        expect(userMessageFor(TimeoutException('x')), AppStrings.timeoutError);
        expect(
          userMessageFor(
            const ApiException(ApiErrorType.unauthorized, 'Unauthenticated.'),
          ),
          AppStrings.unauthorizedError,
        );
        expect(
          userMessageFor(const ApiException(ApiErrorType.server, 'x')),
          AppStrings.serverError,
        );
      },
    );

    test('shows the server message when it is Arabic', () {
      expect(
        userMessageFor(
          const ApiException(ApiErrorType.validation, 'رقم الهاتف مطلوب'),
        ),
        'رقم الهاتف مطلوب',
      );
    });

    test('hides English server messages behind a friendly default', () {
      final msg = userMessageFor(
        const ApiException(
          ApiErrorType.validation,
          'The given data was invalid.',
        ),
      );
      expect(msg.contains('The given'), isFalse);
    });

    test('unknown errors use the generic message', () {
      expect(userMessageFor(Exception('???')), AppStrings.unknownError);
    });
  });
}
