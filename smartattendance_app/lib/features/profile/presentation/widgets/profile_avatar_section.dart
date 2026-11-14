// ============================================================================
// ARCHIVO: profile_avatar_section.dart
// QUÉ HACE: Sección del avatar de perfil: círculo con foto/inicial de alto
//           contraste + badge de edición y chip corporativo sin overflow.
// CÓMO FUNCIONA: Muestra CircleAvatar con FileImage/NetworkImage o letra inicial
//                blanca sobre superficie oscura y usa Flexible con ellipsis.
// POR QUÉ: Elimina franjas amarillas de desbordamiento y texto oscuro ilegible
//          en modo oscuro (< 150 líneas).
// ============================================================================

import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class ProfileAvatarSection extends StatelessWidget {
  final String? resolvedPhotoUrl;
  final String initialChar;
  final String cargo;
  final String cedula;
  final bool uploadingPhoto;
  final VoidCallback onTap;

  const ProfileAvatarSection({
    super.key,
    required this.resolvedPhotoUrl,
    required this.initialChar,
    required this.cargo,
    required this.cedula,
    required this.uploadingPhoto,
    required this.onTap,
  });

  // QUÉ HACE: Construye el ImageProvider correcto según tipo de ruta.
  // CÓMO: Soporta rutas locales ('/' o 'file://') y remotas ('http').
  // POR QUÉ: Permite visualización offline y online sin errores.
  ImageProvider? _buildImageProvider() {
    if (resolvedPhotoUrl == null || resolvedPhotoUrl!.isEmpty) return null;
    if (resolvedPhotoUrl!.startsWith('/') ||
        resolvedPhotoUrl!.startsWith('file://')) {
      final path = resolvedPhotoUrl!.replaceFirst('file://', '');
      final file = File(path);
      if (file.existsSync()) return FileImage(file);
      return null;
    }
    if (resolvedPhotoUrl!.startsWith('http')) {
      return NetworkImage(resolvedPhotoUrl!);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final imageProvider = _buildImageProvider();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Stack(
            children: [
              Container(
                width: 82,
                height: 82,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark
                      ? const Color(0xFF18181B)
                      : const Color(0xFFF1F5F9),
                  border: Border.all(color: context.cBorder, width: 0.7),
                  image: imageProvider != null
                      ? DecorationImage(image: imageProvider, fit: BoxFit.cover)
                      : null,
                ),
                alignment: Alignment.center,
                child: imageProvider == null
                    ? Text(
                        initialChar,
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w700,
                          color: context.cTextPrimary,
                        ),
                      )
                    : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(5.5),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    shape: BoxShape.circle,
                    border: Border.all(color: context.cBackground, width: 1.5),
                  ),
                  child: uploadingPhoto
                      ? SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            color: isDark ? Colors.black : Colors.white,
                            strokeWidth: 1.8,
                          ),
                        )
                      : Icon(
                          CupertinoIcons.camera_fill,
                          size: 12,
                          color: isDark ? Colors.black : Colors.white,
                        ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.cBorder, width: 0.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                CupertinoIcons.building_2_fill,
                size: 13,
                color: context.cTextSecondary,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  'SERVICIUDAD E.S.P. · $cargo · C.C. $cedula',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: context.cTextPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
