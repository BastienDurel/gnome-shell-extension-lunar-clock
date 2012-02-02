#
# Regular cron jobs for the gnome-shell-extension-lunar-clock package
#
0 4	* * *	root	[ -x /usr/bin/gnome-shell-extension-lunar-clock_maintenance ] && /usr/bin/gnome-shell-extension-lunar-clock_maintenance
