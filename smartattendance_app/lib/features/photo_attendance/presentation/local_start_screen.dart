import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/auth/session_controller.dart';
import '../../../../shared/widgets/control_ai_logo.dart';

/// Arranque sin temporizador artificial. El router escucha el resultado de
/// restaurar el perfil y navega al inicio o a configurar el encargado local.
class LocalStartScreen extends ConsumerStatefulWidget {
  const LocalStartScreen({super.key});
  @override
  ConsumerState<LocalStartScreen> createState() => _LocalStartScreenState();
}

class _LocalStartScreenState extends ConsumerState<LocalStartScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) ref.read(sessionControllerProvider.notifier).restore();
    });
  }

  @override
  Widget build(BuildContext context) => const Scaffold(
      body: Center(child: ControlAiLogo(size: 48, isHorizontal: false)));
}
