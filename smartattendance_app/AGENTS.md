# Reglas de Ingeniería, Auditoría de Código y Arquitectura Limpia

## 1. REGLA ESTRICTA DE MODULARIZACIÓN (< 200 LÍNEAS)
- Ningún archivo nuevo o modificado puede superar las **200 líneas de código** (o máximo 280 líneas únicamente si contiene comentarios pedagógicos extensos y justificados).
- Si un componente crece, debe descomponerse en submódulos, controladores o widgets delegados bajo Clean Architecture.

## 2. COMENTARIOS PEDAGÓGICOS OBLIGATORIOS (APRENDER LEYENDO EL CÓDIGO)
Todo archivo, componente y función debe llevar comentarios explicativos en su punto de inicio:
```dart
// ============================================================================
// ARCHIVO: [nombre_archivo.ext]
// QUÉ HACE: [Explicación clara del propósito y responsabilidad]
// CÓMO FUNCIONA: [Paso a paso del flujo de ejecución y lógica interna]
// POR QUÉ: [Justificación arquitectónica, SOLID o de rendimiento]
// ============================================================================
```
En cada función o bloque clave:
- `// QUÉ HACE:` Propósito exacto.
- `// CÓMO:` Mecánica de ejecución.
- `// POR QUÉ:` Razón del enfoque técnico.

## 3. CERO SIMULACIONES Y CERO ALUCINACIONES (100% REAL)
- Prohibidos mocks ficticios, datos hardcoded a medias o lógica simulada (`Future.delayed` sin conexión real).
- Toda persistencia (SQLite, SecureStorage), red (Dio/API), geolocalización (GPS/Traccar), biometría y roles debe ser completamente funcional, lógica y verificable.

## 4. AUDITORÍA LÓGICA, PERMISOS Y PROCESOS ZOMBI
- **Permisos:** Auditar estados reales de permisos del SO (otorgado, denegado, bloqueado permanentemente).
- **Procesos Zombi:** Cancelar siempre `Timer`, `StreamSubscription`, `AnimationController`, sockets y listeners en `dispose()`.
- **Rendimiento y Lags:** Evitar re-renders masivos, computaciones pesadas en el UI thread (usar `compute` / `Isolates`) y llamadas duplicadas a red.
- **C++ / llama.cpp / FFI:** En caso de módulos nativos, verificar liberación de memoria RAII, control de punteros nulos y no bloquear el runtime principal.
- **Sin tests masivos que consuman tokens:** Validar mediante análisis estático (`flutter analyze`), logs precisos e inspección visual manual sobre dispositivo.

## 5. UI/UX: MATERIAL EXPRESSIVE, LIQUID GLASS Y MODO OSCURO PROFESIONAL
- **Modo Oscuro:** Fondo azul noche profundo (`#060E1C` o `#07101E`, no negro plano lavado), tarjetas Liquid Glass con `BackdropFilter` de 16-24px, bordes ultra-finos de alta definición (`0.7px - 0.9px`) y luminancia ambiental sutil.
- **Modo Horizontal (Landscape):** Layouts fluidos adaptativos (`maxWidth: 500-520px` o grillas 2 columnas), alturas adaptativas y cero overflows.
- **Aprovechamiento de Cabecera:** Banners fotográficos superiores de borde a borde, sin espacios blancos residuales (`MediaQuery.removePadding(removeTop: true)`).
