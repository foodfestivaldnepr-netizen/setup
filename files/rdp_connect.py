import subprocess
import json
import os
import gi
gi.require_version("Gtk", "3.0")
gi.require_version("GtkLayerShell", "0.1")
from gi.repository import Gtk, Gdk, GtkLayerShell, GLib

SERVER = ""
DEFAULT_USERNAME = ""
DEFAULT_PASSWORD = ""
CONFIG_PATH = os.path.expanduser("~/.config/rdp_connect.json")


def load_credentials():
    if os.path.exists(CONFIG_PATH):
        try:
            with open(CONFIG_PATH) as f:
                data = json.load(f)
                return (
                    data.get("server", DEFAULT_USERNAME),
                    data.get("username", DEFAULT_USERNAME),
                    data.get("password", DEFAULT_PASSWORD),
                )
        except Exception:
            pass
    return SERVER, DEFAULT_USERNAME, DEFAULT_PASSWORD


def save_credentials(server, username, password):
    with open(CONFIG_PATH, "w") as f:
        json.dump({"server": server, "username": username, "password": password}, f)


SCALES = [100, 140, 180]
HIDE_DELAY_MS = 1200
STRIP_W = 14

CSS = b"""
* { transition: none; }

#rdp-panel { background-color: #0d0505; }
#strip { background-color: #8b0000; }

#login-dialog {
    background-color: #0d0505;
    border-radius: 0px;
}

#dialog-header {
    background-color: #100808;
    border-radius: 0px;
    padding: 20px 28px 16px 28px;
    border-bottom: 1px solid #5a0000;
}

#dialog-body {
    background-color: #0d0505;
    padding: 24px 28px 20px 28px;
}

#dialog-footer {
    background-color: #080303;
    border-radius: 0px;
    padding: 14px 28px;
    border-top: 1px solid #5a0000;
}

#title-label {
    font-size: 15px;
    font-weight: bold;
    color: #c9a84c;
}

#subtitle-label {
    font-size: 10px;
    color: #5a3a1a;
    letter-spacing: 1px;
}

#server-label {
    font-size: 10px;
    color: #5a0000;
}

#field-label {
    font-size: 10px;
    color: #8b7355;
    margin-bottom: 4px;
    letter-spacing: 1px;
}

entry {
    background-color: #1a0808;
    color: #d4c9b0;
    border: 1px solid #5a0000;
    border-radius: 0px;
    padding: 8px 12px;
    font-size: 13px;
    caret-color: #8b0000;
    min-height: 0;
}
entry:focus {
    border-color: #8b0000;
    background-color: #200808;
}

#eye-btn {
    background: transparent;
    border: none;
    padding: 4px 6px;
    color: #5a0000;
    border-radius: 0px;
    min-height: 0;
    min-width: 0;
    font-size: 13px;
}
#eye-btn:hover {
    background: #1a0808;
    color: #c9a84c;
}

#cancel-btn {
    background: transparent;
    color: #5a3a2a;
    border: 1px solid #3d1a1a;
    border-radius: 0px;
    padding: 7px 16px;
    font-size: 11px;
    min-height: 0;
    letter-spacing: 1px;
}
#cancel-btn:hover {
    background: #1a0808;
    color: #d4c9b0;
    border-color: #5a0000;
}

#save-btn {
    background: #1a0808;
    color: #c9a84c;
    border: 1px solid #c9a84c;
    border-radius: 0px;
    padding: 7px 16px;
    font-size: 11px;
    font-weight: bold;
    min-height: 0;
    letter-spacing: 1px;
}
#save-btn:hover {
    background: #c9a84c;
    color: #0d0505;
}

#connect-btn {
    background: #3d0000;
    color: #d4c9b0;
    border: 1px solid #8b0000;
    border-radius: 0px;
    padding: 7px 20px;
    font-size: 11px;
    font-weight: bold;
    min-height: 0;
    letter-spacing: 1px;
}
#connect-btn:hover {
    background: #8b0000;
    color: #c9a84c;
}

#saved-label {
    font-size: 11px;
    color: #c9a84c;
}

button {
    background: #1a0808;
    color: #8b7355;
    border: 1px solid #3d1a1a;
    border-radius: 0px;
    padding: 6px 8px;
    font-size: 11px;
    min-height: 0;
}
button:hover { background: #2d0a0a; color: #d4c9b0; }
label { color: #d4c9b0; }
"""


