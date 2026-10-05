import 'package:flutter/material.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  Widget _sectionCard({
    required IconData icon,
    required String title,
    required String description,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE6EBF2),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF183B60).withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF1F8),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFF24598B),
                  size: 23,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Color(0xFF183B60),
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      description,
                      style: const TextStyle(
                        color: Color(0xFF8994A3),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (children.isNotEmpty) ...[
            const SizedBox(height: 15),
            ...children,
          ],
        ],
      ),
    );
  }

  Widget _faqItem({
    required String question,
    required String answer,
  }) {
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(bottom: 10),
      iconColor: const Color(0xFF24598B),
      collapsedIconColor: const Color(0xFF7C8797),
      title: Text(
        question,
        style: const TextStyle(
          color: Color(0xFF354052),
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            answer,
            style: const TextStyle(
              color: Color(0xFF687386),
              fontSize: 12,
              height: 1.45,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF163B68),
        foregroundColor: Colors.white,
        title: const Text(
          'Help & Support',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionCard(
              icon: Icons.info_outline_rounded,
              title: 'How Guardian Circle Helps',
              description: 'A quick overview of the safety system',
              children: const [
                Text(
                  'Guardian Circle combines live location, planned trips, '
                  'safety monitoring, and emergency alerts to help a '
                  'caregiver stay informed about an elderly user.',
                  style: TextStyle(
                    color: Color(0xFF687386),
                    fontSize: 12.5,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            _sectionCard(
              icon: Icons.help_outline_rounded,
              title: 'Frequently Asked Questions',
              description: 'Common questions about the app',
              children: [
                _faqItem(
                  question: 'How do I check the patient location?',
                  answer:
                      'Open Live Location from the dashboard to view '
                      'the latest available patient location on the map.',
                ),
                _faqItem(
                  question: 'What is a planned trip?',
                  answer:
                      'A planned trip records where the patient is '
                      'expected to travel and when the journey is scheduled.',
                ),
                _faqItem(
                  question: 'What does Active Trip mean?',
                  answer:
                      'An active trip indicates that the planned journey '
                      'is currently being monitored by Guardian Circle.',
                ),
                _faqItem(
                  question: 'Where can I update patient information?',
                  answer:
                      'Open Patient Profile from the dashboard to view '
                      'and update the elderly user information.',
                ),
                _faqItem(
                  question: 'What should I do if information looks incorrect?',
                  answer:
                      'Check the patient profile, trip information, and '
                      'latest location data. Make sure the saved details '
                      'are up to date before relying on them.',
                ),
              ],
            ),
            _sectionCard(
              icon: Icons.support_agent_rounded,
              title: 'Need Assistance?',
              description: 'Basic guidance when something is not working',
              children: const [
                Text(
                  'For a project demonstration or testing issue, '
                  'first check the internet connection, location '
                  'permission, Bluetooth connection, and whether the '
                  'backend service is running.',
                  style: TextStyle(
                    color: Color(0xFF687386),
                    fontSize: 12.5,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF1F8),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: const Color(0xFFD5E2EE),
                ),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.shield_outlined,
                    color: Color(0xFF24598B),
                    size: 21,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Guardian Circle is a safety-support system. '
                      'Always verify critical information when responding '
                      'to an emergency.',
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
