################################################################################
#
# optee-os
#
################################################################################

OPTEE_OS_VERSION = $(call qstrip,$(BR2_TARGET_OPTEE_OS_VERSION))
OPTEE_OS_LICENSE = BSD-2-Clause
OPTEE_OS_LICENSE_FILES = LICENSE

ifeq ($(BR2_TARGET_OPTEE_OS_CUSTOM_GIT),y)
OPTEE_OS_SITE = $(call qstrip,$(BR2_TARGET_OPTEE_OS_CUSTOM_REPO_URL))
OPTEE_OS_SITE_METHOD = git
BR_NO_CHECK_HASH_FOR += $(OPTEE_OS_SOURCE)
else
OPTEE_OS_SITE = $(call github,OP-TEE,optee_os,OPTEE_OS_VERSION)
endif

# On 64bit targets, OP-TEE OS can be built in 32bit mode, or
# can be built in 64bit mode and support 32bit and 64bit
# trusted applications. Since buildroot currently references
# a single cross compiler, build exclusively in 32bit
# or 64bit mode.
OPTEE_OS_MAKE_OPTS = CROSS_COMPILE="$(TARGET_CROSS)"
OPTEE_OS_MAKE_OPTS += CROSS_COMPILE_core="$(TARGET_CROSS)"
ifeq ($(BR2_aarch64),y)
OPTEE_OS_MAKE_OPTS += CROSS_COMPILE_ta_arm64="$(TARGET_CROSS)"
endif
ifeq ($(BR2_arm),y)
OPTEE_OS_MAKE_OPTS += CROSS_COMPILE_ta_arm32="$(TARGET_CROSS)"
endif

# Get mandatory PLAFORM and optional PLATFORM_FLAVOR
OPTEE_OS_MAKE_OPTS += PLATFORM=$(call qstrip,$(BR2_TARGET_OPTEE_OS_PLATFORM))
ifneq ($(BR2_TARGET_OPTEE_OS_PLATFORM_FLAVOR),)
OPTEE_OS_MAKE_OPTS += PLATFORM_FLAVOR=$(call qstrip,$(BR2_TARGET_OPTEE_OS_PLATFORM_FLAVOR))
endif
OPTEE_OS_MAKE_OPTS += $(call qstrip,$(BR2_TARGET_OPTEE_OS_ADDITIONAL_VARIABLES))

# OP-TEE OS builds from subdirectory build/ of its synced sourcetree root path
ifeq ($(BR2_aarch64),y)
OPTEE_OS_LOCAL_SDK = build/export-ta_arm64
endif
ifeq ($(BR2_arm),y)
OPTEE_OS_LOCAL_SDK = build/export-ta_arm32
endif

ifeq ($(BR2_TARGET_OPTEE_OS_CORE),y)
define OPTEE_OS_BUILD_CORE
	$(TARGET_MAKE_ENV) $(MAKE) -C $(@D) \
		O=build $(TARGET_CONFIGURE_OPTS) $(OPTEE_OS_MAKE_OPTS) all
endef
define OPTEE_OS_INSTALL_CORE
	mkdir -p $(BINARIES_DIR)
	cp -dpf $(@D)/build/core/tee.bin $(BINARIES_DIR)
	cp -dpf $(@D)/build/core/tee-*_v2.bin $(BINARIES_DIR)
endef
endif

ifeq ($(BR2_TARGET_OPTEE_OS_SDK),y)
define OPTEE_OS_BUILD_SDK
	$(TARGET_MAKE_ENV) $(MAKE) -C $(@D) \
		 O=build $(TARGET_CONFIGURE_OPTS) $(OPTEE_OS_MAKE_OPTS) ta_dev_kit
endef
define OPTEE_OS_INSTALL_SDK
	mkdir -p $(STAGING_DIR)/lib/optee
	cp -ardpf $(@D)/$(OPTEE_OS_LOCAL_SDK) $(STAGING_DIR)/lib/optee
endef
endif

ifeq ($(BR2_TARGET_OPTEE_OS_SERVICES),y)
define OPTEE_OS_BUILD_SERVICES
	$(foreach f,$(wildcard $(@D)/ta_services/*/Makefile), \
		$(TARGET_MAKE_ENV) $(MAKE) -C $(dir $f) \
			O=build $(TARGET_CONFIGURE_OPTS) \
			TA_DEV_KIT_DIR=$(@D)/$(OPTEE_OS_LOCAL_SDK) \
			CROSS_COMPILE=$(TARGET_CROSS) &&) true
endef
define OPTEE_OS_INSTALL_SERVICES
	mkdir -p $(TARGET_DIR)/lib/optee_armtz
	$(foreach f,$(wildcard $(@D)/ta_services/*/build/*.ta), \
		$(INSTALL) -v -p --mode=444 \
			--target-directory=$(TARGET_DIR)/lib/optee_armtz \
			 $f &&) true
endef
endif

define OPTEE_OS_BUILD_CMDS
	$(OPTEE_OS_BUILD_CORE)
	$(OPTEE_OS_BUILD_SDK)
	$(OPTEE_OS_BUILD_SERVICES)
endef

define OPTEE_OS_INSTALL_IMAGES_CMDS
	$(OPTEE_OS_INSTALL_CORE)
	$(OPTEE_OS_INSTALL_SDK)
	$(OPTEE_OS_INSTALL_SERVICES)
endef

OPTEE_OS_INSTALL_STAGING = YES
OPTEE_OS_INSTALL_IMAGES = YES

$(eval $(generic-package))
