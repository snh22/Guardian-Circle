import 'dart:convert';

import 'package:http/http.dart' as http;

class FallEventService {
  static const String backendUrl =
      'https://guardian-ka-circle-backend.onrender.com/latest';

  static const String acknowledgeUrl =
      'https://guardian-ka-circle-backend.onrender.com/acknowledge';

  static const String guardianCircleUrl =
      'https://guardian-ka-circle-backend.onrender.com/guardian-circle';

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

  // ============================================================
  // GUARDIAN CIRCLE
  // ============================================================

  Future<double> fetchGuardianCircleRange() async {
    final response = await http.get(
      Uri.parse(guardianCircleUrl),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Guardian Circle backend error: '
        '${response.statusCode}',
      );
    }

    final data = jsonDecode(response.body);

    return (data['radius'] as num).toDouble();
  }

  Future<double> updateGuardianCircleRange(
    double radius,
  ) async {
    final response = await http.post(
      Uri.parse(guardianCircleUrl),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'radius': radius,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Guardian Circle update failed: '
        '${response.statusCode}: '
        '${response.body}',
      );
    }

    final data = jsonDecode(response.body);

    return (data['radius'] as num).toDouble();
  }
}
