// ============================================================================
// ARCHIVO: settings_widgets.dart
// QUÉ HACE: Componentes visuales reutilizables para la pantalla de Configuración
//           (títulos de sección, tarjetas contenedoras, filas e indicadores).
// CÓMO FUNCIONA: Aplica el sistema de diseño adaptable a modo claro/oscuro.
// POR QUÉ: Cumple SRP y mantiene todos los archivos bajo < 120 líneas.
// ============================================================================

import 'package:flutter/material.dart';
import '../../../../core/design_system/ios_floating_glass_sheet.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';

/// QUÉ HACE: Renderiza el encabezado de cada bloque en Configuración.
class SettingsSectionTitle extends StatelessWidget {
  const SettingsSectionTitle(this.title, {super.key});
  final String title;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8, left: 4),
        child: Text(
          title,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: context.cGray, letterSpacing: 0.5),
        ),
      );
}

/// QUÉ HACE: Tarjeta agrupada con bordes redondeados para filas de ajustes.
class SettingsGroupCard extends StatelessWidget {
  const SettingsGroupCard({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(children: children),
      );
}

/// QUÉ HACE: Fila individual de configuración con ícono, título, subtítulo y acción.
class SettingItemRow extends StatelessWidget {
  const SettingItemRow({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.accentColor = AppColors.primary,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final Color accentColor;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: accentColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: accentColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 15, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(subtitle, maxLines: 3, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 12.5)),
                  ],
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 8), trailing!],
            ],
          ),
        ),
      );
}

/// QUÉ HACE: Muestra el modal de Términos y Políticas de Privacidad.
void showSettingsTermsModal(BuildContext context) {
  showIosFloatingGlassSheet<void>(
    context: context,
    title: 'Términos y Privacidad',
    subtitle: 'Políticas y protección de datos institucionales',
    child: Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Flexible(
            child: SingleChildScrollView(
              child: Text(
                'SmartAttendance es la plataforma de registro de jornada laboral de tu organización.\n\n'
                '1. Tratamiento de Datos Personales: Los datos recopilados (cédula, nombre, cargo) se utilizan exclusivamente para la gestión interna de nómina y control de asistencia.\n\n'
                '2. Geolocalización: Los datos de ubicación se registran únicamente en el instante en que el usuario registra su marca biométrica, garantizando la privacidad fuera de la jornada.\n\n'
                '3. Seguridad de Acceso: El token de sesión y las credenciales permanecen encriptados localmente mediante enclaves seguros (Keystore / Keychain).',
                style: TextStyle(fontSize: 13.5, height: 1.5, color: context.cTextSecondary),
              ),
            ),
          ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), padding: const EdgeInsets.symmetric(vertical: 13)),
            child: const Text('Entendido', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    ),
  );
}
