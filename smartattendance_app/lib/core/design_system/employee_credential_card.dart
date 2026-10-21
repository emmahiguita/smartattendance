import 'dart:io';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// ============================================================================
/// COMPONENTE: EmployeeCredentialCard
/// ============================================================================
/// Credencial corporativa del empleado con rotación 3D (PerspectiveFlipCard).
/// Cara Frontal: Identidad corporativa, foto autorizada, nombre, cargo, ID.
/// Cara Posterior: Empresa, área de trabajo, políticas laborales y validez.
class EmployeeCredentialCard extends StatefulWidget {
  final String employeeName;
  final String employeeId;
  final String role;
  final String department;
  final String companyName;
  final String? photoPath;
  final bool isActive;
  final String credentialStatus;
  final String heroTag;
  final VoidCallback? onHeroTap;

  const EmployeeCredentialCard({
    super.key,
    required this.employeeName,
    required this.employeeId,
    required this.role,
    this.department = 'Operaciones',
    this.companyName = 'SmartAttendance Enterprise',
    this.photoPath,
    this.isActive = true,
    this.credentialStatus = 'VIGENTE',
    this.heroTag = 'employee-credential-hero',
    this.onHeroTap,
  });

  @override
  State<EmployeeCredentialCard> createState() => _EmployeeCredentialCardState();
}

class _EmployeeCredentialCardState extends State<EmployeeCredentialCard> {
  final GlobalKey<PerspectiveFlipCardState> _flipKey = GlobalKey();

  Widget _buildAvatar(BuildContext context) {
    if (widget.photoPath != null && widget.photoPath!.isNotEmpty) {
      final file = File(widget.photoPath!);
      if (file.existsSync()) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(AppDesignTokens.radiusCard),
          child: Image.file(
            file,
            width: 78,
            height: 94,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _fallbackAvatar(context),
          ),
        );
      }
    }
    return _fallbackAvatar(context);
  }

  Widget _fallbackAvatar(BuildContext context) {
    final initials = widget.employeeName.isNotEmpty
        ? widget.employeeName.trim().split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join()
        : '?';

    return Container(
      width: 78,
      height: 94,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppDesignTokens.radiusCard),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.25),
          width: 1.0,
        ),
      ),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            color: AppColors.primary,
            fontSize: 26,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildFront(BuildContext context) {
    final isDark = context.isDark;
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 380),
      padding: const EdgeInsets.all(AppDesignTokens.space20),
      decoration: BoxDecoration(
        color: context.cSurface,
        borderRadius: BorderRadius.circular(AppDesignTokens.radiusPanel),
        border: Border.all(
          color: context.cBorder.withValues(alpha: isDark ? 0.6 : 0.8),
          width: AppDesignTokens.borderWidth,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.06),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabecera de la credencial con logo corporativo
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.badge_rounded, color: Colors.white, size: 17),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.companyName.toUpperCase(),
                      style: TextStyle(
                        color: context.cTextSecondary,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'CREDENCIAL DIGITAL DE ASISTENCIA',
                      style: TextStyle(
                        color: context.cTextPrimary,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: widget.isActive
                      ? AppColors.systemGreen.withValues(alpha: 0.12)
                      : AppColors.systemRed.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppDesignTokens.radiusPill),
                  border: Border.all(
                    color: widget.isActive
                        ? AppColors.systemGreen.withValues(alpha: 0.4)
                        : AppColors.systemRed.withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  widget.isActive ? 'ACTIVO' : 'INACTIVO',
                  style: TextStyle(
                    color: widget.isActive ? AppColors.systemGreen : AppColors.systemRed,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDesignTokens.space16),
          const Divider(height: 1),
          const SizedBox(height: AppDesignTokens.space16),

          // Foto y datos principales
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Hero(
                tag: '${widget.heroTag}-avatar',
                child: _buildAvatar(context),
              ),
              const SizedBox(width: AppDesignTokens.space16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.employeeName,
                      style: AppDesignTokens.title(color: context.cTextPrimary, fontSize: 17),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.role.isNotEmpty ? widget.role : 'Colaborador',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: context.cBackgroundSecondary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'ID: ${widget.employeeId}',
                        style: TextStyle(
                          color: context.cTextPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          fontFeatures: AppDesignTokens.tabularFigures,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDesignTokens.space16),

          // Pie de la credencial con indicación interactiva
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.touch_app_outlined, size: 14, color: context.cTextSecondary),
                  const SizedBox(width: 4),
                  Text(
                    'Toca para ver reverso',
                    style: TextStyle(color: context.cTextSecondary, fontSize: 11),
                  ),
                ],
              ),
              Text(
                'VÁLIDO 2026',
                style: TextStyle(
                  color: context.cTextSecondary,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBack(BuildContext context) {
    final isDark = context.isDark;
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 380),
      padding: const EdgeInsets.all(AppDesignTokens.space20),
      decoration: BoxDecoration(
        color: context.cSurface,
        borderRadius: BorderRadius.circular(AppDesignTokens.radiusPanel),
        border: Border.all(
          color: context.cBorder.withValues(alpha: isDark ? 0.6 : 0.8),
          width: AppDesignTokens.borderWidth,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.06),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'INFORMACIÓN LABORAL',
                style: TextStyle(
                  color: context.cTextSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.systemBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  widget.credentialStatus,
                  style: const TextStyle(
                    color: AppColors.systemBlue,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          _infoRow(context, 'Empresa', widget.companyName),
          const SizedBox(height: 8),
          _infoRow(context, 'Área / Dpto', widget.department),
          const SizedBox(height: 8),
          _infoRow(context, 'Identificación', widget.employeeId),
          const SizedBox(height: 8),
          _infoRow(context, 'Emisión', 'Enero 2026'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: context.cBackgroundSecondary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.shield_outlined, size: 16, color: context.cTextSecondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Esta credencial es de uso estrictamente laboral y no almacena datos biométricos privados.',
                    style: TextStyle(color: context.cTextSecondary, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Toca para volver al frente',
              style: TextStyle(color: AppColors.primary, fontSize: 11.5, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(BuildContext context, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: context.cTextSecondary, fontSize: 12.5)),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              color: context.cTextPrimary,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        PerspectiveFlipCard(
          key: _flipKey,
          front: _buildFront(context),
          back: _buildBack(context),
          duration: AppDesignTokens.durationFlip,
        ),
        const SizedBox(height: 8),
        // Botón alternativo accesible para lectores de pantalla o personas con dificultad motriz
        Semantics(
          label: 'Girar credencial corporativa',
          child: TextButton.icon(
            style: TextButton.styleFrom(
              minimumSize: const Size(48, AppDesignTokens.minTouchTargetSize),
            ),
            onPressed: () => _flipKey.currentState?.flip(),
            icon: const Icon(Icons.flip_camera_android_rounded, size: 18),
            label: const Text('Girar credencial (Frente / Reverso)'),
          ),
        ),
      ],
    );
  }
}
