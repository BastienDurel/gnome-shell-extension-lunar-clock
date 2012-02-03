FILES=metadata.json extension.js stylesheet.css
SCHEMA=org.gnome.shell.extensions.lunar-clock.gschema.xml
NAME=lunarClock@geekwu.org

LEGACY=legacy/glunarclock-0.34.1
FRGMO=$(LEGACY)/po/fr.gmo

DIR=$(DESTDIR)/usr/share/gnome-shell/extensions/$(NAME)
SDIR=$(DESTDIR)/usr/share/glib-2.0/schemas/
LOCALDIR=$(HOME)/.local/share/gnome-shell/extensions/$(NAME)
LOCALSDIR=$(DESTDIR)/.local/share/glib-2.0/schemas/

EXT=$(FILES) $(SCHEMA) $(FRGMO)

all: $(EXT)

po: $(FRGMO)

$(LEGACY):
	tar zxv -C legacy -f legacy/glunarclock_0.34.1.orig.tar.gz
$(LEGACY)/Makefile: legacy/glunarclock-0.34.1
	(cd $< ; GNOME_APPLETS_CFLAGS=-I. GNOME_APPLETS_LIBS=-L. ./configure --prefix=/usr)
$(FRGMO): legacy/glunarclock-0.34.1/Makefile
	make -C legacy/glunarclock-0.34.1/po

install: $(DIR) $(EXT)
	install -d $(DIR)
	install -d $(SDIR)
	install $(FILES) $(DIR)
	install $(SCHEMA) $(SDIR)
	make DESTDIR=$(DESTDIR) -C $(LEGACY)/po install

install-local: $(LOCALDIR) $(EXT)
	install $(FILES) $(LOCALDIR)
	install $(SCHEMA) $(LOCALSDIR)
	make DESTDIR=$(HOME)/.local -C $(LEGACY)/po install

$(DIR):
	mkdir -p $@

clean:
	-make -C $(LEGACY) distclean

