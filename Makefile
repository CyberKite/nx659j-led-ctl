MODULE = $(shell sed -n 's/^id=//p' src/module.prop)
MODULE_VER = $(shell sed -n 's/^versionCode=//p' src/module.prop)
OUT = out
ZIP = $(OUT)/$(MODULE)_$(MODULE_VER).zip

ANDROID_NDK_HOME = $(HOME)/Android/Sdk/ndk/30.0.16248370
NDK_BIN = $(ANDROID_NDK_HOME)/toolchains/llvm/prebuilt/linux-x86_64/bin
NDK_CC = $(NDK_BIN)/aarch64-linux-android26-clang

UPDATE_PATH = build/META-INF/com/google/android

SRC_FILES = $(shell find src -type f)
BUILD_FILES = $(patsubst src/%,build/%,$(filter-out %.c,$(SRC_FILES))) \
	$(patsubst src/%.c,build/%,$(filter %.c,$(SRC_FILES))) \
	$(UPDATE_PATH)/update-binary \
	$(UPDATE_PATH)/updater-script \
	build/tinymix

ROOT_MANAGER = magisk

.PHONY: all clean build install-magisk install-apatch install

all: $(ZIP)

clean:
	rm -rf '$(OUT)' build

mrproper: clean
	$(MAKE) -C vendor/tinyalsa clean

ifeq ($(ROOT_MANAGER),apatch)
install: install-apatch
else
install: install-magisk
endif

install-magisk: $(ZIP)
	adb push $(ZIP) /sdcard/$(MODULE).zip
	adb shell su -c 'magisk --install-module /sdcard/$(MODULE).zip'

install-apatch: $(ZIP)
	adb push $(ZIP) /sdcard/$(MODULE).zip
	@adb shell su -c '/data/adb/apd module uninstall $(MODULE)'
	adb shell su -c '/data/adb/apd module install /sdcard/$(MODULE).zip'

$(ZIP): $(BUILD_FILES)
	mkdir -p $(OUT)
	rm -f '$@'
	cd build && zip -X '../$@' $(patsubst build/%,%,$(BUILD_FILES))

build/%.prop: src/%.prop
	mkdir -p '$(dir $@)'
	cp '$<' '$@'

build/%.sh: src/%.sh
	mkdir -p '$(dir $@)'
	cp '$<' '$@'
	chmod +x '$@'

build/%.default: src/%.default
	mkdir -p '$(dir $@)'
	cp '$<' '$@'

build/%: src/%.c
	mkdir -p '$(dir $@)'
	$(NDK_CC) $(CFLAGS) $(LDFLAGS) -o '$@' '$<'

$(UPDATE_PATH)/updater-script:
	mkdir -p '$(dir $@)'
	echo "#MAGISK" > '$@'

$(UPDATE_PATH)/update-binary:
	mkdir -p '$(dir $@)'
	wget -qO '$@' https://github.com/topjohnwu/Magisk/raw/refs/heads/master/scripts/module_installer.sh

build/tinymix: vendor/tinyalsa
	mkdir -p '$(dir $@)'
	$(MAKE) -C vendor/tinyalsa/src libtinyalsa.a \
		CC='$(NDK_CC)' AR='$(NDK_BIN)/llvm-ar'
	$(MAKE) -C vendor/tinyalsa/utils tinymix \
		CC='$(NDK_CC)' LD='$(NDK_CC)'
	cp vendor/tinyalsa/utils/tinymix '$@'
