// lib/features/history/presentation/widgets/google_meet_card.dart
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import 'google_meet_service.dart';

/// ============================================================================
/// COMPONENTE: GoogleMeetCard (Tarjeta de Sincronización Meet & Calendar)
/// ============================================================================
/// QUÉ HACE:
/// Muestra un bloque corporativo premium que permite:
/// 1. Iniciar una sala de Google Meet instantánea para el equipo.
/// 2. Unirse a una reunión existente introduciendo el código de sala.
/// 3. Sincronizar la jornada actual directamente con Google Calendar.
///
/// CÓMO FUNCIONA:
/// Invoca los métodos estáticos de [GoogleMeetService] que lanzan deep-links
/// nativos sin costo de licencias API ni demoras de red.
///
/// POR QUÉ:
/// Satisface el requerimiento de agendar reuniones e interactuar con Google Meet
/// de forma 100% gratuita dentro de la vista de agenda diaria del colaborador.
///
/// PRINCIPIOS SOLID:
/// - S (Single Responsibility): Presentación del centro de conferencias Google Meet.
/// ============================================================================
class GoogleMeetCard extends StatelessWidget {
  final DateTime selectedDate;

  const GoogleMeetCard({super.key, required this.selectedDate});

  void _showJoinMeetDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      useRootNavigator: true,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.video_call_rounded, color: Color(0xFF00897B)),
            SizedBox(width: 8),
            Text('Unirse a Google Meet', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          ],
        ),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'ej. abc-defg-hij o enlace',
            prefixIcon: const Icon(Icons.link_rounded),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00897B),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              final code = controller.text;
              Navigator.of(dialogCtx).pop();
              GoogleMeetService.openMeet(context, code);
            },
            child: const Text('Unirse'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF00897B).withValues(alpha: 0.28), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF00897B).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.video_camera_front_rounded, color: Color(0xFF00897B), size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Google Meet Corporativo',
                      style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, letterSpacing: -0.2),
                    ),
                    Text(
                      'Salas de sincronización 100% gratuitas',
                      style: TextStyle(fontSize: 11.5, color: context.cTextSecondary),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Añadir a Google Calendar',
                onPressed: () => GoogleMeetService.addToCalendar(context, selectedDate),
                icon: const Icon(Icons.event_available_rounded, color: AppColors.systemBlue, size: 22),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => GoogleMeetService.openMeet(context),
                  icon: const Icon(Icons.video_call_rounded, size: 18),
                  label: const Text('Iniciar Sala Meet', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00897B),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                onPressed: () => _showJoinMeetDialog(context),
                icon: const Icon(Icons.login_rounded, size: 16),
                label: const Text('Unirse', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF00897B),
                  side: const BorderSide(color: Color(0xFF00897B), width: 1.2),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
