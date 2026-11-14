// lib/core/validators/input_validators.dart

abstract final class InputValidators {
  // Contrato de los campos CC existentes: entre 6 y 13 dígitos.
  // Los documentos genéricos se validan por separado, sin atribuir reglas legales.
  static String? validateCedula(String? input) {
    if (input == null || input.trim().isEmpty) return 'La cédula no puede estar vacía';
    if (!RegExp(r'^\d{6,13}$').hasMatch(input.trim())) return 'Ingresa una cédula de 6 a 13 dígitos';
    return null;
  }

  static String? validateDocument(String? input) {
    if (input == null || input.trim().isEmpty) {
      return 'El documento no puede estar vacío';
    }

    final trimmed = input.trim();

    if (trimmed.length < 4) {
      return 'Mínimo 4 caracteres';
    }

    if (trimmed.length > 16) {
      return 'Máximo 16 caracteres';
    }

    if (!RegExp(r'^[a-zA-Z0-9]+$').hasMatch(trimmed)) {
      return 'Solo números y letras sin signos';
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
