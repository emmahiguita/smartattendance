---
name: flutter-color-system-guard
description: Contraste WCAG, modo claro/oscuro y color semántico conservador.
license: MIT
metadata:
  version: "1.0.0"
---

# Objetivo
Controlar el color como sistema semántico, nunca como una colección de hexadecimales inventados.

## Procedimiento
1. Leer `design_policy` y el tema real: `ThemeData`, `ColorScheme`, `ThemeExtension`, variantes claro/oscuro, colores por estado.
2. El color visible en una captura es orientación, NO valor contractual de la implementación. Extraer los tokens reales del código.
3. Para pares opacos, usar MCP `color_contrast`. Mínimo WCAG AA 4.5:1 texto habitual y 3:1 texto grande; contraste gráfico significativo 3:1, donde aplique.
4. Cuando hay vidrio/transparencia/fotos, no dar resultados falsos: componer el color FINAL por escenario y medir visualmente; el MCP solo admite colores opacos.
5. Asociar color al estado, no a la posición: éxito, error, advertencia, deshabilitado, activo y foco; no depender únicamente del color para comunicar cambios.
6. Si solo se pidió cambiar iconos, preservar **todos** los colores, incluso si se detectan deudas técnicas: registrarlas para una tarea distinta.
7. Probar modos oscuro y claro donde existen, contraste, visualización con fuente grande y alto contraste.

## Guardrails
Prohibidos gradientes decorativos, glows, colores brand nuevos, fondos translúcidos o paletas recreadas sin aprobación.

Referencias: https://www.w3.org/WAI/WCAG22/Understanding/contrast-minimum | https://docs.flutter.dev/cookbook/design/themes