class LoginDialog(Gtk.Window):
    def __init__(self):
        super().__init__(title="ADEPTUS MECHANICUS")
        self.set_name("login-dialog")
        self.set_position(Gtk.WindowPosition.CENTER)
        self.set_resizable(False)
        self.set_decorated(False)
        self.credentials = None

        saved_server, saved_user, saved_pass = load_credentials()

        provider = Gtk.CssProvider()
        provider.load_from_data(CSS)
        Gtk.StyleContext.add_provider_for_screen(
            Gdk.Screen.get_default(), provider,
            Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION,
        )

        root = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        self.add(root)

        # ── Header ────────────────────────────────────────────
        header = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=2)
        header.set_name("dialog-header")

        title_row = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
        icon = Gtk.Label()
        icon.set_markup('<span size="18000">⚙</span>')
        title_row.pack_start(icon, False, False, 0)
        title = Gtk.Label()
        title.set_name("title-label")
        title.set_markup('<span>RITE OF REMOTE COGNITION</span>')
        title_row.pack_start(title, False, False, 0)
        header.pack_start(title_row, False, False, 0)

        subtitle = Gtk.Label()
        subtitle.set_name("subtitle-label")
        subtitle.set_markup('<span>IN NOMINE OMNISSIAH</span>')
        subtitle.set_halign(Gtk.Align.START)
        header.pack_start(subtitle, False, False, 0)

        root.pack_start(header, False, False, 0)

        # ── Body ──────────────────────────────────────────────
        body = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=16)
        body.set_name("dialog-body")
        root.pack_start(body, False, False, 0)

        # Server field
        server_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=4)
        server_lbl = Gtk.Label(label="NODE ADDRESS")
        server_lbl.set_name("field-label")
        server_lbl.set_halign(Gtk.Align.START)
        server_box.pack_start(server_lbl, False, False, 0)
        self.server_entry = Gtk.Entry()
        self.server_entry.set_text(saved_server)
        self.server_entry.set_width_chars(26)
        self.server_entry.connect("activate", lambda _: self.user_entry.grab_focus())
        server_box.pack_start(self.server_entry, False, False, 0)
        body.pack_start(server_box, False, False, 0)

        # Login field
        user_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=4)
        user_lbl = Gtk.Label(label="OPERATOR IDENT")
        user_lbl.set_name("field-label")
        user_lbl.set_halign(Gtk.Align.START)
        user_box.pack_start(user_lbl, False, False, 0)
        self.user_entry = Gtk.Entry()
        self.user_entry.set_text(saved_user)
        self.user_entry.set_width_chars(26)
        self.user_entry.connect("activate", lambda _: self.pass_entry.grab_focus())
        user_box.pack_start(self.user_entry, False, False, 0)
        body.pack_start(user_box, False, False, 0)

        # Password field with eye toggle
        pass_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=4)
        pass_lbl = Gtk.Label(label="CIPHER KEY")
        pass_lbl.set_name("field-label")
        pass_lbl.set_halign(Gtk.Align.START)
        pass_box.pack_start(pass_lbl, False, False, 0)

        pass_row = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=6)
        self.pass_entry = Gtk.Entry()
        self.pass_entry.set_visibility(False)
        self.pass_entry.set_text(saved_pass)
        self.pass_entry.set_input_purpose(Gtk.InputPurpose.PASSWORD)
        self.pass_entry.connect("activate", self._on_connect)
        pass_row.pack_start(self.pass_entry, True, True, 0)

        self.eye_btn = Gtk.Button(label="👁")
        self.eye_btn.set_name("eye-btn")
        self.eye_btn.connect("clicked", self._toggle_password)
        pass_row.pack_start(self.eye_btn, False, False, 0)

        pass_box.pack_start(pass_row, False, False, 0)
        body.pack_start(pass_box, False, False, 0)

        # ── Footer ────────────────────────────────────────────
        footer = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=8)
        footer.set_name("dialog-footer")

        self.saved_lbl = Gtk.Label(label="")
        self.saved_lbl.set_name("saved-label")
        footer.pack_start(self.saved_lbl, True, True, 0)

        cancel_btn = Gtk.Button(label="ABORT")
        cancel_btn.set_name("cancel-btn")
        cancel_btn.connect("clicked", lambda _: Gtk.main_quit())
        footer.pack_start(cancel_btn, False, False, 0)

        save_btn = Gtk.Button(label="INSCRIBE")
        save_btn.set_name("save-btn")
        save_btn.connect("clicked", self._on_save)
        footer.pack_start(save_btn, False, False, 0)

        connect_btn = Gtk.Button(label="INITIATE LINK")
        connect_btn.set_name("connect-btn")
        connect_btn.connect("clicked", self._on_connect)
        footer.pack_start(connect_btn, False, False, 0)

        root.pack_start(footer, False, False, 0)

        self.connect("destroy", Gtk.main_quit)
        self.show_all()
        self.user_entry.grab_focus()

    def _toggle_password(self, *_):
        visible = self.pass_entry.get_visibility()
        self.pass_entry.set_visibility(not visible)
        self.eye_btn.set_label("🙈" if not visible else "👁")

    def _on_save(self, *_):
        save_credentials(self.server_entry.get_text(), self.user_entry.get_text(), self.pass_entry.get_text())
        self.saved_lbl.set_text("✓ INSCRIBED TO COGITATOR")
        GLib.timeout_add(2000, lambda: self.saved_lbl.set_text("") or False)

    def _on_connect(self, *_):
        server = self.server_entry.get_text()
        username = self.user_entry.get_text()
        password = self.pass_entry.get_text()
        save_credentials(server, username, password)
        self.credentials = (server, username, password)
        Gtk.main_quit()


