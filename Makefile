export PROJECT ?= $(shell basename $(shell pwd))
TRONADOR_AUTO_INIT := true

GITVERSION ?= $(INSTALL_PATH)/gitversion
GH ?= $(INSTALL_PATH)/gh
YQ ?= $(INSTALL_PATH)/yq

-include $(shell curl -sSL -o .tronador "https://cowk.io/acc"; echo .tronador)

## Xcode Version Bump and creates VERSION File - Uses always the FullSemVer from GitVersion (no need to prepend the 'v').
version: packages/install/gitversion packages/install/yq
	$(call assert-set,GITVERSION)
	$(call assert-set,YQ)
ifeq ($(GIT_IS_TAG),1)
	@echo "$(GIT_TAG)" | sed -e 's/^v\([0-9]\{1,\}\.[0-9]\{1,\}\.[0-9]\{1,\}\(-[a-zA-Z0-9.]\{1,\}\)*\)\(+deploy-.*\)\?$$/\1/' > VERSION
	@$(YQ) e -i e '.version = "$(shell echo "$(GIT_TAG)" | sed 's/^v//')"' pubspec.yaml
else
	# Translates + in version to - for helm/docker compatibility
	@echo "$(shell $(GITVERSION) -output json -showvariable FullSemVer | tr '+' '-')" > VERSION
	@$(YQ) e -i e '.version = "$(shell $(GITVERSION) -output json -showvariable FullSemVer | tr '+' '-')"' pubspec.yaml
endif

# Modify package.json to change the project name with the $(PROJECT) variable
## Code Initialization for Node Project
code/init: packages/install/gitversion packages/install/gh packages/install/yq
	$(call assert-set,GITVERSION)
	$(call assert-set,GH)
	$(call assert-set,YQ)
	$(eval $@_OWNER := $(shell $(GH) repo view --json 'name,owner' -q '.owner.login'))
	@$(YQ) e -i '.name = "$(PROJECT)"' pubspec.yaml
	@$(YQ) e -i e '.version = "$(shell $(GITVERSION) -output json -showvariable FullSemVer | tr '+' '-')"' pubspec.yaml
