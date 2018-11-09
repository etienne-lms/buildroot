OPTEE_OS_VERSION = $(call qstrip,$(BR2_TARGET_OPTEE_OS_VERSION))
OPTEE_OS_LICENSE = BSD-2-Clause
OPTEE_OS_LICENSE_FILES = LICENSE

ifeq ($(BR2_TARGET_OPTEE_OS_GIT),y)
OPTEE_OS_SITE = $(call qstrip,$(BR2_TARGET_OPTEE_OS_SITE))
OPTEE_OS_SITE_METHOD = git
BR_NO_CHECK_HASH_FOR += $(OPTEE_OS_SOURCE)
else ifeq ($(BR2_TARGET_OPTEE_OS_LOCAL),y)
OPTEE_OS_SITE = $(call qstrip,$(BR2_TARGET_OPTEE_OS_SITE))
OPTEE_OS_SITE_METHOD = local
OPTEE_OS_SOURCE = local
else
OPTEE_OS_SITE = $(call github,OP-TEE,optee_os,master)
endif

# OP-TEE OS needs a cross compiler for 32bit and/or 64bit tatrgets
# Buildroot currently references only 1 cross compiler.
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

ifeq ($(BR2_aarch64),y)
OPTEE_OS_LOCAL_SDK = out-br/export-ta_arm64
endif
ifeq ($(BR2_arm),y)
OPTEE_OS_LOCAL_SDK = out-br/export-ta_arm32
endif

# FIXME: this does not allows to build the SKS TA using an external TA devkit.

define OPTEE_OS_BUILD_CMDS
	@echo "Build devkit: $(BR2_TARGET_OPTEE_OS_SDK)"
	@echo "Build core: $(BR2_TARGET_OPTEE_OS_BUILD)"
	@echo "Build services: $(BR2_TARGET_OPTEE_OS_SERVICES)"
	@test "$(BR2_TARGET_OPTEE_OS_SDK)" != y || \
		$(TARGET_CONFIGURE_OPTS) \
			$(MAKE) -C $(@D) O=out-br $(OPTEE_OS_MAKE_OPTS) ta_dev_kit
	@test "$(BR2_TARGET_OPTEE_OS_BUILD)" != y || \
		$(TARGET_CONFIGURE_OPTS) \
			$(MAKE) -C $(@D) O=out-br $(OPTEE_OS_MAKE_OPTS) all
	@test "$(BR2_TARGET_OPTEE_OS_SERVICES)" != y || { \
		$(foreach f,$(wildcard $(@D)/ta_services/*/Makefile), \
		$(TARGET_CONFIGURE_OPTS) \
			$(MAKE) CROSS_COMPILE=$(TARGET_CROSS) \
				O=out-br TA_DEV_KIT_DIR=$(@D)/$(OPTEE_OS_LOCAL_SDK) \
				-C $(dir $f) &&) true; }
endef

# Installs OP-TEE TA devkit in $(STAGING_DIR)/lib/optee.
# May installs OP-TEE core images in $(BINARIES_DIR).
# May installs OP-TEE TA services in $(TARGET_DIR)/lib/optee_armtz
define OPTEE_OS_INSTALL_IMAGES_CMDS
	@echo "Install devkit: $(BR2_TARGET_OPTEE_OS_SDK)"
	@echo "Install core: $(BR2_TARGET_OPTEE_OS_BUILD)"
	@echo "Install services: $(BR2_TARGET_OPTEE_OS_SERVICES)"
	@test "$(BR2_TARGET_OPTEE_OS_SDK)" != y || { \
		mkdir -p $(STAGING_DIR)/lib/optee && \
		cp -ardpf $(@D)/$(OPTEE_OS_LOCAL_SDK) $(STAGING_DIR)/lib/optee; }
	@test "$(BR2_TARGET_OPTEE_OS_BUILD)" != y || { \
		mkdir -p $(BINARIES_DIR) && \
		cp -dpf $(@D)/out-br/core/tee-*_v2.bin $(BINARIES_DIR); }
	@test "$(BR2_TARGET_OPTEE_OS_SERVICES)" != y || { \
		mkdir -p $(TARGET_DIR)/lib/optee_armtz && \
		$(foreach f,$(wildcard $(@D)/ta_services/*/out-br/*.ta), \
			$(INSTALL) -v -p  --mode=444 \
				--target-directory=$(TARGET_DIR)/lib/optee_armtz \
				 $f &&) true; }
endef

OPTEE_OS_INSTALL_STAGING = YES
OPTEE_OS_INSTALL_IMAGES = YES

$(eval $(generic-package))
