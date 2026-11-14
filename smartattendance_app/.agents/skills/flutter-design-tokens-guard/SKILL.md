---
name: flutter-design-tokens-guard
description: Design tokens escalables y refactor seguro sin alterar pantallas.
license: MIT
metadata:
  version: "1.0.0"
---

# Objetivo
Evitar componentes de estilos duplicados y simplificar el mantenimiento, con equivalencia visual como condición.

## Procedimiento
1. Inspeccionar estilos existentes y recursos de tema: `ColorScheme`, `TextTheme`, `IconThemeData`, `ThemeExtension`, constantes y archivos de UI.
2. Distinguir propiedades intencionales de duplicación accidental. No convertir todo inline a token sin medir esfuerzo y riesgo.
3. Inventariar tokens: `color.brand`, `color.textPrimary`, `color.success`, `typography.body`, `icon.size`, `stroke`, `radii`, `spacing`; usar nombres semánticos, no numeraciones arbitrarias.
4. Separar tokens existentes de **propuestas**, y no introducir los últimos por defecto.
5. Cuando haya autorización para refactor, migrar SOLO un alcance pequeño, comparando capturas/golden antes y después para demostrar equivalencia.
6. Evitar dependencias de UI sobre capa de dominio; un cambio de color jamás altera casos de uso, persistencia ni estados de asistencia.
7. Consultar `flutter_visual_audit` y `ui_change_gate`; solicitar revisión explícita para cualquier línea fuera de alcance.

## Requisitos de entrega
Diff mínimo, lista de archivos, tokens reutilizados, capturas de equivalencia y deuda técnica no modificada.

Referencia: https://docs.flutter.dev/cookbook/design/themes
