PREFIX ?= /Applications

.PHONY: build test bundle package install clean

build:
	swift build

test:
	swift test

bundle:
	./scripts/bundle.sh

package:
	./scripts/package.sh $(VERSION)

install: bundle
	rm -rf "$(PREFIX)/rookbar.app"
	cp -R build/rookbar.app "$(PREFIX)/rookbar.app"

clean:
	rm -rf .build build
