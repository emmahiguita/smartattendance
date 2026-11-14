---
name: flutter-typography-guard
description: Auditoría tipográfica de Flutter sin reemplazo arbitrario de fuentes.
license: MIT
metadata:
  version: "1.0.0"
---

# Objetivo
Preservar la identidad y métricas tipográficas actuales, mejorar legibilidad solo cuando hay evidencia.

## Procedimiento
1. Ejecutar MCP `typography_audit` y `flutter_visual_audit`. Inspeccionar `ThemeData`, `TextTheme`, fuentes locales en `pubspec.yaml`, y `google_fonts` si existe.
2. Inventariar roles: title, headline, body, label, caption, y sus tamaños, pesos, alturas y espaciado. No suponer que un `fontSize` inline es un error: registrar y contrastar contexto.
3. No sustituir `fontFamily`, Material textTheme ni escala global si el pedido se limita a iconos.
4. Si el usuario autoriza una mejora, proponer una muestra comparada antes de cambiar. Fuentes de ejemplo: Inter, Plus Jakarta Sans, Manrope, Roboto; **no instalarlas automáticamente**.
5. Fuentes iOS (SF Pro y otros assets restringidos): no redistribuir ni incrustar archivos sin comprobar la licencia; preferir pila del sistema cuando proceda.
6. Considerar `MediaQuery.textScaler`, traducciones largas, accesibilidad y saltos de línea; evitar alturas fijas en textos que pueden expandirse.
7. Verificar licencia en documentación original y conservar avisos al distribuir fuentes de terceros.
8. Probar la pantalla con escalado de texto, tipografía local y plataformas; registrar diferencias en lugar de sustituir todo el sistema.

## Prohibiciones
No descargar TTF/OTF al azar, no usar varias familias por decoración, no reemplazar fuentes existentes por tendencias ni modificar altura de cards sin autorización.

Referencias: https://docs.flutter.dev/cookbook/design/themes | https://pub.dev/packages/google_fonts
