#!/usr/bin/env python3
# ============================================================================
# ARCHIVO: test_e2e_full_window_creation.py
# QUÉ HACE: Prueba automatizada E2E de la nueva ventana profesional completa sin cards:
#           1. Inicia sesión como Super Administrador (1007331963 / 123456).
#           2. Entra a Gestión RRHH -> Personal -> "+ Nuevo" (WorkerDialog fullscreen).
#           3. Registra a un nuevo Supervisor: "Hernando Giraldo" (2026009999).
#           4. Verifica persistencia en SQLite (workers y usuarios_locales).
#           5. Toma capturas de pantalla de evidencia completas.
# ============================================================================

import subprocess
import time
import os
import sqlite3
import base64
import re
import xml.etree.ElementTree as ET

SERIAL = "VGL7MVFMDYQG8T55"
PACKAGE = "io.smartattendance.attendance"
ARTIFACT_DIR = r"C:\Users\emman\.gemini\antigravity\brain\a45ec64e-10e5-4686-8711-6d6f1c99486e"

def run_adb(args):
    cmd = ["adb", "-s", SERIAL] + args
    res = subprocess.run(cmd, capture_output=True, text=True, encoding="utf-8", errors="ignore")
    return res.stdout.strip()

def tap(x, y):
    run_adb(["shell", "input", "tap", str(x), str(y)])
    time.sleep(1.0)

def type_text(text):
    run_adb(["shell", "input", "text", text.replace(" ", "%s")])
    time.sleep(0.6)

def keyevent(code):
    run_adb(["shell", "input", "keyevent", str(code)])
    time.sleep(0.5)

def capture_screen(name):
    path = os.path.join(ARTIFACT_DIR, f"{name}.png")
    raw = subprocess.check_output(["adb", "-s", SERIAL, "exec-out", "screencap", "-p"])
    with open(path, "wb") as f:
        f.write(raw)
    print(f"  [SCREENSHOT] {name}.png guardada.")
    return path

def dump_ui():
    run_adb(["shell", "uiautomator", "dump", "/sdcard/e2e_dump.xml"])
    xml_str = run_adb(["shell", "cat", "/sdcard/e2e_dump.xml"])
    try:
        return ET.fromstring(xml_str)
    except Exception as e:
        print(f"Error parseando XML: {e}")
        return None

def find_node(root, content_desc=None, text=None, class_name=None):
    if root is None:
        return None
    for elem in root.iter("node"):
        cd = elem.attrib.get("content-desc", "")
        t = elem.attrib.get("text", "")
        c = elem.attrib.get("class", "")
        if content_desc and content_desc in cd:
            return elem
        if text and text in t:
            return elem
        if class_name and class_name == c:
            return elem
    return None

def find_all_nodes(root, content_desc=None, class_name=None):
    if root is None:
        return []
    res = []
    for elem in root.iter("node"):
        cd = elem.attrib.get("content-desc", "")
        c = elem.attrib.get("class", "")
        match = True
        if content_desc and content_desc not in cd:
            match = False
        if class_name and class_name != c:
            match = False
        if match:
            res.append(elem)
    return res

def bounds_center(node):
    if node is None:
        return None, None
    b = node.attrib.get("bounds", "")
    m = re.match(r"\[(\d+),(\d+)\]\[(\d+),(\d+)\]", b)
    if m:
        x1, y1, x2, y2 = map(int, m.groups())
        return (x1 + x2) // 2, (y1 + y2) // 2
    return None, None

