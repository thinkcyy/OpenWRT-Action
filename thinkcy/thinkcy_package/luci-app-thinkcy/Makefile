include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-thinkcy
PKG_VERSION:=1.0.0
PKG_RELEASE:=1
PKG_MAINTAINER:=ThinkCy Team <team@thinkcy.org>
PKG_LICENSE:=GPL-3.0-only
PKG_LICENSE_FILES:=LICENSE

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
  SECTION:=luci
  CATEGORY:=LuCI
  SUBMENU:=3. Applications
  TITLE:=ThinkCy System Controls
  DEPENDS:=+luci-base +luci-compat
  PKGARCH:=all
endef

define Package/$(PKG_NAME)/description
  A LuCI web interface for managing Clash, VPN and DDNS services.
  Provides easy toggles for enabling/disabling these services.
endef

define Package/$(PKG_NAME)/conffiles
/etc/config/thinkcy
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_CONF) ./files/etc/config/thinkcy $(1)/etc/config/
	
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/etc/init.d/thinkcy $(1)/etc/init.d/
	
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/controller
	$(INSTALL_DATA) ./files/usr/lib/lua/luci/controller/thinkcy.lua \
		$(1)/usr/lib/lua/luci/controller/
	
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/model/cbi/thinkcy
	$(INSTALL_DATA) ./files/usr/lib/lua/luci/model/cbi/thinkcy/thinkcy.uc \
		$(1)/usr/lib/lua/luci/model/cbi/thinkcy/
	
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/view/thinkcy
	$(INSTALL_DATA) ./files/usr/lib/lua/luci/view/thinkcy/*.htm \
		$(1)/usr/lib/lua/luci/view/thinkcy/
	
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/applications
	$(INSTALL_DATA) ./files/usr/lib/lua/luci/applications/thinkcy.json \
		$(1)/usr/lib/lua/luci/applications/
	
	$(INSTALL_DIR) $(1)/usr/share/rpcd/acl.d
	$(INSTALL_DATA) ./files/usr/share/rpcd/acl.d/luci-app-thinkcy.json \
		$(1)/usr/share/rpcd/acl.d/
	
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) ./src/thinkcy-status $(1)/usr/bin/
endef

include $(INCLUDE_DIR)/luci.mk

# call BuildPackage - must be last
$(eval $(call BuildPackage,$(PKG_NAME)))
