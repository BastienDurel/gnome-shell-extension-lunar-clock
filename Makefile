FILES=metadata.json extension.js stylesheet.css
NAME=lunarClock@geekwu.org
DIR=$(DESTDIR)$(HOME)/.local/share/gnome-shell/extensions/$(NAME)

all: 

install: $(DIR)
	cp $(FILES) $(DIR)/

$(DIR):
	mkdir -p $@


