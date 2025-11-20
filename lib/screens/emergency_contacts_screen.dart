import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../utils/app_localizations.dart';

/// ============================================
/// 🚨 صفحة معلومات الطوارئ - Emergency Contacts Screen
/// ============================================
class EmergencyContactsScreen extends StatelessWidget {
  const EmergencyContactsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations();
    
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [
                      Color(0xFFEF4444), // Red
                      Color(0xFFDC2626), // Darker Red
                    ],
                  ),
                ),
              ),
            ),
            title: Text(
              localizations.emergencyContacts,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: true,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // بطاقة معلومات
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                        colors: [
                          Color(0xFFEF4444),
                          Color(0xFFDC2626),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withValues(alpha: 0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.emergency_rounded,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          localizations.emergencyContactsTitle,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          localizations.emergencyContactsSubtitle,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // قائمة أرقام الطوارئ
                  _buildEmergencyContact(
                    context: context,
                    icon: Icons.security_rounded,
                    title: localizations.securityPatrolsOperations,
                    phoneNumber: '999',
                    color: const Color(0xFF8B5CF6),
                    gradient: const [
                      Color(0xFF8B5CF6),
                      Color(0xFF7C3AED),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildEmergencyContact(
                    context: context,
                    icon: Icons.fire_extinguisher_rounded,
                    title: localizations.civilDefenseOperations,
                    phoneNumber: '998',
                    color: const Color(0xFFF97316),
                    gradient: const [
                      Color(0xFFF97316),
                      Color(0xFFEA580C),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildEmergencyContact(
                    context: context,
                    icon: Icons.local_police_rounded,
                    title: localizations.roadSecurityOperations,
                    phoneNumber: '996',
                    color: const Color(0xFF1A237E),
                    gradient: const [
                      Color(0xFF1A237E),
                      Color(0xFF0D47A1),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildEmergencyContact(
                    context: context,
                    icon: Icons.traffic_rounded,
                    title: localizations.trafficOperations,
                    phoneNumber: '993',
                    color: const Color(0xFFF59E0B),
                    gradient: const [
                      Color(0xFFF59E0B),
                      Color(0xFFD97706),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildEmergencyContact(
                    context: context,
                    icon: Icons.badge_rounded,
                    title: localizations.policeOperations,
                    phoneNumber: '999',
                    color: const Color(0xFF1A237E),
                    gradient: const [
                      Color(0xFF1A237E),
                      Color(0xFF0D47A1),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildEmergencyContact(
                    context: context,
                    icon: Icons.medical_services_rounded,
                    title: localizations.redCrescentOperations,
                    phoneNumber: '997',
                    color: const Color(0xFFEF4444),
                    gradient: const [
                      Color(0xFFEF4444),
                      Color(0xFFDC2626),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildEmergencyContact(
                    context: context,
                    icon: Icons.star_rounded,
                    title: localizations.najm,
                    phoneNumber: '920000560',
                    color: const Color(0xFF10B981),
                    gradient: const [
                      Color(0xFF10B981),
                      Color(0xFF059669),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyContact({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String phoneNumber,
    required Color color,
    required List<Color> gradient,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _makePhoneCall(phoneNumber),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: gradient,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.3),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      phoneNumber,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.phone_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        debugPrint('❌ [Emergency] Cannot launch phone: $phoneNumber');
      }
    } catch (e) {
      debugPrint('❌ [Emergency] Error making phone call: $e');
    }
  }
}

