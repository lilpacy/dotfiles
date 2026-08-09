.PHONY: install brew runtimes link lint test

# 新マシン bootstrap の唯一の入口
install: brew runtimes link

brew:
	brew bundle --file=Brewfile

runtimes:
	cut -d' ' -f1 .tool-versions | xargs -n1 asdf plugin add || true
	asdf install
	aqua i

link:
	./link.sh

lint:
	shellcheck --severity=error \
		link.sh link-skills.sh common.sh .bashrc \
		githooks/pre-commit claude/hooks/auto-commit.sh
	git grep -lE '^#!/(usr/)?bin/(env )?(bash|sh)\b' -- bin \
		| xargs shellcheck --severity=error
	$(MAKE) -C dictation lint

test:
	$(MAKE) -C dictation test
