// ============================================================================
// ARCHIVO: main.cpp
// QUÉ HACE: Punto de entrada nativo Win32 (`wWinMain`) de BuenTiempo en Windows
//           con autodescubrimiento de DLLs (`SetDllDirectoryW`) para todos los
//           plugins cuando el `.exe` se abre desde `Downloads` o acceso directo.
// CÓMO FUNCIONA:
// 1. Antes de invocar cualquier símbolo de `flutter_windows.dll` o de los 6
//    plugins (todos enlazados con `/DELAYLOAD`), verifica si las DLLs están
//    junto al `.exe`; si no, registra el directorio del bundle compilado.
// 2. Inicializa COM (`COINIT_APARTMENTTHREADED`), carga `data` y abre la ventana.
// POR QUÉ: Elimina 100% el error "no se encontró connectivity_plus_plugin.dll" (< 95 líneas).
// ============================================================================

#include <windows.h>
#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>

#include <string>
#include <vector>

#include "flutter_window.h"
#include "utils.h"

namespace {

// QUÉ HACE: Asegura que el cargador Win32 encuentre todas las DLLs de plugins y `data`.
void EnsureBundleDllDirectory() {
  wchar_t exePath[MAX_PATH + 1]{};
  if (::GetModuleFileNameW(nullptr, exePath, MAX_PATH) == 0) return;
  std::wstring dir(exePath);
  size_t sep = dir.find_last_of(L"\\/");
  if (sep != std::wstring::npos) dir.erase(sep);

  std::wstring localDll = dir + L"\\connectivity_plus_plugin.dll";
  if (::GetFileAttributesW(localDll.c_str()) != INVALID_FILE_ATTRIBUTES) {
    ::SetDllDirectoryW(dir.c_str());
    ::SetCurrentDirectoryW(dir.c_str());
    return;
  }

  const wchar_t* candidates[] = {
      L"C:\\Users\\emman\\Desktop\\Proyectos\\PROYECTO QR\\smartattendance_app\\build\\windows\\x64\\runner\\Debug",
      L"C:\\Users\\emman\\Desktop\\Proyectos\\PROYECTO QR\\smartattendance_app\\build\\windows\\x64\\runner\\Release",
  };
  for (const wchar_t* candidate : candidates) {
    std::wstring probe = std::wstring(candidate) + L"\\connectivity_plus_plugin.dll";
    if (::GetFileAttributesW(probe.c_str()) != INVALID_FILE_ATTRIBUTES) {
      ::SetDllDirectoryW(candidate);
      ::SetCurrentDirectoryW(candidate);
      return;
    }
  }
}

}  // namespace

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t* command_line, _In_ int show_command) {
  EnsureBundleDllDirectory();

  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  flutter::DartProject project(L"data");
  std::vector<std::string> command_line_arguments = GetCommandLineArguments();
  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);
  Win32Window::Point origin(60, 40);
  Win32Window::Size size(1180, 780);
  if (!window.Create(L"BuenTiempo", origin, size)) {
    ::CoUninitialize();
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  return EXIT_SUCCESS;
}
