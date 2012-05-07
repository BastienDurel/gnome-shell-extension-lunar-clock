
const St = imports.gi.St;
const GLib = imports.gi.GLib;
const Main = imports.ui.main;
const PanelMenu = imports.ui.panelMenu;
const PopupMenu = imports.ui.popupMenu;
const Mainloop = imports.mainloop;
const Tweener = imports.ui.tweener;
const Cairo = imports.cairo;
const Gio = imports.gi.Gio;
const Gtk = imports.gi.Gtk;
const Util = imports.misc.util;
const Lang = imports.lang;
const Json = imports.gi.Json;
const Gettext = imports.gettext.domain('glunarclock');
const _ = Gettext.gettext;

const SETTINGS_SCHEMA = 'org.gnome.shell.extensions.lunar-clock';
const POSITION_IN_PANEL_KEY = 'position-in-panel';
const Position = {
    CENTER: 0,
    RIGHT: 1,
    LEFT: 2
}
const PIXMAPS = '/pixmaps/lunar-clock';

let clock;

function LunarClock() {
    this._init();
}

function getSettings(schema) {
    if (Gio.Settings.list_schemas().indexOf(schema) == -1)
        throw _("Schema \"%s\" not found.").format(schema);
    return new Gio.Settings({ schema: schema });
}

