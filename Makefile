# Version number
VERSION=$(shell ./tools/image-tag | cut -d, -f 1)

GIT_REVISION := $(shell git rev-parse --short HEAD)
GIT_BRANCH := $(shell git rev-parse --abbrev-ref HEAD)

GOOS ?= $(shell go env GOOS)
GOARCH ?= $(shell go env GOARCH)

GOPATH := $(shell go env GOPATH)

GO_OPT= -mod vendor -ldflags "-X main.Branch=$(GIT_BRANCH) -X main.Revision=$(GIT_REVISION) -X main.Version=$(VERSION)"

### Development

.PHONY: run
run:
	go run ./cmd/prometheus-plex-exporter

### Build

.PHONY: prometheus-plex-exporter
prometheus-plex-exporter:
	CGO_ENABLED=0 go build $(GO_OPT) -o ./bin/$(GOOS)/prometheus-plex-exporter ./cmd/prometheus-plex-exporter

.PHONY: exe
exe:
	GOOS=linux $(MAKE) $(COMPONENT)

### Docker Images

.PHONY: docker-component # Not intended to be used directly
docker-component: check-component exe
	docker buildx build -t masterevarior/$(COMPONENT) --build-arg=TARGETARCH=$(GOARCH) --platform $(GOOS)/$(GOARCH) -f ./cmd/$(COMPONENT)/Dockerfile .
	docker tag masterevarior/$(COMPONENT) $(COMPONENT)
	docker tag masterevarior/$(COMPONENT) ghcr.io/masterevarior/$(COMPONENT)

.PHONY: docker-prometheus-plex-exporter
docker-prometheus-plex-exporter:
	COMPONENT=prometheus-plex-exporter $(MAKE) docker-component

.PHONY: docker-images
docker-images: docker-prometheus-plex-exporter

.PHONY: check-component
check-component:
ifndef COMPONENT
	$(error COMPONENT variable was not defined)
endif
