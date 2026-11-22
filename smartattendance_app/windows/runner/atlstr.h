// ============================================================================
// ARCHIVO: atlstr.h
// QUÉ HACE: Provee conversión ligera UTF-8 <-> UTF-16 (`CA2W` y `CW2A`) usando
//           la API estándar de Win32 (`MultiByteToWideChar` / `WideCharToMultiByte`).
// CÓMO FUNCIONA: Sustituye la dependencia opcional de Visual Studio ATL para
//                que `flutter_secure_storage_windows` compile sin requerir ATL.
// POR QUÉ: Garantiza compilación nativa en Windows 100% limpia (< 55 líneas).
// ============================================================================

#pragma once
#include <windows.h>
#include <string>

struct CA2W {
  std::wstring buf;
  LPWSTR m_psz;
  explicit CA2W(const char* src) : m_psz(nullptr) {
    if (src) {
      int n = MultiByteToWideChar(CP_UTF8, 0, src, -1, nullptr, 0);
      if (n > 0) {
        buf.resize(static_cast<size_t>(n));
        MultiByteToWideChar(CP_UTF8, 0, src, -1, &buf[0], n);
      }
    }
    if (buf.empty()) buf.push_back(L'\0');
    m_psz = &buf[0];
  }
  operator LPWSTR() const { return m_psz; }
};

struct CW2A {
  std::string buf;
  explicit CW2A(const wchar_t* src) {
    if (src) {
      int n = WideCharToMultiByte(CP_UTF8, 0, src, -1, nullptr, 0, nullptr, nullptr);
      if (n > 0) {
        buf.resize(static_cast<size_t>(n - 1));
        WideCharToMultiByte(CP_UTF8, 0, src, -1, &buf[0], n, nullptr, nullptr);
      }
    }
  }
  operator const char*() const { return buf.c_str(); }
  operator std::string() const { return buf; }
};
