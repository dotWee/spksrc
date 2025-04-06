SPK_NAME = rclone
SPK_VERS = 1.69.1
SPK_REV = 1
SPK_ICON = src/logo.png

DEPENDS = cross/rclone

UNSUPPORTED_ARCHS = $(PPC_ARCHS)

MAINTAINER = dotwee
DESCRIPTION = Rclone is a command-line program to manage files on cloud storage. It is a feature-rich alternative to cloud vendors' web storage interfaces.
DISPLAY_NAME = rclone
STARTABLE = yes
SERVICE_USER = auto
SERVICE_SETUP = src/service-setup.sh
FWPORTS = src/rclone.sc
# Web GUI port
ADMIN_PORT = 5572

WIZARDS_DIR = src/wizard/

CHANGELOG = "Initial release."

HOMEPAGE = https://rclone.org/
HELPURL = https://rclone.org/docs/

LICENSE  = MIT

SPK_COMMANDS = bin/rclone

POST_STRIP_TARGET = rclone_extra_install

include ../../mk/spksrc.spk.mk

.PHONY: rclone_extra_install
rclone_extra_install:
	@install -d -m 755 $(STAGING_DIR)/var
	@install -m 644 src/environment-variables $(STAGING_DIR)/var/
