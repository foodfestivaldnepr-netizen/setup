#!/usr/bin/env python3
import gi
gi.require_version('Gtk', '4.0')
from gi.repository import Gtk, GLib, Gio
import subprocess
import os

PRINTER_MEDIA = {
    'printer1floor': ('A4', 'A4 (210×297 мм)'),
    'HP_LaserJet_400_M401dn_93020A': ('A4', 'A4 (210×297 мм)'),
    'XP-480B': ('w4h4', '4×4" (100×100 мм)'),
}

MONOCHROME_PRINTERS = {'printer1floor', 'HP_LaserJet_400_M401dn_93020A'}


def get_printers():
    try:
        out = subprocess.check_output(['lpstat', '-p'], text=True, stderr=subprocess.DEVNULL)
    except subprocess.CalledProcessError:
        return []
    printers = []
    for line in out.splitlines():
        parts = line.split()
        if len(parts) >= 2:
            printers.append(parts[1])
    return printers


def do_print(printer, filepath, media, copies, fit):
    if filepath.lower().endswith('.pdf'):
        ps_path = '/tmp/print_manager_out.ps'
        conv = subprocess.run(['pdf2ps', filepath, ps_path], capture_output=True, text=True)
        if conv.returncode != 0:
            return False, conv.stderr.strip()
        filepath = ps_path

    cmd = ['lp', '-d', printer, '-n', str(copies), '-o', f'media={media}']
    if fit:
        cmd += ['-o', 'fit-to-page']
    if printer in MONOCHROME_PRINTERS:
        cmd += ['-o', 'print-color-mode=monochrome']
    cmd.append(filepath)
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode == 0:
        return True, result.stdout.strip()
    return False, result.stderr.strip()


class PrintWindow(Gtk.ApplicationWindow):
    def __init__(self, app):
        super().__init__(application=app, title='Менеджер друку')
        self.set_default_size(480, 0)
        self.filepath = None

        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=16)
        box.set_margin_top(20)
        box.set_margin_bottom(20)
        box.set_margin_start(24)
        box.set_margin_end(24)
        self.set_child(box)

        # File picker
        file_row = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=8)
        self.file_label = Gtk.Label(label='Файл не обрано', xalign=0, hexpand=True)
        self.file_label.add_css_class('dim-label')
        file_btn = Gtk.Button(label='Обрати файл…')
        file_btn.connect('clicked', self.on_pick_file)
        file_row.append(self.file_label)
        file_row.append(file_btn)
        box.append(file_row)

        box.append(Gtk.Separator())

        # Printer selector
        printer_row = self._make_row('Принтер:')
        self.printer_combo = Gtk.DropDown()
        printers = get_printers()
        self.printer_list = Gtk.StringList.new(printers)
        self.printer_combo.set_model(self.printer_list)
        self.printer_combo.set_hexpand(True)
        self.printer_combo.connect('notify::selected', self.on_printer_changed)
        printer_row.append(self.printer_combo)
        box.append(printer_row)

        # Paper size (auto or override)
        media_row = self._make_row('Папір:')
        self.media_label = Gtk.Label(label='—', xalign=0, hexpand=True)
        media_row.append(self.media_label)
        box.append(media_row)

        # Copies
        copies_row = self._make_row('Копії:')
        self.copies_spin = Gtk.SpinButton.new_with_range(1, 99, 1)
        self.copies_spin.set_value(1)
        copies_row.append(self.copies_spin)
        box.append(copies_row)

        # Fit to page toggle
        self.fit_check = Gtk.CheckButton(label='Масштабувати до розміру сторінки')
        self.fit_check.set_active(True)
        box.append(self.fit_check)

        box.append(Gtk.Separator())

        # Status
        self.status = Gtk.Label(label='', xalign=0)
        self.status.set_wrap(True)
        box.append(self.status)

        # Print button
        self.print_btn = Gtk.Button(label='Друкувати')
        self.print_btn.add_css_class('suggested-action')
        self.print_btn.connect('clicked', self.on_print)
        box.append(self.print_btn)

        # Init media label from first printer
        if printers:
            self._update_media(printers[0])

    def _make_row(self, label_text):
        row = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=12)
        lbl = Gtk.Label(label=label_text, width_chars=10, xalign=0)
        row.append(lbl)
        return row

    def _update_media(self, printer):
        media, desc = PRINTER_MEDIA.get(printer, ('A4', 'A4'))
        self.media_label.set_text(desc)
        self._current_media = media

    def on_printer_changed(self, combo, _):
        idx = combo.get_selected()
        if idx < self.printer_list.get_n_items():
            self._update_media(self.printer_list.get_string(idx))

    def on_pick_file(self, _):
        dialog = Gtk.FileDialog()
        dialog.open(self, None, self._on_file_chosen)

    def _on_file_chosen(self, dialog, result):
        try:
            f = dialog.open_finish(result)
            self.filepath = f.get_path()
            name = os.path.basename(self.filepath)
            self.file_label.set_text(name)
            self.file_label.remove_css_class('dim-label')
        except GLib.Error:
            pass

    def on_print(self, _):
        if not self.filepath:
            self.status.set_text('⚠ Спочатку оберіть файл.')
            return

        idx = self.printer_combo.get_selected()
        printer = self.printer_list.get_string(idx)
        copies = int(self.copies_spin.get_value())
        fit = self.fit_check.get_active()

        self.print_btn.set_sensitive(False)
        self.status.set_text('Надсилаємо на друк…')

        ok, msg = do_print(printer, self.filepath, self._current_media, copies, fit)
        if ok:
            self.status.set_text(f'✓ {msg}')
        else:
            self.status.set_text(f'✗ Помилка: {msg}')
        self.print_btn.set_sensitive(True)


class PrintApp(Gtk.Application):
    def __init__(self):
        super().__init__(application_id='ua.local.printmanager')

    def do_activate(self):
        win = PrintWindow(self)
        win.present()


if __name__ == '__main__':
    app = PrintApp()
    app.run()
