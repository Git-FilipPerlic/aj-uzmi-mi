#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <flutter_windows.h>
#include <windows.h>

#include "flutter_window.h"
#include "utils.h"

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  // Uzak prozor preko cele visine ekrana, kao telefon (želja korisnika):
  // kartice razvučene preko celog monitora ne liče ni na jedan program.
  const int kSirinaProzora = 480;

  FlutterWindow window(project);
  Win32Window::Point origin(10, 10);
  Win32Window::Size size(kSirinaProzora, 720);
  if (!window.Create(L"Aj uzmi mi", origin, size)) {
    return EXIT_FAILURE;
  }

  // Cela visina radnog dela ekrana (bez trake sa zadacima), prozor na sredini.
  RECT radno;
  if (::SystemParametersInfo(SPI_GETWORKAREA, 0, &radno, 0)) {
    HMONITOR monitor =
        ::MonitorFromWindow(window.GetHandle(), MONITOR_DEFAULTTOPRIMARY);
    double razmera = FlutterDesktopGetDpiForMonitor(monitor) / 96.0;
    int sirina = static_cast<int>(kSirinaProzora * razmera);
    int x = radno.left + (radno.right - radno.left - sirina) / 2;
    ::SetWindowPos(window.GetHandle(), nullptr, x, radno.top, sirina,
                   radno.bottom - radno.top, SWP_NOZORDER | SWP_NOACTIVATE);
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
