FILES=metadata.json extension.js stylesheet.css
SCHEMA=org.gnome.shell.extensions.lunar-clock.gschema.xml
NAME=lunarClock@geekwu.org

IMG=pixmaps/48/lunar-clock-0.png pixmaps/24/lunar-clock-55.png

LEGACY=legacy/glunarclock-0.34.1
FRGMO=$(LEGACY)/po/fr.gmo

DEB=../gnome-shell-extension-lunar-clock_0.1-1_all.deb

DIR=$(DESTDIR)/usr/share/gnome-shell/extensions/$(NAME)
SDIR=$(DESTDIR)/usr/share/glib-2.0/schemas/
LOCALDIR=$(HOME)/.local/share/gnome-shell/extensions/$(NAME)
LOCALSDIR=$(DESTDIR)/.local/share/glib-2.0/schemas/

EXT=$(FILES) $(SCHEMA) $(FRGMO) $(IMG)

all: $(EXT)

po: $(FRGMO)

deb: $(DEB)
$(DEB): $(EXT)
	dpkg-buildpackage -b
deb-install: $(DEB)
	sudo dpkg -i $(DEB)

root-install:
	sudo install $(SCHEMA) /usr/share/glib-2.0/schemas
	sudo install $(FILES) /usr/share/gnome-shell/extensions/lunarClock@geekwu.org
	sudo glib-compile-schemas /usr/share/glib-2.0/schemas/

$(LEGACY):
	tar zxv -C legacy -f legacy/glunarclock_0.34.1.orig.tar.gz
$(LEGACY)/Makefile: $(LEGACY)
	(cd $< ; autoconf ; GNOME_APPLETS_CFLAGS=-I. GNOME_APPLETS_LIBS=-L. ./configure --prefix=/usr)
$(FRGMO): $(LEGACY)/Makefile
	make -C $(LEGACY)/po

pixmaps:
	mkdir $@
pixmaps/24:
	mkdir $@
pixmaps/48:
	mkdir $@
$(IMG): pixmaps pixmaps/24 pixmaps/48 $(LEGACY)/pixmaps/moon_56frames.png
	for i in `seq 0 55` ; do \
		convert $(LEGACY)/pixmaps/moon_56frames.png -crop 48x48+`echo $$i*48+1|bc`+1 pixmaps/48/lunar-clock-$$i.png\
		&& convert pixmaps/48/lunar-clock-$$i.png -resize 24x24 pixmaps/24/lunar-clock-$$i.png;\
	done

install: $(DIR) $(EXT)
	install -d $(DIR)
	install -d $(SDIR)
	install -d $(DESTDIR)/usr/share/icons/gnome/48x48
	install -d $(DESTDIR)/usr/share/icons/gnome/24x24
	install $(FILES) $(DIR)
	install $(SCHEMA) $(SDIR)
	make DESTDIR=$(DESTDIR) -C $(LEGACY)/po install
	for i in `seq 0 55` ; do install pixmaps/48/lunar-clock-$$i.png $(DESTDIR)/usr/share/icons/gnome/48x48 ; done
	for i in `seq 0 55` ; do install pixmaps/24/lunar-clock-$$i.png $(DESTDIR)/usr/share/icons/gnome/24x24 ; done

install-local: $(LOCALDIR) $(EXT)
	install $(FILES) $(LOCALDIR)
	install $(SCHEMA) $(LOCALSDIR)
	make DESTDIR=$(HOME)/.local -C $(LEGACY)/po install

$(DIR):
	mkdir -p $@

clean:
	-make -C $(LEGACY) distclean

