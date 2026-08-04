# SmartAttendance

Sistema Inteligente de Control de Asistencia Empresarial con escaneo QR, modo offline y panel administrativo.

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![FastAPI](https://img.shields.io/badge/FastAPI-0.115-009688?logo=fastapi)](https://fastapi.tiangolo.com)
[![Python](https://img.shields.io/badge/Python-3.12-3776AB?logo=python)](https://python.org)
[![Tests](https://img.shields.io/badge/tests-131%20passed-brightgreen)]()
[![License](https://img.shields.io/badge/license-proprietary-red)]()

---

## Estructura del repositorio

```
├── README.md                          ← Este archivo
├── run_tests.ps1                      ← Suite automatizada de pruebas
├── docs/                              ← Documentación del proyecto
│   ├── QUICK_START.md                 ← Guía rápida de instalación
│   ├── ENTREGABLES.md                 ← Entregables del proyecto
│   └── ...                            ← Historial de fases, auditorías, planes
├── smartattendance_app/               ← Flutter (Android + iOS + Web + Windows)
│   ├── lib/
│   │   ├── main.dart
│   │   ├── core/                      ← Auth, red, tema, router, validadores
│   │   ├── features/                  ← Clean Architecture por feature
│   │   │   ├── auth/                  ← Login, registro, splash
│   │   │   ├── attendance/            ← Dashboard admin, hoy empleado
│   │   │   ├── qr/                    ← Escáner + generación QR
│   │   │   ├── profile/               ← Perfil + edición
│   │   │   ├── history/               ← Historial de asistencias
│   │   │   ├── users/                 ← Gestión de empleados (admin)
│   │   │   ├── settings/              ← Configuración
│   │   │   └── messaging/             ← Mensajería interna
│   │   └── shared/                    ← Widgets reutilizables
│   ├── test/                          ← 107 tests (unit + widget + smoke)
│   ├── integration_test/              ← Tests end-to-end reales
│   └── packages/                      ← Stubs locales (geolocator_linux)
├── smartattendance_backend/           ← FastAPI REST API
│   ├── main.py                        ← Entry point + app factory
│   ├── app/
│   │   ├── api/v1/                    ← Endpoints + dependencias
│   │   ├── core/                      ← Config, seguridad, hashing
│   │   ├── database/                  ← SQLAlchemy engine + sesiones
│   │   ├── models/                    ← ORM (User, Attendance, QRCode)
│   │   ├── repositories/              ← Acceso a datos
│   │   ├── schemas/                   ← Pydantic request/response
│   │   └── services/                  ← Lógica de negocio
│   ├── tests/                         ← 24 tests pytest
│   └── seed.py                        ← Datos de prueba
```

---

## Stack técnico

| Capa | Tecnología |
|------|-----------|
| Mobile | Flutter 3.x, Dart 3.4+ |
| State | Riverpod 2.6 |
| Router | GoRouter 14 |
| HTTP | Dio 5 |
| DB local | SQLite (sqflite) |
| QR | mobile_scanner 5, qr_flutter 4 |
| Auth | JWT (access + refresh rotado), Google Sign-In |
| Backend | FastAPI 0.115, Python 3.12 |
| ORM | SQLAlchemy 2.x |
| Auth server | bcrypt, python-jose |
| Excel | openpyxl |
| Google Sheets | gspread (sincronización en background) |

---

## Requisitos

- Flutter SDK 3.x
- Python 3.12
- Android Studio / Xcode (para build mobile)
- Dispositivo Android 11+ o iOS 15+

---

## Instalación rápida

```powershell
# Backend
cd smartattendance_backend
python -m venv venv
.\venv\Scripts\python.exe -m pip install -r requirements.txt
copy .env.example .env    # Editar SECRET_KEY y DATABASE_URL
.\venv\Scripts\python.exe seed.py
.\venv\Scripts\python.exe -m uvicorn main:create_app --factory --reload --host 0.0.0.0 --port 8000

# Flutter
cd ..\smartattendance_app
flutter pub get
flutter run
```

Guía detallada en [`docs/QUICK_START.md`](docs/QUICK_START.md).

---

## Pruebas

```powershell
# Suite completa automatizada
.\run_tests.ps1

# Solo backend
.\run_tests.ps1 -BackendOnly

# Solo Flutter
.\run_tests.ps1 -FlutterOnly
```

| Suite | Tests | Estado |
|-------|-------|--------|
| Backend (pytest) | 24 | Pasando |
| Flutter unit | 61 | Pasando |
| Flutter widget | 7 | Pasando |
| Flutter smoke | 42 | Pasando |
| **Total** | **134** | |

---

## Funcionalidades principales

- **Autenticación**: Login por cédula + contraseña, Google Sign-In, recuperación de contraseña
- **QR Scanner**: Escaneo de QR con cámara para registrar entrada/salida
- **Jornada laboral 4 marcas**: entrada → salida almuerzo → regreso almuerzo → salida (server-side)
- **Modo offline**: Cola SQLite local con sincronización cuando hay conexión
- **Dashboard admin**: KPIs, estado hoy de todos los empleados, exportación Excel
- **Google Sheets**: Sincronización automática en background
- **Perfil**: Edición de datos personales + foto
- **Tema**: Claro / Oscuro / Sistema

---

## Documentación

- [`docs/QUICK_START.md`](docs/QUICK_START.md) — Guía de instalación y primer uso
- [`docs/ENTREGABLES.md`](docs/ENTREGABLES.md) — Entregables del proyecto
- [`docs/AUDITORIA_PROFESIONAL.md`](docs/AUDITORIA_PROFESIONAL.md) — Auditoría de código
- [`docs/PLAN_ACCION_PRODUCCION.md`](docs/PLAN_ACCION_PRODUCCION.md) — Plan de producción
- [`docs/INDICE_DOCUMENTACION.md`](docs/INDICE_DOCUMENTACION.md) — Índice completo
