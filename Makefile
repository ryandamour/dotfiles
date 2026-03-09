.PHONY: help install install-dry dotfiles test test-unit lint \
       packer-build packer-clean \
       vagrant-build vagrant-up vagrant-test vagrant-ssh vagrant-destroy \
       clean check

SHELL := /bin/bash
SCRIPTS := install $(wildcard lib/*.sh)
BATS_UNIT := $(filter-out test/integration.bats, $(wildcard test/*.bats))

PACKER_BOX := packer/output/silverblue-42.box
VAGRANT_IMAGE := localhost/vagrant-container:latest

# Mirrors the alias in .zshrc — podman-wrapped vagrant for Silverblue
VAGRANT := sudo podman run --rm \
  --volume /run/libvirt:/run/libvirt \
  --volume "$(HOME):$(HOME):rslave" \
  --env "HOME=$(HOME)" \
  --workdir "$(CURDIR)" \
  --net host \
  --privileged \
  --security-opt label=disable \
  --entrypoint /usr/bin/vagrant \
  $(VAGRANT_IMAGE)

help: ## Show all targets
	@grep -E '^[a-zA-Z_-]+:.*##' $(MAKEFILE_LIST) | \
	  awk 'BEGIN {FS = ":.*## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'

install: ## Run full bootstrap
	./install

install-dry: ## Dry-run bootstrap
	./install --dry-run

dotfiles: ## Sync dotfiles only
	@bash -c 'source lib/core.sh; source lib/dotfiles.sh; DOTFILES_SRC=./dotfiles DRY_RUN=false sync_dotfiles'

test: ## Run all BATS tests
	bats test/

test-unit: ## Unit tests only (excludes integration)
	bats $(BATS_UNIT)

lint: ## ShellCheck all scripts
	shellcheck -x $(SCRIPTS)

packer-build: ## Build Silverblue Vagrant box with Packer (~15-30 min)
	cd packer && packer init . && packer build -force .
	mkdir -p packer/output && mv packer/silverblue-42.box $(PACKER_BOX)

packer-clean: ## Remove Packer build artifacts
	rm -rf packer/output/ packer/packer_cache/

vagrant-build: ## Build the vagrant container image (sudo — shared with vagrant alias)
	sudo podman build -t $(VAGRANT_IMAGE) vagrant/

vagrant-up: ## Create/provision VM (builds container if needed)
	@test -f $(PACKER_BOX) || { echo "ERROR: $(PACKER_BOX) not found. Run 'make packer-build' first (15-30 min)."; exit 1; }
	@sudo podman image exists $(VAGRANT_IMAGE) 2>/dev/null || $(MAKE) vagrant-build
	$(VAGRANT) up

vagrant-test: ## Bring up VM + run full test suite
	@test -f $(PACKER_BOX) || { echo "ERROR: $(PACKER_BOX) not found. Run 'make packer-build' first (15-30 min)."; exit 1; }
	@sudo podman image exists $(VAGRANT_IMAGE) 2>/dev/null || $(MAKE) vagrant-build
	$(VAGRANT) up
	@echo "=== Reboot 1: activate base packages + RPM Fusion ==="
	$(VAGRANT) reload
	$(VAGRANT) ssh -c 'cd /home/vagrant/dotfiles && bash ./install --laptop --ohmyzsh --p10k || true'
	@echo "=== Reboot 2: activate ffmpeg override ==="
	$(VAGRANT) reload
	$(VAGRANT) ssh -c 'cd /home/vagrant/dotfiles && bash ./install --laptop --ohmyzsh --p10k'
	$(VAGRANT) ssh -c 'cd /home/vagrant/dotfiles && bats test/'

vagrant-ssh: ## SSH into the test VM
	@sudo podman image exists $(VAGRANT_IMAGE) 2>/dev/null || $(MAKE) vagrant-build
	sudo podman run --rm -it \
	  --volume /run/libvirt:/run/libvirt \
	  --volume "$(HOME):$(HOME):rslave" \
	  --env "HOME=$(HOME)" \
	  --workdir "$(CURDIR)" \
	  --net host \
	  --privileged \
	  --security-opt label=disable \
	  --entrypoint /usr/bin/vagrant \
	  $(VAGRANT_IMAGE) ssh

vagrant-destroy: ## Destroy VM
	@sudo podman image exists $(VAGRANT_IMAGE) 2>/dev/null || exit 0; \
	  $(VAGRANT) destroy -f

clean: ## Remove generated files and vagrant state
	-$(VAGRANT) destroy -f 2>/dev/null
	rm -rf .vagrant/
	rm -rf packer/output/
	rm -f test/*.tmp

check: lint test ## lint + test
