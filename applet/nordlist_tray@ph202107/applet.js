const Applet = imports.ui.applet;
const GLib = imports.gi.GLib;
const Gio = imports.gi.Gio;
const Mainloop = imports.mainloop;
const Util = imports.misc.util;
const PopupMenu = imports.ui.popupMenu;
const Settings = imports.ui.settings;
const St = imports.gi.St;

class NordListApplet extends Applet.TextIconApplet {
    constructor(metadata, orientation, panelHeight, instanceId) {
        super(orientation, panelHeight, instanceId);

        this.metadata = metadata;
        this._timeout = null;

        this.actor.track_hover = true;
        this.actor.reactive = true;
        this.actor.connect('enter-event', () => this.on_hover_enter());
        this.actor.connect('leave-event', () => this.on_hover_leave());

        this.settings = new Settings.AppletSettings(this, this.metadata.uuid, instanceId);
        this.settings.bindProperty(Settings.BindingDirection.IN, "refresh-interval", "refreshInterval", this._onSettingsChanged.bind(this));
        this.settings.bindProperty(Settings.BindingDirection.IN, "full-status-hover", "fullStatusHover", this._onSettingsChanged.bind(this));
        this.settings.bindProperty(Settings.BindingDirection.IN, "script-path", "scriptPath", this._onSettingsChanged.bind(this));
        this.settings.bindProperty(Settings.BindingDirection.IN, "show-city-on-panel", "showCityOnPanel", this._onSettingsChanged.bind(this));

        this.menuManager = new PopupMenu.PopupMenuManager(this);
        this.hoverMenu = new Applet.AppletPopupMenu(this, orientation);
        this.menuManager.addMenu(this.hoverMenu);

        this.statusLabel = new PopupMenu.PopupMenuItem("", { reactive: false });
        this.statusLabel.label.set_style('text-align: left; font-family: monospace;');
        this.hoverMenu.addMenuItem(this.statusLabel);

        this.update_vpn_status();
        this._updateLoop();
    }

    on_hover_enter() {
        this.update_vpn_status();
        this.hoverMenu.open(true);
    }

    on_hover_leave() {
        this.hoverMenu.close();
    }

    on_applet_middle_clicked() {
        this.update_vpn_status();
    }

    _onSettingsChanged() {
        if (this._timeout) Mainloop.source_remove(this._timeout);
        this.update_vpn_status();
        this._updateLoop();
    }

    _updateLoop() {
        this._timeout = Mainloop.timeout_add_seconds(this.refreshInterval, () => {
            this.update_vpn_status();
            return true;
        });
    }

    get_icon_path(status) {
        const iconPath = `${this.metadata.path}/icons/${status}.png`;
        if (GLib.file_test(iconPath, GLib.FileTest.EXISTS)) return iconPath;
        return {
            connected: 'network-vpn-symbolic',
            disconnected: 'network-vpn-disconnected-symbolic',
            error: 'dialog-error-symbolic'
        }[status];
    }

    // Traditional Async Callback method (No await/async keywords)
    update_vpn_status() {
        try {
            let proc = new Gio.Subprocess({
                argv: ['nordvpn', 'status'],
                flags: Gio.SubprocessFlags.STDOUT_PIPE | Gio.SubprocessFlags.STDERR_PIPE
            });
            proc.init(null);

            proc.communicate_utf8_async(null, null, (obj, res) => {
                try {
                    let [success, stdout, stderr] = obj.communicate_utf8_finish(res);
                    if (success && stdout) {
                        this.process_nord_output(stdout.trim());
                    }
                } catch (e) {
                    this.handle_error(e);
                }
            });
        } catch (e) {
            this.handle_error(e);
        }
    }

    process_nord_output(output) {
        let displayString = "";
        let cityName = "";

        let cityMatch = output.match(/^City: (.*)$/m);
        if (cityMatch && cityMatch[1]) {
            cityName = cityMatch[1].trim();
        }

        if (this.fullStatusHover) {
            displayString = "NordVPN\n" + output;
        } else {
            let statusMatch = output.match(/^Status:.*$/m);
            displayString = "NordVPN";
            if (statusMatch) displayString += "\n" + statusMatch[0];
            if (cityMatch) displayString += "\n" + cityMatch[0];
            if (!statusMatch && !cityMatch) displayString += "\n" + output;
        }

        this.statusLabel.label.set_text(displayString);

        let isConnected = output.includes('Status: Connected');
        this.set_applet_icon_path(this.get_icon_path(isConnected ? 'connected' : 'disconnected'));

        if (this.showCityOnPanel && isConnected && cityName !== "") {
            this.set_applet_label(cityName);
        } else {
            this.set_applet_label("");
        }
    }

    handle_error(e) {
        if (this.statusLabel) this.statusLabel.label.set_text("Error fetching status");
        this.set_applet_label("");
        this.set_applet_icon_path(this.get_icon_path('error'));
    }

    on_applet_clicked() {
        let path = this.scriptPath ? this.scriptPath.replace('~', GLib.get_home_dir()) : null;
        if (path && GLib.file_test(path, GLib.FileTest.EXISTS)) {
            Util.spawnCommandLine(`gnome-terminal -- bash -c '${path}; exec bash'`);
        }
    }

    on_applet_removed_from_panel() {
        if (this._timeout) Mainloop.source_remove(this._timeout);
        this.settings.finalize();
    }
}

function main(metadata, orientation, panelHeight, instanceId) {
    return new NordListApplet(metadata, orientation, panelHeight, instanceId);
}
