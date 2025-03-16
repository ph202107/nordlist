const Applet = imports.ui.applet;
const GLib = imports.gi.GLib;
const Mainloop = imports.mainloop;
const Util = imports.misc.util;
const PopupMenu = imports.ui.popupMenu;
const Settings = imports.ui.settings;
const Main = imports.ui.main;

class NordListApplet extends Applet.IconApplet {
    constructor(metadata, orientation, panelHeight, instanceId) {
        super(orientation, panelHeight, instanceId);
        
        this.metadata = metadata;
        this._timeout = null;
        
        // Initialize settings
        this.settings = new Settings.AppletSettings(
            this,
            this.metadata.uuid,
            instanceId
        );
        this.settings.bindProperty(
            Settings.BindingDirection.IN,
            "refresh-interval",
            "refreshInterval",
            this._onSettingsChanged.bind(this)
        );
        this.settings.bindProperty(
            Settings.BindingDirection.IN,
            "script-path",
            "scriptPath",
            this._onSettingsChanged.bind(this)
        );

        // Set up menu
        this.menuManager = new PopupMenu.PopupMenuManager(this);
        this.menu = new Applet.AppletPopupMenu(this, this.orientation);
        this.menuManager.addMenu(this.menu);
        
        // Add config menu item
        const configItem = new PopupMenu.PopupMenuItem("Config");
        configItem.connect('activate', () => {
            Util.spawnCommandLine("cinnamon-settings applets " + this.metadata.uuid);
        });
        this.menu.addMenuItem(configItem);
        
        // Initial setup
        this.set_applet_icon_path(this.get_icon_path('error'));
        this.set_applet_tooltip("Initializing...");
        this.update_vpn_status();
        this._updateLoop();
    }

    _onSettingsChanged() {
        if (this._timeout) {
            Mainloop.source_remove(this._timeout);
            this._timeout = null;
        }
        this._updateLoop();
    }

    _updateLoop() {
        this._timeout = Mainloop.timeout_add_seconds(
            this.refreshInterval,
            () => {
                this.update_vpn_status();
                return true;
            }
        );
    }

    get_icon_path(status) {
        const iconPath = `${this.metadata.path}/icons/${status}.png`;
        if (GLib.file_test(iconPath, GLib.FileTest.EXISTS)) {
            return iconPath;
        }
        // Fallback to system icons
        return {
            connected: 'network-vpn-symbolic',
            disconnected: 'network-vpn-disconnected-symbolic',
            error: 'dialog-error-symbolic'
        }[status];
    }

    update_vpn_status() {
        try {
            let [success, out, err, exitCode] = GLib.spawn_command_line_sync('nordvpn status');
            
            if (!success || exitCode !== 0) {
                throw new Error(`Command failed: ${err.toString()}`);
            }
            
            let output = out.toString().trim();
            
            if (output.includes('Status: Connected')) {
                this.set_applet_icon_path(this.get_icon_path('connected'));
                this.set_applet_tooltip("NordVPN Connected");
            } else {
                this.set_applet_icon_path(this.get_icon_path('disconnected'));
                this.set_applet_tooltip("NordVPN Disconnected");
            }
        } catch(e) {
            console.error(`Status check failed: ${e}`);
            this.set_applet_icon_path(this.get_icon_path('error'));
            this.set_applet_tooltip("Connection Status Unknown");
        }
    }

    on_applet_clicked() {
        if (this.scriptPath && GLib.file_test(this.scriptPath, GLib.FileTest.EXISTS)) {
            Util.spawnCommandLine(`gnome-terminal -- bash -c '${this.scriptPath}; exec bash'`);
        } else {
            Main.notifyError("Nordlist Error", "Script not found: " + this.scriptPath);
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
