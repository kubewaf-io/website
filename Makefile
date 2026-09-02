# kubeWAF website (Hugo + Docsy) — Kubernetes-style layout
HUGO ?= hugo
NPM ?= npm
PUBLIC_DIR ?= public

.PHONY: deps serve build clean module-check

deps:
	$(NPM) ci

serve: deps
	$(HUGO) server --bind 0.0.0.0 --buildFuture --disableFastRender

build: deps
	$(HUGO) --gc --minify -d $(PUBLIC_DIR)

clean:
	rm -rf $(PUBLIC_DIR) resources/_gen .hugo_build.lock

module-check:
	$(HUGO) config | head -40
