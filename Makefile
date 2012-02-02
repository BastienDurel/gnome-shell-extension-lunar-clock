FILES=metadata.json extension.js
NAME=tint2_space@geekwu.org
DIR=$(HOME)/.local/share/gnome-shell/extensions/$(NAME)

all: 

install: $(DIR)
	cp $(FILES) $(DIR)/

$(DIR):
	mkdir -p $@