LunarClock.prototype = {
	__proto__: PanelMenu.Button.prototype,
	_init: function() {
        // Load settings
        this._settings = getSettings(SETTINGS_SCHEMA);
		this._position_in_panel = this._settings.get_enum(POSITION_IN_PANEL_KEY);
		this._icon_type = St.IconType.FULLCOLOR;
    this._refresh_interval = 3600;

		this._moonId = 0;

		this._moons = new Array();
		this._bigmoons = new Array();
		let sysdirs = GLib.get_system_data_dirs();
		let base = '';
		for (let i = 0; i < sysdirs.length; i++) {
			//global.log('seeking icons in ' + sysdirs[i] + PIXMAPS + ' ...');
			let file = Gio.file_new_for_path(sysdirs[i] + PIXMAPS + '/24x24/lunar-clock-0.png');
			if (file.query_exists(null)) {
				//global.log('Found !');
				base = sysdirs[i] + PIXMAPS;
				break;
			}
		}
		for (let i = 0; i < 56; ++i) {
			this._moons[i] = Gio.icon_new_for_string(base + '/24x24/lunar-clock-' + i + '.png');
			this._bigmoons[i] = Gio.icon_new_for_string(base + '/48x48/lunar-clock-' + i + '.png');
			//global.log('icon ' + i + ': ' + this._moons[i]);
		}

        // Panel icon
        this._icon = new St.Icon({
            icon_type: this._icon_type,
						icon_size: 24,
            gicon: this._moons[20],
            style_class: 'system-status-icon lunar-icon'
        });

        // Panel menu item - the current class
        let menuAlignment = 0.25;
        PanelMenu.Button.prototype._init.call(this, menuAlignment);

        this.actor.add_actor(this._icon);
        let children = null;
        switch (this._position_in_panel) {
            case Position.LEFT:
                children = Main.panel._leftBox.get_children();
                Main.panel._leftBox.insert_actor (this.actor, children.length-1);
                break;
            case Position.CENTER:
                Main.panel._centerBox.add(this.actor, { y_fill: true });
                break;
            case Position.RIGHT:
                children = Main.panel._rightBox.get_children();
                Main.panel._rightBox.insert_actor(this.actor, children.length-1);
                break;
			default:
                Main.panel._centerBox.add(this.actor, { y_fill: true });
                break;
        }

        // Moon details
        this._moonDet = new St.Bin({ style_class: 'moon' });
		this._bigmoonIcon = new St.Icon({
            icon_type: this._icon_type,
			icon_size: 48,
            gicon: this._bigmoons[20],
            style_class: 'lunar-icon'
        });
		this._moonDetLabel = new St.Label({ text: _('Details ... lorem ipsum et caetera') });
		let box = new St.BoxLayout({ style_class: 'lunar-clock-details' });
		box.add_actor(this._bigmoonIcon);
		box.add_actor(this._moonDetLabel);
		this._moonDet.set_child(box);
        // Astronomical details
        this._AstroDet = new St.Bin({ style_class: 'astro' });

        // Separator (copied from Gnome shell's popupMenu.js)
        this._separatorArea = new St.DrawingArea({ style_class: 'popup-separator-menu-item' });
        this._separatorArea.width = 200;
        this._separatorArea.connect('repaint', Lang.bind(this, this._onSeparatorAreaRepaint));

        // Putting the popup item together
        let mainBox = new St.BoxLayout({ vertical: true });
        mainBox.add_actor(this._moonDet);
        mainBox.add_actor(this._separatorArea);
        mainBox.add_actor(this._AstroDet);
        this.menu.addActor(mainBox);
	},

    // Copied from Gnome shell's popupMenu.js
    _onSeparatorAreaRepaint: function(area) {
        let cr = area.get_context();
        let themeNode = area.get_theme_node();
        let [width, height] = area.get_surface_size();
        let margin = themeNode.get_length('-margin-horizontal');
        let gradientHeight = themeNode.get_length('-gradient-height');
        let startColor = themeNode.get_color('-gradient-start');
        let endColor = themeNode.get_color('-gradient-end');

        let gradientWidth = (width - margin * 2);
        let gradientOffset = (height - gradientHeight) / 2;
        let pattern = new Cairo.LinearGradient(margin, gradientOffset, width - margin, gradientOffset + gradientHeight);
        pattern.addColorStopRGBA(0, startColor.red / 255, startColor.green / 255, startColor.blue / 255, startColor.alpha / 255);
        pattern.addColorStopRGBA(0.5, endColor.red / 255, endColor.green / 255, endColor.blue / 255, endColor.alpha / 255);
        pattern.addColorStopRGBA(1, startColor.red / 255, startColor.green / 255, startColor.blue / 255, startColor.alpha / 255);
        cr.setSource(pattern);
        cr.rectangle(margin, gradientOffset, gradientWidth, gradientHeight);
        cr.fill();
    },

    refreshMoon: function(loop) {
        //global.log('refreshMoon()');
		let cmd = "lunar-clock-helper";
		let helperJSON = this.spawnCommandLine(cmd);
        //global.log('helperJSON: ' + helperJSON);
		let jp = new Json.Parser();
		jp.load_from_data("" + helperJSON + "", -1);
		this.moondata = jp.get_root().get_object();
		//global.log("moondata: " + this.moondata);
        let moonId = this.moondata.get_int_member('image_number');
		let fullMoon = this.moondata.get_double_member('full_moon');
		//global.log('moonId: ' + moonId + " - fullMoon: " + fullMoon);
        this._icon.gicon = this._moons[moonId];
        this._bigmoonIcon.gicon = this._bigmoons[moonId];
		/* build details */
		let alt = this.moondata.get_double_member('altitude');
		var det = "";
		if (alt < 0) {
			det += _("The moon is currently below the horizon.");
		}
		else {
			det += _("The moon is currently above the horizon.");
		}
		det += "\n" + _("Moonrise & Moonset (Universal Time)") + ": ";
		det += this.moondata.get_string_member('rise') + ' & ' + 
			this.moondata.get_string_member('set');
		this._moonDetLabel.text = det;
		/* build astronomical details */
        let box = new St.Table({ homogeneous: false });
		let fr = new St.Label({ text: _("Fraction of Cycle") });
		let frv = new St.Label({ text: this.moondata.get_double_member('phase') + "%" });
		let alt = new St.Label({ text: _("Altitude") });
		let altv = new St.Label({ text:this.moondata.get_double_member('altitude') + " \u00b0" });
		let azm = new St.Label({ text: _("Azimuth") });
		let azmv = new St.Label({ text: this.moondata.get_double_member('azimuth') + " \u00b0" });
		let nm = new St.Label({ text: _("Days to New Moon") });
		let nmv = new St.Label({ text: this.moondata.get_double_member('new_moon') + "" });
		let fm = new St.Label({ text: _("Days to Full Moon") });
		let fmv = new St.Label({ text: this.moondata.get_double_member('full_moon') + "" });
		box.add(fr, {row: 0, col: 0, x_fill:false, y_fill:false});
		box.add(frv, {row: 0, col: 1, x_fill:false, y_fill:false});
		box.add(alt, {row: 1, col: 0, x_fill:false, y_fill:false});
		box.add(altv, {row: 1, col: 1, x_fill:false, y_fill:false});
		box.add(azm, {row: 2, col: 0, x_fill:false, y_fill:false});
		box.add(azmv, {row: 2, col: 1, x_fill:false, y_fill:false});
		box.add(nm, {row: 3, col: 0, x_fill:false, y_fill:false});
		box.add(nmv, {row: 3, col: 1, x_fill:false, y_fill:false});
		box.add(fm, {row: 4, col: 0, x_fill:false, y_fill:false});
		box.add(fmv, {row: 4, col: 1, x_fill:false, y_fill:false});
		this._AstroDet.set_child(box);
		/* register next refresh */
        if (loop) Mainloop.timeout_add_seconds(this._refresh_interval, Lang.bind(this, function() {
            if (Main.panel._moon) this.refreshMoon(true);
        }));
    },

    spawnCommandLine: function(command_line) {
        try {
            let [success, argv] = GLib.shell_parse_argv(command_line);
            return this.trySpawn(argv);
        } catch (err) {
            let title = _("Execution of '%s' failed:").format(command_line);
            Main.notifyError(title, err.message);
            global.log(title + err.message);
            return null;
        }
    },

    trySpawn: function(argv)
    {
        try {
            let [success, stdout, stderr] = GLib.spawn_sync(null, argv, null,
                                     GLib.SpawnFlags.SEARCH_PATH, null, null);
            //global.log('stdout: ' + stdout);
            return stdout;
        } catch (err) {
            if (err.code == GLib.SpawnError.G_SPAWN_ERROR_NOENT) {
                err.message = _("Command not found");
            } else {
                // The exception from gjs contains an error string like:
                //   Error invoking GLib.spawn_command_line_async: Failed to
                //   execute child process "foo" (No such file or directory)
                // We are only interested in the part in the parentheses. (And
                // we can't pattern match the text, since it gets localized.)
                err.message = err.message.replace(/.*\((.+)\)/, '$1');
            }

            throw err;
        }
    }
};

function init() {
}

function enable() {
	clock = new LunarClock();
    Main.panel.addToStatusArea('lunar-clock', clock);
    Main.panel._moon = clock;
    clock.refreshMoon(true);
}

function disable() {
    clock.destroy();
    Main.panel._moon = null;
}
