---
name: flutter-accessibility-guard
description: Semántica Flutter, contraste y navegación accesible para interfaces móviles.
license: MIT
metadata:
  version: "1.0.0"
---

# Objetivo
Garantizar que un cambio de iconos no disminuya usabilidad visual ni accesibilidad.

## Protocolo
1. Inventariar iconos interactivos, etiquetas visibles, lectores de pantalla y estados seleccionados/deshabilitados.
2. Iconos puramente decorativos: evitar lectura duplicada; iconos interactivos: botón padre con nombre y estado accesible.
3. Mantener hit target suficiente, contraste, foco, orden semántico, dimensiones dinámicas y navegación por teclado si aplica.
4. Los colores por estado requieren una señal adicional cuando la distinción sea funcional (texto, forma o estado semántico).
5. Probar TalkBack y VoiceOver donde sea posible; el análisis estático no equivale a QA en dispositivo.
6. Para botones bloqueados, comunicar causa en texto existente; no habilitar/alterar flujos de asistencia sin autorización.
7. Calcular contraste de pares opacos con MCP `color_contrast`; registrar limitaciones en superficies transparentes.

## Evidencia de aceptación
Resultados de `flutter analyze`, pruebas de semántica, captura o grabación de lector de pantalla cuando sea posible y pendientes documentados.

Referencia: https://docs.flutter.dev/ui/accessibility-and-internationalization/accessibility | https://www.w3.org/TR/WCAG22/
