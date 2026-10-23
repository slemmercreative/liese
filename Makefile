# Liese — common tasks. Run `make` for the list.
APP      := Liese
PROJECT  := $(APP).xcodeproj
DERIVED  := build/DerivedData
FILE     ?= Samples/bounce.json

.DEFAULT_GOAL := help
.PHONY: help install project open build run preview doctor hooks unhooks version uninstall clean

help: ## List tasks
	@grep -E '^[a-zA-Z_-]+:.*## ' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*## "}; {printf "  \033[36m%-10s\033[0m %s\n", $$1, $$2}'

install: ## Build Release → /Applications/Liese.app and refresh Quick Look
	@bash scripts/install.sh

project: ## Generate Liese.xcodeproj from project.yml
	@xcodegen generate --quiet

open: project ## Generate the project and open it in Xcode
	@open $(PROJECT)

build: project ## Debug build only (nothing installed)
	@xcodebuild -project $(PROJECT) -scheme $(APP) -configuration Debug \
		-derivedDataPath $(DERIVED) -destination 'generic/platform=macOS' -quiet build

run: build ## Debug build, then launch it from build/
	@open $(DERIVED)/Build/Products/Debug/$(APP).app

preview: ## Quick Look a file: make preview FILE=path/to/anim.json
	@qlmanage -p "$(FILE)" >/dev/null 2>&1

doctor: ## Show installed build + Quick Look registration
	@bash scripts/doctor.sh

hooks: ## Auto-install after every commit (post-commit hook)
	@chmod +x .githooks/*
	@git config core.hooksPath .githooks
	@echo "Post-commit auto-install enabled. Disable with: make unhooks"

unhooks: ## Turn off auto-install after commits
	@git config --unset core.hooksPath || true
	@echo "Post-commit auto-install disabled."

version: ## Set the marketing version: make version V=0.2.0
	@test -n "$(V)" || { echo "usage: make version V=x.y.z"; exit 1; }
	@sed -i '' -E 's/^MARKETING_VERSION = .*/MARKETING_VERSION = $(V)/' Config/Liese.xcconfig
	@echo "MARKETING_VERSION = $(V)"

uninstall: ## Remove the installed app and its Quick Look extension
	@bash scripts/uninstall.sh

clean: ## Delete build output and the generated project
	@rm -rf build $(PROJECT)
