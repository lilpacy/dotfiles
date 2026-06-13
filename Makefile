.PHONY: lint test

lint:
	bash -n bin/local-dictation dictation/*.sh
	shellcheck bin/local-dictation dictation/*.sh test/*.bats
	jq empty .config/karabiner/karabiner.json dictation/karabiner.json.example
	luac -p .hammerspoon/init.lua dictation/hammerspoon.lua.example

test:
	bats test
