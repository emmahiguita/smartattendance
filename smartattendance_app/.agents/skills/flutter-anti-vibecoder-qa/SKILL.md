---
name: flutter-anti-vibecoder-qa
description: Auditoría anti-vibecoder, control de alcance y pruebas verificables Flutter.
license: MIT
metadata:
  version: "1.0.0"
---

# Objetivo
Rechazar cambios cosméticos inventados, duplicaciones y promesas de funcionamiento no verificadas.

## Ciclo de trabajo exigido
1. Crear un inventario inicial: archivos de pantallas, tema, widgets reutilizados, iconos, dependencias, referencias visuales y tests.
2. Ejecutar `design_policy`, `flutter_visual_audit`, `typography_audit` y `ui_change_gate` antes de modificar.
3. Declarar alcance: iconos solamente / texto / tema / layout / lógica. Si solo se piden iconos, lo demás queda bloqueado.
4. Preferir reemplazar un `IconData` existente a introducir wrappers, servicios, gestores globales o paquetes de efectos.
5. Cambiar una familia por pantalla; verificar código de símbolo en versión instalada. Ni un solo símbolo supuesto es aceptable.
6. Ejecutar `flutter pub get` únicamente si se aprueba dependencia; después `dart format --output=none --set-exit-if-changed`, `flutter analyze`, pruebas y goldens cuando existan.
7. Revisar diff, clasificar con `ui_change_gate`; si marca `blocked` o `unverified`, detener entrega y explicar.
8. Concluir con evidencia: qué se cambió, por qué, qué tests se ejecutaron, qué no se pudo probar y capturas comparables.

## Criterios de rechazo inmediato
Nuevas cards/fondos, sombras, glassmorphism, animaciones, rutas, funciones comerciales, datos simulados, colores inventados o más navegación no solicitados; modificaciones de lógica de asistencia; cambios masivos sin baseline.

## Calidad de mantenimiento
Respetar SOLID/Clean Architecture existente. Preferir componentes pequeños, nombres semánticos y comentarios breves que expliquen responsabilidades no evidentes; no comentar cada expresión trivial ni reformatar toda una pantalla por cambiar un icono.

## Limitación
El MCP es **heurístico** y de solo lectura: no certifica visualmente, no verifica ejecución en dispositivos y no impide a un agente ignorar las reglas sin control de CI/revisión humana.
