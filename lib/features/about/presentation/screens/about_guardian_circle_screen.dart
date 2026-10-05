import 'package:flutter/material.dart';

class AboutGuardianCircleScreen extends StatelessWidget {
  const AboutGuardianCircleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FC),
      appBar: AppBar(
        title: const Text('About Guardian Circle'),
        backgroundColor: const Color(0xFF24598B),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE7F1FA),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(
                      Icons.shield_rounded,
                      size: 38,
                      color: Color(0xFF24598B),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Guardian Circle',
                    style: TextStyle(
                      color: Color(0xFF173B5F),
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Low-Cost Wearable and Mobile-Based '
                    'Safety Monitoring System for Elderly Users',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF687386),
                      fontSize: 13,
                      height: 1.45,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            const Text(
              'ABOUT THE PROJECT',
              style: TextStyle(
                color: Color(0xFF687386),
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 10),

            _InfoCard(
              icon: Icons.monitor_heart_outlined,
              title: 'Safety Monitoring',
              description:
                  'Guardian Circle is designed to support elderly safety '
                  'monitoring through a wearable device and mobile application.',
            ),

            const SizedBox(height: 11),

            _InfoCard(
              icon: Icons.watch_outlined,
              title: 'Wearable Device',
              description:
                  'The wearable prototype uses an ESP32-C3, MPU6050 motion '
                  'sensor, SOS button, vibration motor and rechargeable battery.',
            ),

            const SizedBox(height: 11),

            _InfoCard(
              icon: Icons.phone_android_rounded,
              title: 'Mobile Application',
              description:
                  'The mobile application connects with the wearable and '
                  'supports location monitoring, Bluetooth communication, '
                  'geofencing and notifications.',
            ),

            const SizedBox(height: 11),

            _InfoCard(
              icon: Icons.storage_rounded,
              title: 'Backend System',
              description:
                  'Guardian Circle uses a FastAPI backend with PostgreSQL '
                  'for application data and safety-related information.',
            ),

            const SizedBox(height: 11),

            _InfoCard(
              icon: Icons.dashboard_rounded,
              title: 'Monitoring Dashboard',
              description:
                  'The monitoring interface provides caregivers with access '
                  'to relevant patient information, location and safety status.',
            ),

            const SizedBox(height: 22),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF3FB),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFD3E5F4),
                ),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: Color(0xFF24598B),
                    size: 21,
                  ),
                  SizedBox(width: 11),
                  Expanded(
                    child: Text(
                      'Guardian Circle is a safety-support project. '
                      'It is intended to assist caregivers and should not '
                      'replace professional medical or emergency services.',
                      style: TextStyle(
                        color: Color(0xFF31516F),
                        fontSize: 11.5,
                        height: 1.45,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF3FB),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF24598B),
              size: 22,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF173B5F),
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  description,
                  style: const TextStyle(
                    color: Color(0xFF687386),
                    fontSize: 12,
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
