FILES=metadata.json extension.js stylesheet.css
SCHEMA=org.gnome.shell.extensions.lunar-clock.gschema.xml
NAME=lunarClock@geekwu.org
HELPER=lunar-clock-helper

IMG=pixmaps/48/lunar-clock-0.png pixmaps/24/lunar-clock-55.png

LEGACY=legacy/glunarclock-0.34.1
FRGMO=$(LEGACY)/po/fr.gmo

HELPERC=helper.c $(LEGACY)/src/CalcEphem.c $(LEGACY)/src/Moon.c $(LEGACY)/src/MoonRise.c
HELPEROBJ=$(HELPERC:.c=.o)
CFLAGS=$(shell pkg-config --cflags glib-2.0) -I$(LEGACY)/src
LDFLAGS=$(shell pkg-config --libs glib-2.0) -lm

DEB=../gnome-shell-extension-lunar-clock_0.1-1_all.deb

DIR=$(DESTDIR)/usr/share/gnome-shell/extensions/$(NAME)
SDIR=$(DESTDIR)/usr/share/glib-2.0/schemas/
BDIR=$(DESTDIR)/usr/bin

LOCAL=$(DESTDIR)$(HOME)/.local
LOCALDIR=$(LOCAL)/share/gnome-shell/extensions/$(NAME)
LOCALSDIR=$(LOCAL)/share/glib-2.0/schemas/
LOCALBDIR=$(LOCAL)/bin

PIXMAPDIR=share/pixmaps/lunar-clock

EXT=$(FILES) $(SCHEMA) $(FRGMO) $(IMG) $(HELPER)

all: $(EXT)

po: $(FRGMO)

deb: $(DEB)
$(DEB): $(EXT)
	dpkg-buildpackage -b -uc
deb-install: $(DEB)
	sudo dpkg -i $(DEB)

root-install:
	sudo install $(FILES) $(DIR)
	sudo install $(SCHEMA) $(SDIR)
	sudo install $(HELPER) $(BDIR)
	sudo glib-compile-schemas $(SDIR)

$(LEGACY):
	tar zxv -C legacy -f legacy/glunarclock_0.34.1.orig.tar.gz
$(LEGACY)/configure:
	test -d $(LEGACY) || make $(LEGACY)
	(cd $(LEGACY) ; autoconf)
$(LEGACY)/Makefile: $(LEGACY)/configure
	(cd $(LEGACY) ; GNOME_APPLETS_CFLAGS=-I. GNOME_APPLETS_LIBS=-L. ./configure --prefix=/)
$(FRGMO): $(LEGACY)/Makefile
	make -C $(LEGACY)/po

$(HELPER): $(HELPEROBJ)
	$(CC) -o $@ $(HELPEROBJ) $(LDFLAGS)

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

install: $(EXT)
	install -d $(DIR)
	install -d $(SDIR)
	install -d $(BDIR)
	install -d $(DESTDIR)/usr/$(PIXMAPDIR)/48x48
	install -d $(DESTDIR)/usr/$(PIXMAPDIR)/24x24
	install -m 644 $(FILES) $(DIR)
	install -m 644 $(SCHEMA) $(SDIR)
	install $(HELPER) $(BDIR)
	make DESTDIR=$(DESTDIR)/usr -C $(LEGACY)/po install
	for i in `seq 0 55` ; do install -m 644 pixmaps/48/lunar-clock-$$i.png $(DESTDIR)/usr/$(PIXMAPDIR)/48x48 ; done
	for i in `seq 0 55` ; do install -m 644 pixmaps/24/lunar-clock-$$i.png $(DESTDIR)/usr/$(PIXMAPDIR)/24x24 ; done

install-local: $(EXT)
	install -d $(LOCALDIR)
	install -d $(LOCALSDIR)
	install -d $(LOCALBDIR)
	install -m 644 $(FILES) $(LOCALDIR)
	install -m 644 $(SCHEMA) $(LOCALSDIR)
	install -d $(LOCAL)/$(PIXMAPDIR)/48x48
	install -d $(LOCAL)/$(PIXMAPDIR)/24x24
	install $(HELPER) $(LOCALBDIR)
	make DESTDIR=$(LOCAL) -C $(LEGACY)/po install
	for i in `seq 0 55` ; do install -m 644 pixmaps/48/lunar-clock-$$i.png $(LOCAL)/$(PIXMAPDIR)/48x48 ; done
	for i in `seq 0 55` ; do install -m 644 pixmaps/24/lunar-clock-$$i.png $(LOCAL)/$(PIXMAPDIR)/24x24 ; done

$(DIR):
	mkdir -p $@

clean:
	-make -C $(LEGACY) distclean
	rm -Rf $(LEGACY) pixmaps $(HELPEROBJ)

