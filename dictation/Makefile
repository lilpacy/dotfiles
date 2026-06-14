.PHONY: lint test

lint:
	bash -n ../bin/local-dictation bin/local-dictation scripts/*.sh
	shellcheck ../bin/local-dictation bin/local-dictation scripts/*.sh test/*.bats
	jq empty ../.config/karabiner/karabiner.json karabiner.json.example
	luac -p ../.hammerspoon/init.lua ../.hammerspoon/modules/dictation.lua hammerspoon.lua.example

test:
	bats test
