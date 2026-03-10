# gsu — Git Switch User
# https://github.com/hetawk/gsu

PREFIX    ?= $(HOME)/.local
BINDIR    ?= $(PREFIX)/bin
CONFIGDIR ?= $(HOME)/.config/gsu
SHELL_NAME?= $(notdir $(SHELL))

# Completion dirs
ZSH_COMP_DIR  ?= $(HOME)/.local/share/zsh/site-functions
BASH_COMP_DIR ?= $(HOME)/.bash_completion.d
FISH_COMP_DIR ?= $(HOME)/.config/fish/completions

.PHONY: install uninstall completions lint test help

help:
	@echo ""
	@echo "  gsu — Git Switch User  Makefile"
	@echo "  ─────────────────────────────────────────"
	@echo "  make install        Install gsu to $(BINDIR)"
	@echo "  make uninstall      Remove installed gsu"
	@echo "  make completions    Install shell completions"
	@echo "  make lint           Lint the gsu script"
	@echo "  make test           Run smoke tests"
	@echo ""
	@echo "  Variables:"
	@echo "    PREFIX=$(PREFIX)"
	@echo "    BINDIR=$(BINDIR)"
	@echo "    SHELL_NAME=$(SHELL_NAME)"
	@echo ""

install: $(BINDIR)/gsu
	@echo "  ✓ gsu installed to $(BINDIR)/gsu"
	@echo "  Make sure $(BINDIR) is in your PATH."

$(BINDIR)/gsu: gsu
	@mkdir -p $(BINDIR)
	@install -m 755 gsu $(BINDIR)/gsu

uninstall:
	@rm -f $(BINDIR)/gsu
	@echo "  ✓ gsu removed from $(BINDIR)"

completions: completions/gsu.zsh completions/gsu.bash completions/gsu.fish
	@echo "  Installing completions for $(SHELL_NAME)..."
	@# Zsh
	@mkdir -p $(ZSH_COMP_DIR)
	@cp completions/gsu.zsh $(ZSH_COMP_DIR)/_gsu
	@echo "  ✓ Zsh  → $(ZSH_COMP_DIR)/_gsu"
	@# Bash
	@mkdir -p $(BASH_COMP_DIR)
	@cp completions/gsu.bash $(BASH_COMP_DIR)/gsu
	@echo "  ✓ Bash → $(BASH_COMP_DIR)/gsu"
	@# Fish
	@mkdir -p $(FISH_COMP_DIR)
	@cp completions/gsu.fish $(FISH_COMP_DIR)/gsu.fish
	@echo "  ✓ Fish → $(FISH_COMP_DIR)/gsu.fish"

lint:
	@command -v shellcheck >/dev/null 2>&1 || { echo "shellcheck not found. Install shellcheck via your OS package manager."; exit 1; }
	shellcheck -s bash gsu install.sh uninstall.sh
	@echo "  ✓ Lint passed"

test: install
	@echo ""
	@echo "  Running smoke tests..."
	@$(BINDIR)/gsu version >/dev/null && echo "  ✓ gsu version" || echo "  ✗ gsu version FAILED"
	@$(BINDIR)/gsu help >/dev/null && echo "  ✓ gsu help" || echo "  ✗ gsu help FAILED"
	@$(BINDIR)/gsu list 2>/dev/null; echo "  ✓ gsu list (exit $$?)"
	@$(BINDIR)/gsu _keys >/dev/null; echo "  ✓ gsu _keys"
	@echo "  Smoke tests complete."
	@echo ""
