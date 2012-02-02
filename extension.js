
const St = imports.gi.St;
const Main = imports.ui.main;
const Tweener = imports.ui.tweener;
const Cairo = imports.cairo;
const Gio = imports.gi.Gio;
const Gtk = imports.gi.Gtk;

const SETTINGS_SCHEMA = 'org.gnome.shell.extensions.lunar-clock';
const POSITION_IN_PANEL_KEY = 'position-in-panel';

let clock;

LunarClock.prototype = {
	__proto__: PanelMenu.Button.prototype,
	_init: function() {
        // Load settings
        this._settings = getSettings(SETTINGS_SCHEMA);
		this._position_in_panel = this._settings.get_enum(POSITION_IN_PANEL_KEY);

        // Panel icon
        this._icon = new St.Icon({
            icon_type: this._icon_type,
            icon_name: 'view-refresh-symbolic',
            style_class: 'system-status-icon lunar-icon' + (Main.panel.actor.get_direction() == St.TextDirection.RTL ? '-rtl' : '')
        });
	}
};

function init() {
    button = new St.Bin({ style_class: 'panel-button',
                          reactive: true,
                          can_focus: true,
                          x_fill: true,
                          y_fill: false,
                          track_hover: true });
    let icon = new St.Icon({ icon_name: 'system-run',
                             icon_type: St.IconType.SYMBOLIC,
                             style_class: 'system-status-icon' });

    button.set_child(icon);
    button.connect('button-press-event', _showHello);
}

function enable() {
    Main.panel._rightBox.insert_actor(button, 0);
}

function disable() {
    Main.panel._rightBox.remove_actor(button);
}
