SHELL := /usr/bin/env bash
INSTALL := ./install.sh

.PHONY: all dry-run apply uninstall vscode git-config

all:
	$(INSTALL)

dry-run:
	$(INSTALL) --dry-run

apply:
	$(INSTALL) --yes

uninstall:
	$(INSTALL) uninstall

vscode:
	$(INSTALL) --yes vscode

git-config:
	$(INSTALL) git-config
