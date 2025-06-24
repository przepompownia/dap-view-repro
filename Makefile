SHELL := /bin/bash
DIR := ${CURDIR}
NVIM_BINARY := /usr/bin/nvim

vscodePhpDebugVersion := '1.36.1'
vscodePhpDebugUrl := 'https://github.com/xdebug/vscode-php-debug/releases/download/v1.36.1/php-debug-1.36.1.vsix'

.ONESHELL:
install-vscode-php-debug:
	set -e
	[[ -d $(DIR)/tools/vscode-php-debug/$(vscodePhpDebugVersion)/ ]] && exit
	$(DIR)/bin/dap-adapter-utils install xdebug vscode-php-debug $(vscodePhpDebugVersion) $(vscodePhpDebugUrl)
	$(DIR)/bin/dap-adapter-utils setAsCurrent vscode-php-debug $(vscodePhpDebugVersion)

start: install-vscode-php-debug
	$(NVIM_BINARY) -u init.lua

clean-adapter:
	rm -rvf $(DIR)/tools/

clean-plugins:
	rm -rvf $(DIR)/plugins/

clean: clean-adapter clean-plugins
