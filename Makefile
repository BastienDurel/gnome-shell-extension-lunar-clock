FILES=metadata.json extension.js stylesheet.css
SCHEMA=org.gnome.shell.extensions.lunar-clock.gschema.xml
NAME=lunarClock@geekwu.org
DIR=$(DESTDIR)/usr/share/gnome-shell/extensions/$(NAME)
SDIR=$(DESTDIR)/usr/share/glib-2.0/schemas/
LOCALDIR=$(HOME)/.local/share/gnome-shell/extensions/$(NAME)
LOCALSDIR=$(DESTDIR)/.local/share/glib-2.0/schemas/

all: $(FILES) $(SCHEMA)

install: $(DIR)
	install -d $(DIR)
	install -d $(SDIR)
	install $(FILES) $(DIR)
	install $(SCHEMA) $(SDIR)

install-local: $(LOCALDIR)
	install $(FILES) $(LOCALDIR)
	install $(SCHEMA) $(LOCALSDIR)

$(DIR):
	mkdir -p $@