def main():
    print("=" * 60)
    print("INICIANDO PRUEBA AUTOMATIZADA E2E: VENTANA PROFESIONAL COMPLETA")
    print("=" * 60)

    # 1. Asegurar estado en Login
    print("\n1. Reiniciando app y asegurando LoginScreen...")
    run_adb(["shell", "pm", "clear", PACKAGE])
    time.sleep(1)
    run_adb(["shell", "monkey", "-p", PACKAGE, "-c", "android.intent.category.LAUNCHER", "1"])
    time.sleep(4)
    capture_screen("e2e_clean_login_screen")

    # 2. Seleccionar pestaña Administrador
    print("\n2. Seleccionando pestaña Administrador (Rango Superior)...")
    root = dump_ui()
    admin_tab = find_node(root, content_desc="Administrador")
    if admin_tab is not None:
        ax, ay = bounds_center(admin_tab)
        tap(ax, ay)
    else:
        tap(738, 891)
    time.sleep(1)

    print("  Ingresando credenciales del Super Administrador (1007331963)...")
    root = dump_ui()
    edit_texts = find_all_nodes(root, class_name="android.widget.EditText")
    if len(edit_texts) >= 2:
        cx, cy = bounds_center(edit_texts[0])
        tap(cx, cy)
        type_text("1007331963")

        px, py = bounds_center(edit_texts[1])
        tap(px, py)
        type_text("123456")

        keyevent(111) # Ocultar teclado
        time.sleep(1)

    # Scroll para asegurar visibilidad del botón de ingreso
    run_adb(["shell", "input", "swipe", "540", "1400", "540", "800"])
    time.sleep(1)

    root = dump_ui()
    login_btn = find_node(root, content_desc="Ingresar como Administrador")
    if login_btn is None:
        login_btn = find_node(root, content_desc="Iniciar sesión")
    if login_btn is not None:
        lx, ly = bounds_center(login_btn)
        tap(lx, ly)
    else:
        tap(540, 1764)
    time.sleep(4)

    capture_screen("e2e_superadmin_authenticated")
    print("  Super Administrador autenticado con éxito.")

    # 3. Navegar a Gestión RRHH -> Pestaña Personal
    print("\n3. Navegando a Gestión RRHH -> Personal...")
    root = dump_ui()
    equipos_nav = find_node(root, content_desc="Equipos")
    if equipos_nav is not None:
        ex, ey = bounds_center(equipos_nav)
        tap(ex, ey)
        time.sleep(1.5)

    root = dump_ui()
    personal_seg = find_node(root, content_desc="Personal")
    if personal_seg is not None:
        px, py = bounds_center(personal_seg)
        tap(px, py)
        time.sleep(1.5)

    capture_screen("e2e_hr_personal_tab")

    # 4. Abrir la nueva ventana profesional completa (+ Nuevo)
    print("\n4. Abriendo la Ventana Profesional Completa (+ Nuevo)...")
    root = dump_ui()
    nuevo_btn = find_node(root, content_desc="Nuevo")
    if nuevo_btn is not None:
        nx, ny = bounds_center(nuevo_btn)
        tap(nx, ny)
        time.sleep(2)

    capture_screen("e2e_fullscreen_window_view")
    print("  Ventana profesional completa desplegada.")

    # 5. Llenar los datos: Hernando Giraldo, 2026009999, Rol Supervisor
    print("\n5. Ingresando datos del nuevo Supervisor...")
    root = dump_ui()
    inputs = find_all_nodes(root, class_name="android.widget.EditText")
    if len(inputs) >= 2:
        # Nombre completo
        ix, iy = bounds_center(inputs[0])
        tap(ix, iy)
        type_text("Hernando Giraldo")

        # Cédula
        cx, cy = bounds_center(inputs[1])
        tap(cx, cy)
        type_text("2026009999")

        keyevent(111) # Ocultar teclado
        time.sleep(1)

    # 6. Seleccionar Rol -> Supervisor
    print("\n6. Abriendo selector de Rol y eligiendo 'Supervisor'...")
    root = dump_ui()
    rol_row = find_node(root, content_desc="Rol / Nivel de acceso")
    if rol_row is not None:
        rx, ry = bounds_center(rol_row)
        tap(rx, ry)
        time.sleep(1.5)

        menu_root = dump_ui()
        sup_opt = find_node(menu_root, content_desc="Supervisor")
        if sup_opt is not None:
            sx, sy = bounds_center(sup_opt)
            tap(sx, sy)
            time.sleep(1)

    capture_screen("e2e_fullscreen_supervisor_ready")

    # 7. Guardar en la Ventana Completa (Botón inferior o botón AppBar)
    print("\n7. Guardando en la Ventana Profesional Completa...")
    root = dump_ui()
    guardar_btn = find_node(root, content_desc="Guardar Colaborador / Mando")
    if guardar_btn is None:
        guardar_btn = find_node(root, content_desc="Guardar")
    if guardar_btn is not None:
        gx, gy = bounds_center(guardar_btn)
        tap(gx, gy)
    else:
        # Botón guardar en el AppBar superior derecho
        tap(1000, 160)
    time.sleep(3)

    capture_screen("e2e_after_save_directory")

    # 8. Verificación directa en bases de datos SQLite (workers y usuarios_locales)
    print("\n8. Auditando persistencia SQLite...")
    time.sleep(1)
    b64_db1 = run_adb(["shell", "run-as", PACKAGE, "base64", "databases/local_photo_attendance.db"])
    with open("local_photo_verified.db", "wb") as f:
        f.write(base64.b64decode(b64_db1.strip()))

    b64_db2 = run_adb(["shell", "run-as", PACKAGE, "base64", "databases/smartattendance_offline.db"])
    with open("smart_offline_verified.db", "wb") as f:
        f.write(base64.b64decode(b64_db2.strip()))

    c1 = sqlite3.connect("local_photo_verified.db").cursor()
    c1.execute("SELECT id, name, document, job FROM workers WHERE document = '2026009999'")
    w_rows = c1.fetchall()
    print(f"  [SQLITE workers]: {w_rows}")
    assert len(w_rows) > 0, "ERROR: No se encontró al Supervisor en workers"
    assert w_rows[0][3] == "Supervisor", f"ERROR: Cargo no coincide ({w_rows[0][3]})"

    c2 = sqlite3.connect("smart_offline_verified.db").cursor()
    c2.execute("SELECT id, cedula, nombre, cargo, password_hash, is_admin FROM usuarios_locales WHERE cedula = '2026009999'")
    u_rows = c2.fetchall()
    print(f"  [SQLITE usuarios_locales]: {u_rows}")
    assert len(u_rows) > 0, "ERROR: No se encontró al Supervisor en usuarios_locales"
    assert u_rows[0][4] == "123456", "ERROR: Clave por defecto debe ser 123456"
    assert u_rows[0][5] == 1, "ERROR: is_admin debe ser 1 para Supervisor"

    print("\n" + "=" * 60)
    print("PRUEBA AUTOMATIZADA E2E COMPLETADA CON ÉXITO: 100% OPERATIVA")
    print("=" * 60)

if __name__ == "__main__":
    main()
