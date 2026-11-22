// ============================================================================
// ARCHIVO: win32_window.cpp
// QUÉ HACE: Gestiona la creación, ciclo de vida, escalado DPI y tema oscuro/claro
//           de la ventana nativa Win32 que aloja el motor Flutter en Windows.
// CÓMO FUNCIONA:
// 1. Registra la clase de ventana `FLUTTER_RUNNER_WIN32_WINDOW` con un
//    singleton estático sin fugas de memoria (`new` sin `delete` eliminado).
// 2. Sincroniza cambios de tamaño (`WM_SIZE`), DPI (`WM_DPICHANGED`) y cierre.
// POR QUÉ: Cumple RAII, cero memory leaks y límite `< 200` líneas (< 190 líneas).
// ============================================================================

#include "win32_window.h"

#include <dwmapi.h>
#include <flutter_windows.h>

#include "resource.h"

namespace {

#ifndef DWMWA_USE_IMMERSIVE_DARK_MODE
#define DWMWA_USE_IMMERSIVE_DARK_MODE 20
#endif

constexpr const wchar_t kWindowClassName[] = L"FLUTTER_RUNNER_WIN32_WINDOW";
constexpr const wchar_t kBrightnessRegKey[] =
    L"Software\\Microsoft\\Windows\\CurrentVersion\\Themes\\Personalize";
constexpr const wchar_t kBrightnessRegValue[] = L"AppsUseLightTheme";

static int g_active_window_count = 0;
using EnableNonClientDpiScaling = BOOL __stdcall(HWND hwnd);

int Scale(int source, double scale_factor) {
  return static_cast<int>(source * scale_factor);
}

void EnableFullDpiSupportIfAvailable(HWND hwnd) {
  HMODULE user32 = LoadLibraryA("User32.dll");
  if (!user32) return;
  auto fn = reinterpret_cast<EnableNonClientDpiScaling*>(
      GetProcAddress(user32, "EnableNonClientDpiScaling"));
  if (fn) fn(hwnd);
  FreeLibrary(user32);
}

}  // namespace

class WindowClassRegistrar {
 public:
  static WindowClassRegistrar* GetInstance() {
    static WindowClassRegistrar instance;
    return &instance;
  }

  const wchar_t* GetWindowClass() {
    if (!class_registered_) {
      WNDCLASS wc{};
      wc.hCursor = LoadCursor(nullptr, IDC_ARROW);
      wc.lpszClassName = kWindowClassName;
      wc.style = CS_HREDRAW | CS_VREDRAW;
      wc.hInstance = GetModuleHandle(nullptr);
      wc.hIcon = LoadIcon(wc.hInstance, MAKEINTRESOURCE(IDI_APP_ICON));
      wc.lpfnWndProc = Win32Window::WndProc;
      RegisterClass(&wc);
      class_registered_ = true;
    }
    return kWindowClassName;
  }

  void UnregisterWindowClass() {
    UnregisterClass(kWindowClassName, nullptr);
    class_registered_ = false;
  }

 private:
  WindowClassRegistrar() = default;
  bool class_registered_ = false;
};

Win32Window::Win32Window() { ++g_active_window_count; }
Win32Window::~Win32Window() {
  --g_active_window_count;
  Destroy();
}

bool Win32Window::Create(const std::wstring& title, const Point& origin, const Size& size) {
  Destroy();
  const wchar_t* window_class = WindowClassRegistrar::GetInstance()->GetWindowClass();
  const POINT pt = {static_cast<LONG>(origin.x), static_cast<LONG>(origin.y)};
  HMONITOR monitor = MonitorFromPoint(pt, MONITOR_DEFAULTTONEAREST);
  double scale = FlutterDesktopGetDpiForMonitor(monitor) / 96.0;
  HWND window = CreateWindow(
      window_class, title.c_str(), WS_OVERLAPPEDWINDOW,
      Scale(origin.x, scale), Scale(origin.y, scale),
      Scale(size.width, scale), Scale(size.height, scale),
      nullptr, nullptr, GetModuleHandle(nullptr), this);
  if (!window) return false;
  UpdateTheme(window);
  return OnCreate();
}

