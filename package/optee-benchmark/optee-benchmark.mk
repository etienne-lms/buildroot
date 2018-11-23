################################################################################
#
# optee-benchmarch
#
################################################################################

OPTEE_BENCHMARK_VERSION = $(call qstrip,$(BR2_PACKAGE_OPTEE_BENCHMARK_VERSION))
OPTEE_BENCHMARK_LICENSE = BSD-2-Clause

OPTEE_BENCHMARK_DEPENDENCIES = optee-client libyaml

ifeq ($(BR2_PACKAGE_OPTEE_BENCHMARK_LATEST),y)
OPTEE_BENCHMARK_SITE = $(call github,linaro-swg,optee_benchmark,$(OPTEE_BENCHMARK_VERSION))
endif

ifeq ($(BR2_PACKAGE_OPTEE_BENCHMARK_CUSTOM_GIT),y)
OPTEE_BENCHMARK_SITE = $(call qstrip,$(BR2_PACKAGE_OPTEE_BENCHMARK_CUSTOM_REPO_URL))
OPTEE_BENCHMARK_SITE_METHOD = git
BR_NO_CHECK_HASH_FOR += $(OPTEE_BENCHMARK_SOURCE)
endif

$(eval $(cmake-package))
