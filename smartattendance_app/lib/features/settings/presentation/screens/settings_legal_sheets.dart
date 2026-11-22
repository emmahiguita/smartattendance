// ============================================================================
// ARCHIVO: settings_legal_sheets.dart
// QUÉ HACE: Modales legales oficiales de BuenTiempo:
//           - Términos de Servicio y Licencia Propietaria.
//           - Política de Privacidad, Protección de Datos y Habeas Data (Ley 1581).
// CÓMO FUNCIONA: Despliega hojas flotantes Liquid Glass con tipografía editorial
//                organizada, cláusulas legales reales y navegación fluida.
// POR QUÉ: Reemplaza textos improvisados o simulados por marcos legales reales
//          y profesionales sin sobrecargar la pantalla principal (< 220 líneas).
// ============================================================================

import 'package:flutter/material.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/design_system/ios_floating_glass_sheet.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';

Widget _legalParagraph(BuildContext context, {required String number, required String title, required String body}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: (context.isDark ? AppColors.primaryDark : AppColors.primary).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              alignment: Alignment.center,
              child: Text(
                number,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: context.isDark ? AppColors.primaryDark : AppColors.primary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: context.cTextPrimary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(left: 28),
          child: Text(
            body,
            style: TextStyle(
              fontSize: 12,
              height: 1.45,
              color: context.cTextSecondary,
            ),
          ),
        ),
      ],
    ),
  );
}

// QUÉ HACE: Muestra los Términos de Servicio y Licencia Propietaria Comercial.
// CÓMO: Invoca `showIosFloatingGlassSheet` con cláusulas de uso institucional.
// POR QUÉ: Otorga respaldo legal real y formal a la organización y al creador.
void showLegalTermsModal(BuildContext context) {
  final isDark = context.isDark;
  final primary = isDark ? AppColors.primaryDark : AppColors.primary;

  showIosFloatingGlassSheet<void>(
    context: context,
    title: 'Términos de Servicio',
    subtitle: '${AppConfig.appName} v${AppConfig.appVersion} · Licencia Privada',
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _legalParagraph(
                    context,
                    number: '1',
                    title: 'Titularidad y Propiedad Intelectual',
                    body: '${AppConfig.appName} es un software de propiedad exclusiva de Emmanuel Higuita (dev emm ai), '
                        'protegido bajo leyes de derechos de autor y propiedad intelectual. '
                        'Queda prohibida su descompilación, ingeniería inversa, copia o distribución no autorizada.',
                  ),
                  _legalParagraph(
                    context,
                    number: '2',
                    title: 'Licencia de Uso Institucional',
                    body: 'Se concede a la organización licenciataria una licencia de uso corporativo en ${AppConfig.companyName} para el '
                        'control de jornada laboral, geocercas satelitales y gestión operativa de cuadrillas.',
                  ),
                  _legalParagraph(
                    context,
                    number: '3',
                    title: 'Uso Personal e Intransferible',
                    body: 'Cada colaborador es responsable de la veracidad y custodia de su credencial biométrica. '
                        'La marcación de asistencia debe ser realizada de forma presencial y personal en los puntos asignados.',
                  ),
                  _legalParagraph(
                    context,
                    number: '4',
                    title: 'Arquitectura Local-First y Disponibilidad',
                    body: 'El sistema almacena registros de manera inmutable en base de datos local cifrada (SQLite Seguro). '
                        'La operación continuará sin interrupciones aun ante desconexión de red.',
                  ),
                  _legalParagraph(
                    context,
                    number: '5',
                    title: 'Jurisdicción y Vigencia',
                    body: 'Los presentes términos se rigen bajo las leyes de la República de Colombia. Año 2026.',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            style: FilledButton.styleFrom(
              backgroundColor: primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: const Text('Entendido y Aceptar', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    ),
  );
}

// QUÉ HACE: Despliega la Política de Privacidad y Tratamiento de Datos (Ley 1581).
// CÓMO: Estructura la política de Habeas Data con enfoque estricto en biometría y GPS.
// POR QUÉ: Cumplimiento regulatorio estricto con garantías de privacidad del colaborador.
void showPrivacyPolicyModal(BuildContext context) {
  final isDark = context.isDark;
  final primary = isDark ? AppColors.primaryDark : AppColors.primary;

  showIosFloatingGlassSheet<void>(
    context: context,
    title: 'Política de Privacidad',
    subtitle: 'Protección de Datos Personales · Ley 1581 de 2012',
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _legalParagraph(
                    context,
                    number: '1',
                    title: 'Responsable del Tratamiento',
                    body: 'La plataforma ${AppConfig.appName} y la organización autorizada tratan los datos del personal en cumplimiento de la Ley 1581 de 2012 y normas de Habeas Data.',
                  ),
                  _legalParagraph(
                    context,
                    number: '2',
                    title: 'Finalidad Exclusiva Laboral',
                    body: 'La información de documento, nombre, foto biométrica y coordenadas se recopila estrictamente para el registro de asistencia, liquidación de jornada y horas extras.',
                  ),
                  _legalParagraph(
                    context,
                    number: '3',
                    title: 'Privacidad de Biometría Facial',
                    body: 'La fotografía de marcación se procesa localmente en el dispositivo para verificar liveness e identidad. No se comercializa, comparte ni transfiere a bases de datos comerciales de terceros.',
                  ),
                  _legalParagraph(
                    context,
                    number: '4',
                    title: 'Geolocalización Just-in-Time (Cero Rastreo Pasivo)',
                    body: 'El sensor GPS se consulta únicamente durante la fracción de segundo que toma validar la marcación en la geocerca. BuenTiempo no realiza rastreo en segundo plano ni invasión a la intimidad.',
                  ),
                  _legalParagraph(
                    context,
                    number: '5',
                    title: 'Canales de Atención y Derechos ARCO',
                    body: 'Para consultar, actualizar o solicitar rectificación de datos, el titular puede contactar a: eememeai@gmail.com o a través del canal oficial de WhatsApp +57 320 352 7283.',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            style: FilledButton.styleFrom(
              backgroundColor: primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: const Text('Cerrar Política', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    ),
  );
}
