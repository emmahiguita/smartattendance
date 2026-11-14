// QUÉ HACE: Pide al servidor revocar la sesión cuando el usuario sale.
// CÓMO: Envía solo el refresco capturado antes de borrar la sesión local.
// POR QUÉ: No depende del interceptor que podría renovar o abrir otra sesión.
import 'package:dio/dio.dart';

Future<bool> revokeRemoteSession(String baseUrl, String refreshToken) async {
  final client = Dio(BaseOptions(
    baseUrl: baseUrl,
    followRedirects: false,
    connectTimeout: const Duration(seconds: 4),
    sendTimeout: const Duration(seconds: 4),
    receiveTimeout: const Duration(seconds: 4),
  ));
  try {
    final response = await client
        .post<void>('/auth/logout', data: {'refresh_token': refreshToken});
    return response.statusCode == 204;
  } on DioException {
    return false;
  } finally {
    client.close(force: true);
  }
}
