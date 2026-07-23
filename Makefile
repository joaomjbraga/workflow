SHELL := /usr/bin/env bash
INSTALL := ./install.sh

.PHONY: all docker fonts zsh node go applications uninstall dry-run

.PHONY: vscode

all: $(INSTALL)
	$(INSTALL)

dry-run:
	$(INSTALL) --dry-run

docker:
	$(INSTALL) --dry-run=false && $(INSTALL) docker || true

fonts:
	$(INSTALL) --dry-run=false && $(INSTALL) fonts || true

zsh:
	$(INSTALL) --dry-run=false && $(INSTALL) zsh || true

node:
	$(INSTALL) --dry-run=false && $(INSTALL) node || true

go:
	$(INSTALL) --dry-run=false && $(INSTALL) go || true

applications:
	$(INSTALL) --dry-run=false && $(INSTALL) applications || true

uninstall:
	$(INSTALL) uninstall

apply:
	$(INSTALL) --yes

vscode:
	$(INSTALL) --yes vscode
