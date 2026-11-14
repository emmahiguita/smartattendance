---
name: flutter-iconography-guard
description: Iconos profesionales y consistencia de familias en Flutter Android/iOS.
license: MIT
metadata:
  version: "1.0.0"
---

# Objetivo
Sustituir únicamente iconos solicitados con una biblioteca profesional REAL, sin rediseñar la pantalla.

## Procedimiento obligatorio
1. Identificar la pantalla y el icono exacto afectado; documentar archivo, estado, función, label semántico y captura inicial.
2. Consultar `design_policy`, `icon_catalogs`, `icon_roles` e `icon_recommend` por MCP; el nombre sugerido es un **candidato**, NO un identificador verificado.
3. Leer `pubspec.yaml` y `pubspec.lock`; **reutilizar la familia ya instalada** cuando sea coherente. No instalar nuevas bibliotecas sin autorización.
4. Verificar la existencia exacta de cada `IconData`/widget en el código fuente o documentación correspondiente a la versión del paquete instalada.
5. Conservar dimensiones y área táctil; sustituir los iconos sin añadir botones, badges, cajas, fondos, gradientes ni animaciones.
6. Usar la misma familia y grosor óptico POR PANTALLA. Los símbolos elegidos deben distinguir entrada, salida, almuerzo, bloqueo y estado marcado.
7. Mantener semántica accesible del botón e iconos decorativos fuera del árbol semántico duplicado.
8. Ejecutar `ui_change_gate`, `flutter analyze`, pruebas de widgets y golden tests existentes; revisar antes/después en Android e iOS.

## Parámetros de referencia, no órdenes de rediseño
Icono habitual 20–24 dp (política predeterminada 22); navegación 24 dp; objetivo interactivo aproximadamente 48 × 48 dp. Respetar el tamaño ya existente salvo problema demostrado. Seleccionado y deshabilitado deben distinguirse además del color si es necesario.

## Fuentes verificables
Lucide: https://lucide.dev/icons | Hugeicons: https://pub.dev/packages/hugeicons | Phosphor: https://phosphoricons.com | Cupertino: https://pub.dev/packages/cupertino_icons.

## Rechazos
No mezclar colecciones en la misma pantalla por moda; no generar iconos con caracteres Unicode/emojis; no confundir un SVG con un código Dart; no eliminar comentarios existentes sin justificación.
