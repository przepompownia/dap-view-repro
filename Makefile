SHELL := /bin/bash
DIR := ${CURDIR}
NVIM_BINARY := /usr/bin/nvim

vscodePhpDebugVersion := '1.36.1'
vscodePhpDebugUrl := 'https://github.com/xdebug/vscode-php-debug/releases/download/v1.36.1/php-debug-1.36.1.vsix'

.ONESHELL:
install-vscode-php-debug:
	set -e
	$(DIR)/bin/dap-adapter-utils install xdebug vscode-php-debug $(vscodePhpDebugVersion) $(vscodePhpDebugUrl)
	$(DIR)/bin/dap-adapter-utils setAsCurrent vscode-php-debug $(vscodePhpDebugVersion)

.ONESHELL:
composer-get-executable:
	[[ -e bin/composer ]] && exit
	curl -sS https://getcomposer.org/installer | php -- --filename=bin/composer

composer:
	$(DIR)/bin/composer install

start: install-vscode-php-debug composer-get-executable composer
	$(NVIM_BINARY) -u init.lua
