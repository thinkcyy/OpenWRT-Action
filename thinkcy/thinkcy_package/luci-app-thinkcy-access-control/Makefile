include $(TOPDIR)/rules.mk

LUCI_TITLE:=MAC Address Internet Access Control (With Schedule & Timeout)
LUCI_DEPENDS:=+firewall4 +rpcd
LUCI_PKGARCH:=all

PKG_NAME:=luci-app-maccontrol
PKG_VERSION:=3.0
PKG_RELEASE:=1

include $(INCLUDE_DIR)/package.mk

define Package/luci-app-maccontrol
  SECTION:=luci
  CATEGORY:=LuCI
  SUBMENU:=3. Applications
  TITLE:=MAC Internet Access Control App
  DEPENDS:=+firewall4 +rpcd
endef

define Build/Compile
endef

define Package/luci-app-maccontrol/install
	$(INSTALL_DIR) $(1)/usr/libexec/rpcd
	$(INSTALL_BIN) ./root/usr/libexec/rpcd/maccontrol $(1)/usr/libexec/rpcd/maccontrol

	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_BIN) ./root/usr/sbin/maccontrol-cli $(1)/usr/sbin/maccontrol-cli

	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_DATA) ./root/etc/config/maccontrol $(1)/etc/config/maccontrol

	$(INSTALL_DIR) $(1)/usr/share/luci/menu.d
	$(INSTALL_DATA) ./root/share/luci/menu.d/luci-app-maccontrol.json $(1)/usr/share/luci/menu.d/luci-app-maccontrol.json

	$(INSTALL_DIR) $(1)/usr/share/luci/resources/view/maccontrol
	$(INSTALL_DATA) ./root/share/luci/resources/view/maccontrol/main.js $(1)/usr/share/luci/resources/view/maccontrol/main.js
endef

$(eval $(call BuildPackage,luci-app-maccontrol))
