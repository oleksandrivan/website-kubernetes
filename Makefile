.PHONY: run_website

run_website:
	docker build -t website . && \
	docker run --rm --name website -p 8080:80 -d website

.PHONY: teardown_website

stop_website:
	docker stop website

.PHONY: run_registry

run_registry:
	docker run --name local-registry -d --restart=always -p 5000:5000 registry:2

.PHONY: start_cluster

start_cluster:
	kind create cluster --name website-cluster --config ./kind_config.yaml

.PHONY: delete_cluster

delete_cluster:
	kind delete clusters website-cluster && docker stop local-registry && docker rm local-registry

.PHONY: connect_registry_network

connect_registry_network: run_registry
	docker network connect kind local-registry || true

.PHONY: connect_registry

connect_registry: connect_registry_network
	kubectl apply -f ./kind_configmap.yaml

.PHONY: start_cluster_with_registry

start_cluster_with_registry:
	$(MAKE) start_cluster && $(MAKE) connect_registry

.PHONY: push_image

push_image: 
	docker tag website 127.0.0.1:5000/website 
	docker push 127.0.0.1:5000/website

.PHONY: helm_install

helm_install:
	helm upgrade --atomic --install explore-california-website ./chart