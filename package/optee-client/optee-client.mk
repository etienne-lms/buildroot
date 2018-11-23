################################################################################
#
# optee-client
#
################################################################################

OPTEE_CLIENT_VERSION = $(call qstrip,$(BR2_PACKAGE_OPTEE_CLIENT_VERSION))
OPTEE_CLIENT_LICENSE = BSD-3-Clause
OPTEE_CLIENT_LICENSE_FILES = LICENSE

ifeq ($(BR2_PACKAGE_OPTEE_CLIENT_CUSTOM_GIT),y)
OPTEE_CLIENT_SITE = $(call qstrip,$(BR2_PACKAGE_OPTEE_CLIENT_CUSTOM_REPO_URL))
OPTEE_CLIENT_SITE_METHOD = git
BR_NO_CHECK_HASH_FOR += $(OPTEE_CLIENT_SOURCE)
else
OPTEE_CLIENT_SITE = $(call github,OP-TEE,optee_client,$(OPTEE_CLIENT_VERSION))
endif

define OPTEE_CLIENT_INSTALL_SUPPLICANT_SCRIPT
	$(INSTALL) -m 0755 -D $(OPTEE_CLIENT_PKGDIR)/S30optee \
		$(TARGET_DIR)/etc/init.d/S30optee
endef

define OPTEE_CLIENT_INSTALL_INIT_SYSV
	$(OPTEE_CLIENT_INSTALL_SUPPLICANT_SCRIPT)
endef

OPTEE_CLIENT_INSTALL_STAGING = YES

$(eval $(cmake-package))
