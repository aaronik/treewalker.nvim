MINIMAL_INIT=tests/minimal_init.lua
TESTS_DIR=tests
NO_UTIL_SPEC=checks

.PHONY: test

test: ## Run the whole test suite
	@nvim \
		--headless \
		--noplugin \
		-u ${MINIMAL_INIT} \
		-c "PlenaryBustedDirectory ${TESTS_DIR} { timeout = 1000, sequential = true, keep_going = false, minimal_init = '${MINIMAL_INIT}' }"

test-watch: ## Watching for changes to lua files
	@nodemon -e lua -x "$(MAKE) test || exit 1"

check: ## Run luacheck on the project
	@luacheck . --globals vim it describe before_each after_each --exclude-files tests/fixtures --max-comment-line-length 140

no-utils: ## Make sure there are no errant utils hanging around
	@nvim \
		--headless \
		--noplugin \
		-u ${MINIMAL_INIT} \
		-c "PlenaryBustedDirectory ${NO_UTIL_SPEC} { minimal_init = '${MINIMAL_INIT}' }"

pass: test no-utils check ## Run everything, if it's a 0 code, everything's good

help: ## Displays this information.
	@printf '%s\n' "Usage: make <command>"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-30s\033[0m %s\n", $$1, $$2}'
	@printf '\n'

