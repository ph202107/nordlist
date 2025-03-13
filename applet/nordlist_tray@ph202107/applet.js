const Applet = imports.ui.applet;
const GLib = imports.gi.GLib;
const Mainloop = imports.mainloop;
const Util = imports.misc.util;  // Import Util to run external commands

class NordListApplet extends Applet.IconApplet {
    constructor(metadata, orientation, panelHeight, instanceId) {
        super(orientation, panelHeight, instanceId);
        
        // Initial icon and tooltip
        this.update_vpn_status();
        
        // Schedule updates every 15 seconds
        this._updateLoop();
    }

    _updateLoop() {
        this.update_vpn_status();
        Mainloop.timeout_add(15000, () => this._updateLoop()); // 15 seconds
    }

    update_vpn_status() {
        let [res, out] = GLib.spawn_command_line_sync("nordvpn status");
        let output = out ? out.toString() : "";

        if (output.includes("Connected")) {
            this.set_applet_icon_path(this.get_icon_path("connected"));
            this.set_applet_tooltip("NordVPN: Connected");
        } else {
            this.set_applet_icon_path(this.get_icon_path("disconnected"));
            this.set_applet_tooltip("NordVPN: Disconnected");
        }
    }

    get_icon_path(status) {
        let userHome = GLib.get_home_dir();
        return `${userHome}/.local/share/cinnamon/applets/nordlist_tray@ph202107/icons/${status}.png`;
    }

    on_applet_clicked(event) {
        Util.spawnCommandLine("gnome-terminal -- bash -c '~/Scripts/nordlist.sh; exec bash'");
    }
}

function main(metadata, orientation, panelHeight, instanceId) {
    return new NordListApplet(metadata, orientation, panelHeight, instanceId);
}
