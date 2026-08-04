// test/unit/exceptions/error_handler_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:smartattendance/core/exceptions/error_handler.dart';
import 'package:smartattendance/core/exceptions/app_exception.dart';

void main() {
  group('ErrorHandler', () {
    group('handle - AppException', () {
      test('debe retornar la misma AuthException', () {
        final exception = AuthException(message: 'Auth failed');
        final result = ErrorHandler.handle(exception);

        expect(result, exception);
        expect(result is AuthException, true);
      });
    });

    group('handle - DioException', () {
      test('debe retornar NetworkException para connectionTimeout', () {
        final dioError = DioException(
          requestOptions: RequestOptions(path: '/test'),
          type: DioExceptionType.connectionTimeout,
        );

        final result = ErrorHandler.handle(dioError);

        expect(result is NetworkException, true);
        expect(result.message, contains('conexión'));
      });

      test('debe retornar NetworkException para receiveTimeout', () {
        final dioError = DioException(
          requestOptions: RequestOptions(path: '/test'),
          type: DioExceptionType.receiveTimeout,
        );

        final result = ErrorHandler.handle(dioError);

        expect(result is NetworkException, true);
      });

      test('debe retornar NetworkException para connectionError', () {
        final dioError = DioException(
          requestOptions: RequestOptions(path: '/test'),
          type: DioExceptionType.connectionError,
        );

        final result = ErrorHandler.handle(dioError);

        expect(result is NetworkException, true);
      });

      test('debe retornar AuthException para status 401', () {
        final response = Response(
          requestOptions: RequestOptions(path: '/test'),
          statusCode: 401,
        );
        final dioError = DioException(
          requestOptions: RequestOptions(path: '/test'),
          response: response,
          type: DioExceptionType.badResponse,
        );

        final result = ErrorHandler.handle(dioError);

        expect(result is AuthException, true);
        expect(result.message, contains('Sesión'));
      });

      test('debe retornar ValidationException para status 400', () {
        final response = Response(
          requestOptions: RequestOptions(path: '/test'),
          statusCode: 400,
        );
        final dioError = DioException(
          requestOptions: RequestOptions(path: '/test'),
          response: response,
          type: DioExceptionType.badResponse,
        );

        final result = ErrorHandler.handle(dioError);

        expect(result is ValidationException, true);
      });

      test('debe retornar ServerException para status 500', () {
        final response = Response(
          requestOptions: RequestOptions(path: '/test'),
          statusCode: 500,
        );
        final dioError = DioException(
          requestOptions: RequestOptions(path: '/test'),
          response: response,
          type: DioExceptionType.badResponse,
        );

        final result = ErrorHandler.handle(dioError);

        expect(result is ServerException, true);
      });

      test('debe extraer mensaje detail del response', () {
        final response = Response(
          requestOptions: RequestOptions(path: '/test'),
          statusCode: 400,
          data: {'detail': 'Invalid input'},
        );
        final dioError = DioException(
          requestOptions: RequestOptions(path: '/test'),
          response: response,
          type: DioExceptionType.badResponse,
        );

        final result = ErrorHandler.handle(dioError);

        expect(result.message, 'Invalid input');
      });
    });

    group('handle - FormatException', () {
      test('debe retornar ValidationException', () {
        const exception = FormatException('Invalid format');
        final result = ErrorHandler.handle(exception);

        expect(result is ValidationException, true);
      });
    });

    group('handle - Other', () {
      test('debe retornar UnknownException para excepciones desconocidas', () {
        final exception = Exception('Unknown error');
        final result = ErrorHandler.handle(exception);

        expect(result is UnknownException, true);
      });
    });
  });
}
