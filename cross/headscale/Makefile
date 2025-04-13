PKG_NAME = headscale
PKG_VERS = 0.25.1
PKG_EXT = tar.gz

PKG_DIST_NAME = v$(PKG_VERS).$(PKG_EXT)
PKG_DIST_SITE = https://github.com/juanfont/$(PKG_NAME)/archive/refs/tags
PKG_DIR = $(PKG_NAME)

BUILD_DEPENDS = native/go

HOMEPAGE = https://github.com/juanfont/headscale
COMMENT  = Headscale is a platform for managing and monitoring your fleet of servers.
LICENSE  = MIT

#POST_INSTALL_TARGET = headscale_post_install

GO_SRC_DIR = $(WORK_DIR)/$(PKG_NAME)-$(PKG_VERS)
GO_BIN_DIR = $(GO_SRC_DIR)/$(PKG_NAME)

GO_BUILD_ARGS += -ldflags "-s -w -X github.com/juanfont/headscale/cmd/headscale/cli.Version=$(PKG_VERS)"
#GO_LDFLAGS = -s -w

include ../../mk/spksrc.cross-go.mk

#headscale_post_install:
#	install -m 755 -d $(STAGING_INSTALL_PREFIX)/headscale
