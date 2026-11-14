---
name: flutter-platform-fidelity
description: Consistencia de iconos y aspecto Flutter entre Android e iOS sin rediseño.
license: MIT
metadata:
  version: "1.0.0"
---

# Objetivo
Preservar el mismo producto visual en Android e iOS, respetando componentes y semánticas nativas.

## Procedimiento
1. Localizar rutas `ThemeData`, `CupertinoThemeData`, `ThemeMode`, builders responsivos y `Platform.isIOS` utilizados realmente.
2. Identificar si existe diseño compartido o adaptativo y cuál es la fuente de verdad; no crear dos diseños por inferencia.
3. Los iconos pueden provenir de una misma familia cross-platform o adoptar variantes nativas **solo si ya existe esa decisión de diseño**.
4. Los cambios se limitan a recursos visuales solicitados; no modificar navegación, ciclo de vida, pantallas, SafeArea, gestos ni permisos.
5. Comprobar rótulos, hit areas, tamaños ópticos, accesibilidad con TalkBack y VoiceOver y comportamiento en densidades distintas.
6. Golden tests con fuentes cargadas y dispositivos definidos; si faltan golden tests, reportar pendiente en lugar de afirmar equivalencia.
7. Los iconos Cupertino no conceden funcionalidad nativa de iOS por sí mismos.

## Anti-vibe
No copiar efectos glass/líquidos por tendencia, no forzar estilo iPhone en Android si rompe convenciones o requisitos existentes.

Referencia: https://docs.flutter.dev/ui/adaptive-responsive | https://docs.flutter.dev/cookbook/design/themes
