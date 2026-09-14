import 'package:dio/dio.dart';

import 'token_holder.dart';

/// The single shared HTTP client for every backend call.
///
/// baseUrl gotcha (per the plan you already have):
/// - Android EMULATOR  → http://10.0.2.2:8000   (points back to your PC)
/// - Flutter on same PC as backend, desktop/web → http://127.0.0.1:8000
/// - Real phone on Wi-Fi                        → http://<your-PC-LAN-IP>:8000
///
/// Only ever change this one line when switching setups — nothing else in
/// the app should hardcode a host.
class ApiClient {
  static final Dio dio = Dio(
    BaseOptions(
      baseUrl: 'http://10.0.2.2:8000',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
      },
    ),
  )..interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = TokenHolder.instance.token;
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
    );
}