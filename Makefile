.PHONY: run api stop build-apk build-linux build-all

run:
	@./alworki.sh

api:
	@./scripts/start_backend.sh

stop:
	@./scripts/stop_backend.sh

build-apk:
	flutter build apk --release

build-linux:
	flutter build linux --release

build-all: build-apk build-linux
