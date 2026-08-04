// lib/features/qr/presentation/widgets/generate_qr_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/exceptions/error_handler.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/error_widget.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../users/presentation/viewmodels/users_viewmodel.dart';
import '../viewmodels/qr_viewmodel.dart';

/// Dialog reutilizable: lista de empleados → seleccionar → POST /qr/generate
/// → muestra el QR renderizado (single-use, listo para escanear).
/// Usado por el dashboard admin (desktop) y el home del admin (móvil).
Future<void> showGenerateQrDialog(BuildContext context, WidgetRef ref) async {
  final usersAsync = ref.read(usersViewModelProvider.future);

  if (!context.mounted) return;
  await showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: context.cSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        'Generar QR para empleado',
        style: TextStyle(
            color: context.cTextPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700),
      ),
      content: SizedBox(
        width: 420,
        height: 380,
        child: FutureBuilder<List<UserEntity>>(
          future: usersAsync,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  ErrorHandler.handle(snapshot.error).message,
                  style: const TextStyle(color: AppColors.systemRed),
                ),
              );
            }
            final users = snapshot.data ?? const <UserEntity>[];
            if (users.isEmpty) {
              return Center(
                child: Text(
                  'No hay empleados activos',
                  style: TextStyle(color: context.cGray),
                ),
              );
            }
            return ListView.separated(
              itemCount: users.length,
              separatorBuilder: (_, __) =>
                  Divider(height: 1, color: context.cBorder),
              itemBuilder: (_, i) {
                final u = users[i];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                    child: Text(
                      u.nombre.isNotEmpty ? u.nombre[0].toUpperCase() : '?',
                      style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                  title: Text(
                    u.fullName,
                    style: TextStyle(
                        color: context.cTextPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    'C.C. ${u.cedula} · ${u.cargo}',
                    style: TextStyle(color: context.cGray, fontSize: 12),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _generateQr(context, ref, u);
                  },
                );
              },
            );
          },
        ),
      ),
    ),
  );
}

Future<void> _generateQr(
    BuildContext context, WidgetRef ref, UserEntity user) async {
  try {
    final repository = ref.read(qrRepositoryProvider);
    final codigo = await repository.generateQR(user.id);

    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.cSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'QR de ${user.fullName}',
          style: TextStyle(
              color: context.cTextPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.cSurface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: QrImageView(
                data: codigo,
                version: QrVersions.auto,
                size: 220,
                backgroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Un solo uso. El empleado lo escanea con la app.',
              style: TextStyle(color: context.cGray, fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cerrar',
                style: TextStyle(
                    color: AppColors.primary, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  } catch (e) {
    if (!context.mounted) return;
    // Snackbar de error unificado (shared/widgets/error_widget.dart).
    ErrorSnackBar.show(
      context,
      'Error al generar QR: ${ErrorHandler.handle(e).message}',
    );
  }
}