bool Win32Window::Show() { return ShowWindow(window_handle_, SW_SHOWNORMAL); }

LRESULT CALLBACK Win32Window::WndProc(HWND const window, UINT const message,
                                      WPARAM const wparam,
                                      LPARAM const lparam) noexcept {
  if (message == WM_NCCREATE) {
    auto cs = reinterpret_cast<CREATESTRUCT*>(lparam);
    SetWindowLongPtr(window, GWLP_USERDATA,
                     reinterpret_cast<LONG_PTR>(cs->lpCreateParams));
    auto that = static_cast<Win32Window*>(cs->lpCreateParams);
    EnableFullDpiSupportIfAvailable(window);
    that->window_handle_ = window;
  } else if (Win32Window* that = GetThisFromHandle(window)) {
    return that->MessageHandler(window, message, wparam, lparam);
  }
  return DefWindowProc(window, message, wparam, lparam);
}

LRESULT Win32Window::MessageHandler(HWND hwnd, UINT const message,
                                    WPARAM const wparam,
                                    LPARAM const lparam) noexcept {
  switch (message) {
    case WM_DESTROY:
      window_handle_ = nullptr;
      Destroy();
      if (quit_on_close_) PostQuitMessage(0);
      return 0;
    case WM_DPICHANGED: {
      auto r = reinterpret_cast<RECT*>(lparam);
      SetWindowPos(hwnd, nullptr, r->left, r->top, r->right - r->left,
                   r->bottom - r->top, SWP_NOZORDER | SWP_NOACTIVATE);
      return 0;
    }
    case WM_SIZE: {
      RECT r = GetClientArea();
      if (child_content_) {
        MoveWindow(child_content_, r.left, r.top, r.right - r.left,
                   r.bottom - r.top, TRUE);
      }
      return 0;
    }
    case WM_ACTIVATE:
      if (child_content_) SetFocus(child_content_);
      return 0;
    case WM_DWMCOLORIZATIONCOLORCHANGED:
      UpdateTheme(hwnd);
      return 0;
  }
  return DefWindowProc(window_handle_, message, wparam, lparam);
}

void Win32Window::Destroy() {
  OnDestroy();
  if (window_handle_) {
    DestroyWindow(window_handle_);
    window_handle_ = nullptr;
  }
  if (g_active_window_count == 0) {
    WindowClassRegistrar::GetInstance()->UnregisterWindowClass();
  }
}

Win32Window* Win32Window::GetThisFromHandle(HWND const window) noexcept {
  return reinterpret_cast<Win32Window*>(GetWindowLongPtr(window, GWLP_USERDATA));
}

void Win32Window::SetChildContent(HWND content) {
  child_content_ = content;
  SetParent(content, window_handle_);
  RECT r = GetClientArea();
  MoveWindow(content, r.left, r.top, r.right - r.left, r.bottom - r.top, true);
  SetFocus(child_content_);
}

RECT Win32Window::GetClientArea() {
  RECT frame{};
  GetClientRect(window_handle_, &frame);
  return frame;
}

HWND Win32Window::GetHandle() { return window_handle_; }
void Win32Window::SetQuitOnClose(bool quit) { quit_on_close_ = quit; }
bool Win32Window::OnCreate() { return true; }
void Win32Window::OnDestroy() {}

void Win32Window::UpdateTheme(HWND const window) {
  DWORD light_mode = 1;
  DWORD size = sizeof(light_mode);
  if (RegGetValue(HKEY_CURRENT_USER, kBrightnessRegKey, kBrightnessRegValue,
                  RRF_RT_REG_DWORD, nullptr, &light_mode, &size) == ERROR_SUCCESS) {
    BOOL dark = light_mode == 0;
    DwmSetWindowAttribute(window, DWMWA_USE_IMMERSIVE_DARK_MODE, &dark, sizeof(dark));
  }
}
