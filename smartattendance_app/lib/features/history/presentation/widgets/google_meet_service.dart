// lib/features/history/presentation/widgets/google_meet_service.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

/// ============================================================================
/// SERVICIO: GoogleMeetService (Integración Gratuita de Meet y Calendar)
/// ============================================================================
/// QUÉ HACE:
/// Provee integración 100% gratuita y sin costo de licencias API con Google Meet
/// y Google Calendar mediante deep-links nativos y esquemas web URI estándar.
///
/// CÓMO FUNCIONA:
/// 1. `openGoogleMeet`: Abre sala instantánea vía `https://meet.google.com/new`
///    o se une a una sala existente con código (`https://meet.google.com/{code}`).
/// 2. `addToGoogleCalendar`: Crea plantillas de eventos en Google Calendar vía
///    `https://calendar.google.com/calendar/render?action=TEMPLATE&...`.
/// 3. Utiliza `url_launcher` con `LaunchMode.externalApplication` para invocar
///    la app nativa instalada en Android/iOS o el navegador en su defecto.
///
/// POR QUÉ:
/// No requiere claves API de Google Cloud Workspace pagas ni suscripciones,
/// permitiendo a cualquier empresa sincronizar reuniones de trabajo a costo cero.
///
/// PRINCIPIOS SOLID:
/// - S (Single Responsibility): Única clase encargada de la comunicación externa con Google.
/// ============================================================================
abstract final class GoogleMeetService {
  /// Abre Google Meet (nueva reunión o sala existente)
  static Future<void> openMeet(BuildContext context, [String? meetingCode]) async {
    final trimmed = meetingCode?.trim();
    final url = (trimmed != null && trimmed.isNotEmpty)
        ? (trimmed.startsWith('http') ? trimmed : 'https://meet.google.com/$trimmed')
        : 'https://meet.google.com/new';

    final uri = Uri.parse(url);
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && context.mounted) {
        _showErrorSnackbar(context, 'No se pudo abrir la sala de Google Meet.');
      }
    } catch (_) {
      if (context.mounted) {
        _showErrorSnackbar(context, 'Error al conectar con Google Meet.');
      }
    }
  }

  /// Añade recordatorio de turno o reunión a Google Calendar
  static Future<void> addToCalendar(BuildContext context, DateTime date) async {
    final startFormat = DateFormat("yyyyMMdd'T'080000").format(date);
    final endFormat = DateFormat("yyyyMMdd'T'170000").format(date);
    final dateHuman = DateFormat('dd/MM/yyyy').format(date);

    final uri = Uri.parse(
      'https://calendar.google.com/calendar/render?'
      'action=TEMPLATE&'
      'text=Jornada+Laboral+-+BuenTiempo&'
      'dates=$startFormat/$endFormat&'
      'details=Jornada+de+trabajo+y+reuni%C3%B3n+de+sincronizaci%C3%B3n+BuenTiempo+($dateHuman)&'
      'location=Sede+Principal',
    );

    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && context.mounted) {
        _showErrorSnackbar(context, 'No se pudo abrir Google Calendar.');
      }
    } catch (_) {
      if (context.mounted) {
        _showErrorSnackbar(context, 'Error al abrir Google Calendar.');
      }
    }
  }

  static void _showErrorSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