class RDPController:
    def __init__(self, server, username, password):
        self.server = server
        self.username = username
        self.password = password
        self.scale = 140
        self.process = None
        self.hide_timer = None

        self.win = Gtk.Window()
        self.win.set_name("rdp-panel")
        self.win.connect("destroy", self.on_exit)
        self.win.connect("enter-notify-event", self.on_enter)
        self.win.connect("leave-notify-event", self.on_leave)

        GtkLayerShell.init_for_window(self.win)
        GtkLayerShell.set_layer(self.win, GtkLayerShell.Layer.OVERLAY)
        GtkLayerShell.set_keyboard_mode(self.win, GtkLayerShell.KeyboardMode.NONE)
        GtkLayerShell.set_exclusive_zone(self.win, 0)
        GtkLayerShell.set_anchor(self.win, GtkLayerShell.Edge.RIGHT, True)

        outer = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL)
        self.win.add(outer)

        self.panel = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=4)
        self.panel.set_margin_top(8)
        self.panel.set_margin_bottom(8)
        self.panel.set_margin_start(6)
        self.panel.set_margin_end(4)

        exit_btn = Gtk.Button(label="✕  SEVER LINK")
        exit_btn.connect("clicked", lambda _: self.on_exit())
        self.panel.pack_start(exit_btn, True, True, 0)

        hide_btn = Gtk.Button(label="—  CLOAK PANEL")
        hide_btn.connect("clicked", lambda _: self.collapse())
        self.panel.pack_start(hide_btn, True, True, 0)

        self.scale_btn = Gtk.Button(label=f"⚙ {self.scale}%")
        self.scale_btn.connect("clicked", self.show_scale_menu)
        self.panel.pack_start(self.scale_btn, True, True, 0)

        outer.pack_start(self.panel, True, True, 0)

        strip = Gtk.Box()
        strip.set_name("strip")
        strip.set_size_request(STRIP_W, -1)
        outer.pack_end(strip, False, False, 0)

        outer.set_size_request(STRIP_W, 160)

        self.win.show_all()
        GLib.timeout_add(3000, self.collapse)

    def launch_rdp(self):
        cmd = [
            "xfreerdp3",
            f"/v:{self.server}",
            f"/u:{self.username}",
            f"/p:{self.password}",
            "/dynamic-resolution",
            f"/scale:{self.scale}",
            "/cert:ignore",
            "/sec:rdp",
            "+printer",
            "-grab-keyboard",
            f"/drive:Linux,{os.path.expanduser('~')}",
        ]
        self.process = subprocess.Popen(cmd)

    def on_exit(self, *_):
        if self.process and self.process.poll() is None:
            self.process.terminate()
        Gtk.main_quit()

    def on_enter(self, widget, event):
        if event.detail == Gdk.NotifyType.INFERIOR:
            return False
        if self.hide_timer:
            GLib.source_remove(self.hide_timer)
            self.hide_timer = None
        self.panel.show()
        return False

    def on_leave(self, widget, event):
        if event.detail == Gdk.NotifyType.INFERIOR:
            return False
        if self.hide_timer:
            GLib.source_remove(self.hide_timer)
        self.hide_timer = GLib.timeout_add(HIDE_DELAY_MS, self.collapse)
        return False

    def collapse(self, *_):
        self.panel.hide()
        self.hide_timer = None
        return False

    def show_scale_menu(self, widget):
        menu = Gtk.Menu()
        for s in SCALES:
            label = f"• {s}%" if s == self.scale else f"  {s}%"
            item = Gtk.MenuItem(label=label)
            item.connect("activate", lambda _, sc=s: self.set_scale(sc))
            menu.append(item)
        menu.show_all()
        menu.popup_at_widget(widget, Gdk.Gravity.WEST, Gdk.Gravity.EAST, None)

    def set_scale(self, scale):
        self.scale = scale
        self.scale_btn.set_label(f"⚙ {scale}%")
        if self.process and self.process.poll() is None:
            self.process.terminate()
        self.launch_rdp()

    def run(self):
        self.launch_rdp()
        Gtk.main()


dialog = LoginDialog()
Gtk.main()

if dialog.credentials:
    server, username, password = dialog.credentials
    dialog.destroy()
    RDPController(server, username, password).run()
