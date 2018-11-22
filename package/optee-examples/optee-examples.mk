################################################################################
#
# optee-examples
#
################################################################################

OPTEE_EXAMPLES_VERSION = $(call qstrip,$(BR2_PACKAGE_OPTEE_EXAMPLES_VERSION))
OPTEE_EXAMPLES_LICENSE = BSD-2-Clause
OPTEE_EXAMPLES_LICENSE_FILES = LICENSE

ifeq ($(BR2_PACKAGE_OPTEE_EXAMPLES_CUSTOM_GIT),y)
OPTEE_EXAMPLES_SITE = $(call qstrip,$(BR2_PACKAGE_OPTEE_EXAMPLES_CUSTOM_REPO_URL))
OPTEE_EXAMPLES_SITE_METHOD = git
BR_NO_CHECK_HASH_FOR += $(OPTEE_EXAMPLES_SOURCE)
else
OPTEE_EXAMPLES_SITE = $(call github,linaro-swg,optee_examples,$(OPTEE_EXAMPLES_VERSION))
endif

OPTEE_EXAMPLES_DEPENDENCIES = optee-client optee-os
OPTEE_EXAMPLES_INSTALL_STAGING = YES

ifeq ($(BR2_aarch64),y)
OPTEE_EXAMPLES_SDK = $(STAGING_DIR)/lib/optee/export-ta_arm64
endif
ifeq ($(BR2_arm),y)
OPTEE_EXAMPLES_SDK = $(STAGING_DIR)/lib/optee/export-ta_arm32
endif

define OPTEE_EXAMPLES_BUILD_TAS
	@$(foreach f,$(wildcard $(@D)/*/ta/Makefile), \
		$(TARGET_CONFIGURE_OPTS) \
		$(MAKE) CROSS_COMPILE=$(TARGET_CROSS) \
			O=out TA_DEV_KIT_DIR=$(OPTEE_EXAMPLES_SDK) \
			-C $(dir $f) all &&) true
endef

define OPTEE_EXAMPLES_INSTALL_TAS
	@$(foreach f,$(wildcard $(@D)/*/ta/out/*.ta), \
		mkdir -p $(TARGET_DIR)/lib/optee_armtz && \
		$(INSTALL) -v -p --mode=444 \
			--target-directory=$(TARGET_DIR)/lib/optee_armtz $f \
			&&) true
endef

OPTEE_EXAMPLES_POST_BUILD_HOOKS += OPTEE_EXAMPLES_BUILD_TAS
OPTEE_EXAMPLES_POST_INSTALL_TARGET_HOOKS += OPTEE_EXAMPLES_INSTALL_TAS

$(eval $(cmake-package))
