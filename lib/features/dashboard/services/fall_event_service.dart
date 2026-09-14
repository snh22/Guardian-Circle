import 'dart:convert';

import 'package:http/http.dart' as http;

class FallEventService {
  static const String backendUrl =
      'https://guardian-ka-circle-backend.onrender.com/latest';

  static const String acknowledgeUrl =
      'https://guardian-ka-circle-backend.onrender.com/acknowledge';

  Future<Map<String, dynamic>?> fetchLatestEvent() async {
    final response = await http.get(
      Uri.parse(backendUrl),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Backend error: ${response.statusCode}',
      );
    }

    final data = jsonDecode(response.body);

    if (data['status'] == 'none') {
      return null;
    }

    return Map<String, dynamic>.from(data);
  }

  Future<void> acknowledgeEvent() async {
    final response = await http.post(
      Uri.parse(acknowledgeUrl),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Acknowledge failed: ${response.statusCode}',
      );
    }
  }
}