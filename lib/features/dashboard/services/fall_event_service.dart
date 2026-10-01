import 'dart:convert';

import 'package:http/http.dart' as http;

class FallEventService {
  static const String backendUrl =
      'http://10.0.2.2:8000/api/v1/events';

  static const String acknowledgeUrl =
      'http://10.0.2.2:8000/api/v1/alerts';

  Future<Map<String, dynamic>?> fetchLatestEvent() async {
    return null;
  }

  Future<void> acknowledgeEvent(int alertId) async {
    final response = await http.put(
      Uri.parse(
        'http://10.0.2.2:8000/api/v1/alerts/$alertId/resolve',
      ),
      headers: {
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Acknowledge failed: ${response.statusCode}: '
        '${response.body}',
      );
    }
  }
}