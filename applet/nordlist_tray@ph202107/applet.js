const Applet = imports.ui.applet;
const GLib = imports.gi.GLib;
const Mainloop = imports.mainloop;
const Util = imports.misc.util;
const PopupMenu = imports.ui.popupMenu;
const Settings = imports.ui.settings;
const St = imports.gi.St;

// We change this from IconApplet to TextIconApplet to support the panel label
class NordListApplet extends Applet.TextIconApplet {
    constructor(metadata, orientation, panelHeight, instanceId) {
        super(orientation, panelHeight, instanceId);

        this.metadata = metadata;
        this._timeout = null;

        // Enable reactive hover
        this.actor.track_hover = true;
        this.actor.reactive = true;
        this.actor.connect('enter-event', () => this.on_hover_enter());
        this.actor.connect('leave-event', () => this.on_hover_leave());

        // Settings
        this.settings = new Settings.AppletSettings(this, this.metadata.uuid, instanceId);
        this.settings.bindProperty(Settings.BindingDirection.IN, "refresh-interval", "refreshInterval", this._onSettingsChanged.bind(this));
        this.settings.bindProperty(Settings.BindingDirection.IN, "full-status-hover", "fullStatusHover", this._onSettingsChanged.bind(this));
        this.settings.bindProperty(Settings.BindingDirection.IN, "script-path", "scriptPath", this._onSettingsChanged.bind(this));
        this.settings.bindProperty(Settings.BindingDirection.IN, "show-city-on-panel", "showCityOnPanel", this._onSettingsChanged.bind(this));

        // Popup Menu setup
        this.menuManager = new PopupMenu.PopupMenuManager(this);
        this.hoverMenu = new Applet.AppletPopupMenu(this, orientation);
        this.menuManager.addMenu(this.hoverMenu);

        this.statusLabel = new PopupMenu.PopupMenuItem("", { reactive: false });
        this.statusLabel.label.set_style('text-align: left; font-family: monospace;');
        this.hoverMenu.addMenuItem(this.statusLabel);

        // Initial setup
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

    update_vpn_status() {
        try {
            let [success, out, err, exitCode] = GLib.spawn_command_line_sync('nordvpn status');

            if (success && out) {
                let output = out.toString().trim();
                let displayString = "";
                let cityName = "";

                // Regex for City
                let cityMatch = output.match(/^City: (.*)$/m);
                if (cityMatch && cityMatch[1]) {
                    cityName = cityMatch[1].trim();
                }

                // Hover Menu Logic
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

                // Icon logic
                let isConnected = output.includes('Status: Connected');
                this.set_applet_icon_path(this.get_icon_path(isConnected ? 'connected' : 'disconnected'));

                // Panel Label logic
                if (this.showCityOnPanel && isConnected && cityName !== "") {
                    this.set_applet_label(cityName);
                } else {
                    this.set_applet_label("");
                }
            }
        } catch(e) {
            if (this.statusLabel) this.statusLabel.label.set_text("Error fetching status");
            this.set_applet_label("");
        }
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
