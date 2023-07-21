RELEASE_VERSION ?=$(shell grep version colo/charts/farsight-collector-colo/Chart.yaml | awk '{print $$2}')

IMAGE_NAME_COLO ?= farsight.collector.colo
IMAGE_REGISTRY  ?= infoblox

.PHONY: docker
docker:
	docker build -t $(IMAGE_REGISTRY)/$(IMAGE_NAME_COLO):$(RELEASE_VERSION) -t $(IMAGE_NAME_COLO):$(RELEASE_VERSION) -f ./colo/docker/Dockerfile .

# Jenkins will sign and push images -- manual image pushing process is no longer required.
# Left for reference.
# .PHONY: push-docker
# push-docker:
# 	docker tag $(IMAGE_NAME_COLO):$(RELEASE_VERSION) infobloxopen/$(IMAGE_NAME_COLO):$(RELEASE_VERSION)
# 	docker push infobloxopen/$(IMAGE_NAME_COLO):$(RELEASE_VERSION)

.PHONY: chart
chart:
	sed -i '' "s/tag: .*/tag: ${RELEASE_VERSION}/g" colo/charts/farsight-collector-colo/values.yaml

	helm package colo/charts/farsight-collector-colo -d colo/charts/
	helm repo index colo/charts/

.PHONY: clean
clean:
	@docker rmi -f $(shell docker images -q $(IMAGE_NAME_COLO)) || true

.PHONY: list-of-images
list-of-images:
	@echo $(IMAGE_REGISTRY)/$(IMAGE_NAME_COLO):$(RELEASE_VERSION)
