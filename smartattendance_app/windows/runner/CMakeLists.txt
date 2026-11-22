# ============================================================================
# ARCHIVO: windows/runner/CMakeLists.txt
# QUÉ HACE: Configura el ejecutable Win32 `smartattendance.exe` con carga
#           diferida (`/DELAYLOAD`) para `flutter_windows.dll` y TODOS los
#           plugins nativos de Windows.
# CÓMO FUNCIONA: Enlaza `delayimp.lib` y difiere la resolución de DLLs hasta
#                después de que `wWinMain` configure `SetDllDirectoryW`.
# POR QUÉ: Evita el error del sistema "no se encontró connectivity_plus_plugin.dll"
#          cuando el usuario ejecuta `smartattendance.exe` desde Descargas.
# ============================================================================

cmake_minimum_required(VERSION 3.14)
project(runner LANGUAGES CXX)

add_executable(${BINARY_NAME} WIN32
  "flutter_window.cpp"
  "main.cpp"
  "utils.cpp"
  "win32_window.cpp"
  "${FLUTTER_MANAGED_DIR}/generated_plugin_registrant.cc"
  "Runner.rc"
  "runner.exe.manifest"
)

apply_standard_settings(${BINARY_NAME})

target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION=\"${FLUTTER_VERSION}\"")
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION_MAJOR=${FLUTTER_VERSION_MAJOR}")
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION_MINOR=${FLUTTER_VERSION_MINOR}")
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION_PATCH=${FLUTTER_VERSION_PATCH}")
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION_BUILD=${FLUTTER_VERSION_BUILD}")
target_compile_definitions(${BINARY_NAME} PRIVATE "NOMINMAX")

target_link_libraries(${BINARY_NAME} PRIVATE flutter flutter_wrapper_app)
target_link_libraries(${BINARY_NAME} PRIVATE "dwmapi.lib" "delayimp.lib")
target_link_options(${BINARY_NAME} PRIVATE
  "/DELAYLOAD:flutter_windows.dll"
  "/DELAYLOAD:connectivity_plus_plugin.dll"
  "/DELAYLOAD:file_selector_windows_plugin.dll"
  "/DELAYLOAD:flutter_secure_storage_windows_plugin.dll"
  "/DELAYLOAD:geolocator_windows_plugin.dll"
  "/DELAYLOAD:share_plus_plugin.dll"
  "/DELAYLOAD:url_launcher_windows_plugin.dll"
)
target_include_directories(${BINARY_NAME} PRIVATE "${CMAKE_SOURCE_DIR}")

add_dependencies(${BINARY_NAME} flutter_assemble)
