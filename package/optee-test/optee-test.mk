################################################################################
#
# optee-test
#
################################################################################

OPTEE_TEST_VERSION = $(call qstrip,$(BR2_PACKAGE_OPTEE_TEST_VERSION))
OPTEE_TEST_LICENSE = GPL-2.0, BSD-2-Clause,
OPTEE_TEST_LICENSE_FILES = LICENSE.md

ifeq ($(BR2_PACKAGE_OPTEE_TEST_CUSTOM_GIT),y)
OPTEE_TEST_SITE = $(call qstrip,$(BR2_PACKAGE_OPTEE_TEST_CUSTOM_REPO_URL))
OPTEE_TEST_SITE_METHOD = git
BR_NO_CHECK_HASH_FOR += $(OPTEE_TEST_SOURCE)
else
OPTEE_TEST_SITE = $(call github,OP-TEE,optee_test,$(OPTEE_TEST_VERSION))
endif

OPTEE_TEST_DEPENDENCIES = optee-client optee-os

ifeq ($(BR2_aarch64),y)
OPTEE_TEST_SDK = $(STAGING_DIR)/lib/optee/export-ta_arm64
endif
ifeq ($(BR2_arm),y)
OPTEE_TEST_SDK = $(STAGING_DIR)/lib/optee/export-ta_arm32
endif
OPTEE_TEST_CONF_OPTS = -DOPTEE_TEST_SDK=$(OPTEE_TEST_SDK)

define OPTEE_TEST_BUILD_TAS
	@$(foreach f,$(wildcard $(@D)/ta/*/Makefile), \
		$(TARGET_CONFIGURE_OPTS) \
		$(MAKE) CROSS_COMPILE=$(TARGET_CROSS) \
			TA_DEV_KIT_DIR=$(OPTEE_TEST_SDK) \
			-C $(dir $f) all &&) true
endef

define OPTEE_TEST_INSTALL_TAS
	@$(foreach f,$(wildcard $(@D)/ta/*/out/*.ta), \
		mkdir -p $(TARGET_DIR)/lib/optee_armtz && \
		$(INSTALL) -v -p --mode=444 \
			--target-directory=$(TARGET_DIR)/lib/optee_armtz $f \
			&&) true
endef

OPTEE_TEST_POST_BUILD_HOOKS += OPTEE_TEST_BUILD_TAS
OPTEE_TEST_POST_INSTALL_TARGET_HOOKS += OPTEE_TEST_INSTALL_TAS

$(eval $(cmake-package))
