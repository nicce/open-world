GODOT        ?= godot4
GUT_VERSION  := 9.3.0
GUT_DIR      := addons/gut
GD_FILES     := $(shell find scripts scenes components -name "*.gd" 2>/dev/null)

.PHONY: lint format format-check test install-gut help

help:
	@echo "Targets:"
	@echo "  lint          Run gdlint on all GDScript files"
	@echo "  format        Auto-format all GDScript files with gdformat"
	@echo "  format-check  Check formatting without modifying files"
	@echo "  install-gut   Download and install GUT test framework"
	@echo "  test          Run unit tests via GUT (runs install-gut if needed)"

lint:
	gdlint $(GD_FILES)

format:
	gdformat $(GD_FILES)

format-check:
	gdformat --check $(GD_FILES)

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

test: install-gut
	$(GODOT) --headless \
		-s addons/gut/gut_cmdln.gd \
		-gdir=res://tests \
		-gexit \
		-glog=1 \
		-gjunit_xml_file=test_results.xml
