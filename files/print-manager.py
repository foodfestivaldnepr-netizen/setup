#!/usr/bin/env python3
import gi
gi.require_version('Gtk', '4.0')
from gi.repository import Gtk, Gdk, GLib, Gio
import subprocess
import os

PRINTER_MEDIA = {
    'printer1floor': ('A4', 'A4 (210×297 мм)'),
    'HP_LaserJet_400_M401dn_93020A': ('A4', 'A4 (210×297 мм)'),
    'XP-480B': ('w4h4', '4×4" (100×100 мм)'),
}

MONOCHROME_PRINTERS = {'printer1floor', 'HP_LaserJet_400_M401dn_93020A'}

CSS = """
* { transition: none; }

window {
    background-color: #0d0505;
    color: #d4c9b0;
}

box {
    background-color: #0d0505;
}

label {
    color: #d4c9b0;
}

label.dim-label {
    color: #5a3a2a;
}

label.title-label {
    font-size: 14px;
    font-weight: bold;
    color: #c9a84c;
    letter-spacing: 1px;
}

label.subtitle-label {
    font-size: 10px;
    color: #5a3a1a;
    letter-spacing: 1px;
}

label.row-label {
    font-size: 10px;
    color: #8b7355;
    letter-spacing: 1px;
}

label.status-label {
    font-size: 12px;
    color: #8b7355;
}

entry {
    background-color: #1a0808;
    color: #d4c9b0;
    border: 1px solid #5a0000;
    border-radius: 0px;
    padding: 6px 10px;
    font-size: 13px;
    caret-color: #8b0000;
}
entry:focus {
    border-color: #8b0000;
    background-color: #200808;
}

button {
    background-color: #1a0808;
    color: #8b7355;
    border: 1px solid #3d1a1a;
    border-radius: 0px;
    padding: 6px 14px;
    font-size: 11px;
    letter-spacing: 1px;
}
button:hover {
    background-color: #2d0a0a;
    color: #d4c9b0;
    border-color: #5a0000;
}

button.suggested-action {
    background-color: #3d0000;
    color: #d4c9b0;
    border: 1px solid #8b0000;
    border-radius: 0px;
    padding: 8px 20px;
    font-size: 12px;
    font-weight: bold;
    letter-spacing: 1px;
}
button.suggested-action:hover {
    background-color: #8b0000;
    color: #c9a84c;
}
button.suggested-action:disabled {
    background-color: #1a0808;
    color: #3d1a1a;
    border-color: #3d1a1a;
}

separator {
    background-color: #5a0000;
    min-height: 1px;
}

spinbutton {
    background-color: #1a0808;
    color: #d4c9b0;
    border: 1px solid #5a0000;
    border-radius: 0px;
}
spinbutton button {
    background-color: #1a0808;
    border: none;
    color: #8b7355;
}
spinbutton button:hover {
    background-color: #2d0a0a;
    color: #c9a84c;
}

checkbutton {
    color: #8b7355;
    font-size: 11px;
    letter-spacing: 1px;
}
checkbutton check {
    background-color: #1a0808;
    border: 1px solid #5a0000;
    border-radius: 0px;
}
checkbutton check:checked {
    background-color: #8b0000;
    border-color: #8b0000;
}
checkbutton:hover {
    color: #d4c9b0;
}

dropdown {
    background-color: #1a0808;
    border: 1px solid #5a0000;
    border-radius: 0px;
    color: #d4c9b0;
}
dropdown button {
    background-color: #1a0808;
    border: none;
    color: #d4c9b0;
}
dropdown button:hover {
    background-color: #2d0a0a;
}

popover {
    background-color: #100808;
    border: 1px solid #5a0000;
    border-radius: 0px;
}
popover contents {
    background-color: #100808;
}
"""


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
        super().__init__(application=app, title='ADEPTUS MECHANICUS')
        self.set_default_size(480, 0)
        self.filepath = None

        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=16)
        box.set_margin_top(20)
        box.set_margin_bottom(20)
        box.set_margin_start(24)
        box.set_margin_end(24)
        self.set_child(box)

        # Header
        header_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=4)
        title_lbl = Gtk.Label(label='LITANY OF MANIFOLD INSCRIPTION')
        title_lbl.add_css_class('title-label')
        title_lbl.set_halign(Gtk.Align.CENTER)
        header_box.append(title_lbl)
        subtitle_lbl = Gtk.Label(label='ADEPTUS MECHANICUS — RITE OF THE PRINTED WORD')
        subtitle_lbl.add_css_class('subtitle-label')
        subtitle_lbl.set_halign(Gtk.Align.CENTER)
        header_box.append(subtitle_lbl)
        box.append(header_box)

        box.append(Gtk.Separator())

        # File picker
        file_row = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=8)
        self.file_label = Gtk.Label(label='NO MANUSCRIPT DESIGNATED', xalign=0, hexpand=True)
        self.file_label.add_css_class('dim-label')
        file_btn = Gtk.Button(label='DESIGNATE MANUSCRIPT')
        file_btn.connect('clicked', self.on_pick_file)
        file_row.append(self.file_label)
        file_row.append(file_btn)
        box.append(file_row)

        box.append(Gtk.Separator())

        # Printer selector
        printer_row = self._make_row('SACRED MANIFOLD:')
        self.printer_combo = Gtk.DropDown()
        printers = get_printers()
        self.printer_list = Gtk.StringList.new(printers)
        self.printer_combo.set_model(self.printer_list)
        self.printer_combo.set_hexpand(True)
        self.printer_combo.connect('notify::selected', self.on_printer_changed)
        printer_row.append(self.printer_combo)
        box.append(printer_row)

        # Paper size
        media_row = self._make_row('PARCHMENT GRADE:')
        self.media_label = Gtk.Label(label='—', xalign=0, hexpand=True)
        media_row.append(self.media_label)
        box.append(media_row)

        # Copies
        copies_row = self._make_row('ITERATIONS:')
        self.copies_spin = Gtk.SpinButton.new_with_range(1, 99, 1)
        self.copies_spin.set_value(1)
        copies_row.append(self.copies_spin)
        box.append(copies_row)

        # Fit to page toggle
        self.fit_check = Gtk.CheckButton(label='SCALE TO PARCHMENT DIMENSIONS')
        self.fit_check.set_active(True)
        box.append(self.fit_check)

        box.append(Gtk.Separator())

        # Status
        self.status = Gtk.Label(label='', xalign=0)
        self.status.add_css_class('status-label')
        self.status.set_wrap(True)
        box.append(self.status)

        # Print button
        self.print_btn = Gtk.Button(label='COMMENCE INSCRIPTION')
        self.print_btn.add_css_class('suggested-action')
        self.print_btn.connect('clicked', self.on_print)
        box.append(self.print_btn)

        # Init media label from first printer
        if printers:
            self._update_media(printers[0])

    def _make_row(self, label_text):
        row = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=12)
        lbl = Gtk.Label(label=label_text, width_chars=18, xalign=0)
        lbl.add_css_class('row-label')
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
            self.status.set_text('⚠ DESIGNATE A MANUSCRIPT FIRST, ADEPT.')
            return

        idx = self.printer_combo.get_selected()
        printer = self.printer_list.get_string(idx)
        copies = int(self.copies_spin.get_value())
        fit = self.fit_check.get_active()

        self.print_btn.set_sensitive(False)
        self.status.set_text('TRANSMITTING LITANY TO MANIFOLD…')

        ok, msg = do_print(printer, self.filepath, self._current_media, copies, fit)
        if ok:
            self.status.set_text(f'✓ LITANY ACCEPTED — {msg}')
        else:
            self.status.set_text(f'✗ RITE FAILED — MACHINE SPIRIT REFUSES: {msg}')
        self.print_btn.set_sensitive(True)


class PrintApp(Gtk.Application):
    def __init__(self):
        super().__init__(application_id='ua.local.printmanager')

    def do_activate(self):
        provider = Gtk.CssProvider()
        provider.load_from_string(CSS)
        Gtk.StyleContext.add_provider_for_display(
            Gdk.Display.get_default(), provider,
            Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION,
        )
        win = PrintWindow(self)
        win.present()


if __name__ == '__main__':
    app = PrintApp()
    app.run()
