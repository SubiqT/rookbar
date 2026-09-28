PREFIX ?= /Applications

.PHONY: build test bundle install clean

build:
	swift build

test:
	swift test

bundle:
	./scripts/bundle.sh

install: bundle
	rm -rf "$(PREFIX)/rookbar.app"
	cp -R build/rookbar.app "$(PREFIX)/rookbar.app"

clean:
	rm -rf .build build
