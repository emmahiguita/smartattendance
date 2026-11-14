// ============================================================================
// ARCHIVO: login_form_card.dart
// QUÉ HACE: Tarjeta de formulario de acceso Liquid Glass de Serviciudad E.S.P.
//           Diseñada exclusivamente para autenticación de colaboradores y
//           administradores, sin opciones públicas de autoregistro ni olvido de clave.
// CÓMO FUNCIONA: Captura cédula (CC) y contraseña, conmuta rol RBAC, permite
//                recordar sesión y envía las credenciales validadas.
// POR QUÉ: La creación de cuentas y restablecimiento de claves es un proceso
//          estrictamente corporativo realizado desde adentro por el Super Administrador (< 150 líneas).
// ============================================================================

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/design_system/ios_glass_card.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/validators/input_validators.dart';
import '../../../../shared/widgets/primary_button.dart';
import 'remember_session_toggle.dart';
import 'login_role_toggle.dart';

class LoginFormCard extends StatelessWidget {
  const LoginFormCard({
    super.key,
    required this.formKey,
    required this.cedulaController,
    required this.passwordController,
    required this.selectedRole,
    required this.onRoleChanged,
    required this.obscurePassword,
    required this.onToggleObscure,
    required this.rememberSession,
    required this.onRememberChanged,
    required this.isLoading,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController cedulaController;
  final TextEditingController passwordController;
  final LoginRole selectedRole;
  final ValueChanged<LoginRole> onRoleChanged;
  final bool obscurePassword;
  final VoidCallback onToggleObscure;
  final bool rememberSession;
  final ValueChanged<bool?> onRememberChanged;
  final bool isLoading;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final primaryColor = context.cPrimary;
    final isAdminMode = selectedRole == LoginRole.admin;

    return IosGlassCard(
      padding: const EdgeInsets.all(22),
      borderRadius: 24,
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // QUÉ HACE: Conmutador de rol (Colaborador / Administrador).
            LoginRoleToggle(
                selectedRole: selectedRole, onRoleChanged: onRoleChanged),
            const SizedBox(height: 16),

            // Etiqueta del documento de identidad
            Row(
              children: [
                Expanded(
                  child: Text(
                    isAdminMode
                        ? 'Cédula de Administrador (CC)'
                        : 'Cédula de Identidad (CC)',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: context.cTextPrimary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // QUÉ HACE: Campo numérico de cédula de ciudadanía.
            TextFormField(
              controller: cedulaController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: InputValidators.validateCedula,
              decoration: InputDecoration(
                hintText: 'Número de cédula',
                prefixIcon: Icon(
                    isAdminMode ? CupertinoIcons.shield : CupertinoIcons.person,
                    size: 20,
                    color: context.cGray),
              ),
            ),
            const SizedBox(height: 14),

            // Etiqueta y campo de contraseña
            Text('Contraseña',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: context.cTextPrimary)),
            const SizedBox(height: 6),
            TextFormField(
              controller: passwordController,
              obscureText: obscurePassword,
              onFieldSubmitted: (_) => onSubmit(),
              decoration: InputDecoration(
                hintText: isAdminMode
                    ? 'Clave de Administrador'
                    : 'Tu contraseña',
                prefixIcon:
                    Icon(CupertinoIcons.lock, size: 20, color: context.cGray),
                suffixIcon: IconButton(
                  icon: Icon(
                      obscurePassword
                          ? CupertinoIcons.eye_slash
                          : CupertinoIcons.eye,
                      size: 19,
                      color: context.cGray),
                  onPressed: onToggleObscure,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // QUÉ HACE: Checkbox para recordar sesión localmente.
            // POR QUÉ: Sin enlaces externos de registro ni olvido (gestión interna del admin).
            RememberSessionToggle(
              value: rememberSession,
              activeColor: primaryColor,
              onChanged: onRememberChanged,
            ),
            const SizedBox(height: 18),

            // QUÉ HACE: Botón principal de acceso.
            PrimaryButton(
              label: isAdminMode
                  ? 'Ingresar como Administrador'
                  : 'Iniciar sesión',
              expanded: true,
              isLoading: isLoading,
              onPressed: onSubmit,
            ),
            const SizedBox(height: 14),

            // QUÉ HACE: Mensaje corporativo institucional que aclara la política de seguridad.
            Center(
              child: Text(
                'Afiliaciones y accesos gestionados por Administración RRHH',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: context.cTextSecondary.withValues(alpha: 0.75),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
