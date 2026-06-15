.PHONY: lint test

lint:
	bash -n ../bin/local-dictation ../bin/select-mic bin/local-dictation scripts/*.sh
	shellcheck ../bin/local-dictation ../bin/select-mic bin/local-dictation scripts/*.sh test/*.bats
	jq empty ../.config/karabiner/karabiner.json
	luac -p ../.hammerspoon/init.lua ../.hammerspoon/modules/dictation.lua

test:
	bats test
