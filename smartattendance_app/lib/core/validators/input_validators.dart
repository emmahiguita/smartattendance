// lib/core/validators/input_validators.dart

abstract final class InputValidators {
  // Cédula validation
  static String? validateCedula(String? input) {
    if (input == null || input.trim().isEmpty) {
      return 'La cédula no puede estar vacía';
    }

    final trimmed = input.trim();

    if (trimmed.length < 6) {
      return 'Mínimo 6 dígitos';
    }

    if (trimmed.length > 13) {
      return 'Máximo 13 dígitos';
    }

    if (!RegExp(r'^[0-9]+$').hasMatch(trimmed)) {
      return 'Solo se aceptan números';
    }

    return null;
  }

  // Email validation
  static String? validateEmail(String? input) {
    if (input == null || input.isEmpty) return null;

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(input)) {
      return 'Email inválido';
    }

    return null;
  }

  // Password validation
  static String? validatePassword(String? input) {
    if (input == null || input.isEmpty) {
      return 'La contraseña es requerida';
    }

    if (input.length < 8) {
      return 'Mínimo 8 caracteres';
    }

    if (!input.contains(RegExp(r'[A-Z]'))) {
      return 'Requiere al menos una mayúscula';
    }

    if (!input.contains(RegExp(r'[a-z]'))) {
      return 'Requiere al menos una minúscula';
    }

    if (!input.contains(RegExp(r'[0-9]'))) {
      return 'Requiere al menos un número';
    }

    return null;
  }

  // Generic text validation
  static String? validateRequired(String? input, String fieldName) {
    if (input == null || input.trim().isEmpty) {
      return '$fieldName no puede estar vacío';
    }
    return null;
  }

  // Length validation
  static String? validateLength(
    String? input,
    int minLength,
    int maxLength, {
    String? fieldName,
  }) {
    if (input == null || input.isEmpty) return null;
    final name = fieldName ?? 'El campo';

    if (input.length < minLength) {
      return '$name mínimo $minLength caracteres';
    }

    if (input.length > maxLength) {
      return '$name máximo $maxLength caracteres';
    }

    return null;
  }
}
