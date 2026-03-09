GODOT_VERSION  ?= 4.2.2
GUT_VERSION    := 9.3.0
GUT_DIR        := addons/gut
GD_FILES       := $(shell find scripts scenes components -name "*.gd" 2>/dev/null)

BIN_DIR        := bin
GODOT_BIN      := $(BIN_DIR)/godot4
GDTOOLKIT_VENV := $(BIN_DIR)/venv
GDLINT         := $(GDTOOLKIT_VENV)/bin/gdlint
GDFORMAT       := $(GDTOOLKIT_VENV)/bin/gdformat

UNAME_S := $(shell uname -s)
ifeq ($(UNAME_S),Darwin)
    GODOT_ZIP        := Godot_v$(GODOT_VERSION)-stable_macos.universal.zip
    GODOT_BIN_IN_ZIP := Godot.app/Contents/MacOS/Godot
else
    GODOT_ZIP        := Godot_v$(GODOT_VERSION)-stable_linux.x86_64.zip
    GODOT_BIN_IN_ZIP := Godot_v$(GODOT_VERSION)-stable_linux.x86_64
endif

GODOT_URL     := https://github.com/godotengine/godot/releases/download/$(GODOT_VERSION)-stable/$(GODOT_ZIP)
GODOT_APP_BIN := /Applications/Godot.app/Contents/MacOS/Godot

.PHONY: lint format format-check test install-gut install-godot install-gdtoolkit help

help:
	@echo "Targets:"
	@echo "  lint              Run gdlint on all GDScript files"
	@echo "  format            Auto-format all GDScript files with gdformat"
	@echo "  format-check      Check formatting without modifying files"
	@echo "  install-gut       Download and install GUT test framework"
	@echo "  install-godot     Download Godot $(GODOT_VERSION) to $(BIN_DIR)/"
	@echo "  install-gdtoolkit Install gdtoolkit (gdlint/gdformat) to $(BIN_DIR)/venv/"
	@echo "  test              Run unit tests via GUT (auto-installs dependencies)"

$(GODOT_BIN):
	@mkdir -p $(BIN_DIR)
	@if [ "$(UNAME_S)" = "Darwin" ] && [ -f "$(GODOT_APP_BIN)" ]; then \
		echo "Found Godot at $(GODOT_APP_BIN), symlinking to $(GODOT_BIN)..."; \
		ln -sf "$(GODOT_APP_BIN)" $(GODOT_BIN); \
	else \
		echo "Downloading Godot $(GODOT_VERSION) for $(UNAME_S)..."; \
		curl -fsSL "$(GODOT_URL)" -o /tmp/godot.zip; \
		unzip -q /tmp/godot.zip -d /tmp/godot_extract; \
		cp "/tmp/godot_extract/$(GODOT_BIN_IN_ZIP)" $(GODOT_BIN); \
		chmod +x $(GODOT_BIN); \
		rm -rf /tmp/godot.zip /tmp/godot_extract; \
	fi
	@echo "Godot ready at $(GODOT_BIN)"

install-godot: $(GODOT_BIN)

$(GDLINT):
	@echo "Installing gdtoolkit into $(GDTOOLKIT_VENV)..."
	@mkdir -p $(BIN_DIR)
	@python3 -m venv $(GDTOOLKIT_VENV)
	@$(GDTOOLKIT_VENV)/bin/pip install -q "gdtoolkit==4.*"
	@echo "gdtoolkit installed at $(GDTOOLKIT_VENV)"

install-gdtoolkit: $(GDLINT)

lint: $(GDLINT)
	$(GDLINT) $(GD_FILES)

format: $(GDLINT)
	$(GDFORMAT) $(GD_FILES)

format-check: $(GDLINT)
	$(GDFORMAT) --check $(GD_FILES)

install-gut:
	@if [ ! -d "$(GUT_DIR)" ]; then \
		echo "Installing GUT $(GUT_VERSION)..."; \
		mkdir -p addons; \
		curl -fsSL "https://github.com/bitwes/Gut/archive/refs/tags/v$(GUT_VERSION).zip" -o /tmp/gut.zip; \
		unzip -q /tmp/gut.zip -d /tmp/gut_extract; \
		cp -r /tmp/gut_extract/Gut-$(GUT_VERSION)/addons/gut addons/; \
		rm -rf /tmp/gut.zip /tmp/gut_extract; \
		echo "GUT installed at $(GUT_DIR)"; \
	else \
		echo "GUT already installed at $(GUT_DIR)"; \
	fi

test: install-gut $(GODOT_BIN)
	$(GODOT_BIN) --headless --import || true
	$(GODOT_BIN) --headless \
		-s addons/gut/gut_cmdln.gd \
		-gdir=res://tests \
		-ginclude_subdirs \
		-gexit \
		-glog=1 \
		-gjunit_xml_file=test_results.xml
