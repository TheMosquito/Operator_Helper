


help:
	@echo " "
	@echo " "
	@echo "For Open Horizon, edit the \"horizon/my_hzn_env\" file, save it, \"source\" it"
	@echo "then edit the \"my_env\" file, save it, \"source\" it, then"
	@echo "\"docker login\", and login to your cluster (e.g., \"oc login ...\")."
	@echo "After those prerequisites are complete, run \"make init\" for the next steps..."

init:
	operator-sdk new $(MY_OPERATOR_NAME) --type=ansible --api-version=$(MY_API_VERSION) --kind=$(MY_RESOURCE_KIND)
	@echo " "
	@echo " "
	@echo "Operator template has been created in \"$(MY_OPERATOR_NAME)\"."
	@echo "You may now *optionally* add/change/remove files/dirs in the \"src\" directory."
	@echo "When ready, \"make build\" for the next steps..."

build:
	find src -type f | xargs ./sub $(MY_OPERATOR_NAME)
	cd $(MY_OPERATOR_NAME); operator-sdk build docker.io/$(MY_DOCKER_HUB_ID)/$(MY_OPERATOR_NAME)_$(ARCH):$(MY_OPERATOR_VERSION)
	docker push docker.io/$(MY_DOCKER_HUB_ID)/$(MY_OPERATOR_NAME)_$(ARCH):$(MY_OPERATOR_VERSION)
	sed -i "" -e "s|REPLACE_IMAGE|$(MY_DOCKER_HUB_ID)/$(MY_OPERATOR_NAME)_$(ARCH):$(MY_OPERATOR_VERSION)|" "$(MY_OPERATOR_NAME)/deploy/operator.yaml"
	cat src/role_append >> "$(MY_OPERATOR_NAME)/deploy/role.yaml"
	@echo " "
	@echo " "
	@echo "Your operator has been built and pushed to DockerHub. Now you can \"make test\"."

test:
	kubectl apply -f $(MY_OPERATOR_NAME)/deploy/crds/*_crd.yaml
	kubectl apply -f $(MY_OPERATOR_NAME)/deploy/service_account.yaml
	kubectl apply -f $(MY_OPERATOR_NAME)/deploy/role.yaml
	kubectl apply -f $(MY_OPERATOR_NAME)/deploy/role_binding.yaml
	kubectl apply -f $(MY_OPERATOR_NAME)/deploy/operator.yaml
	kubectl apply -f $(MY_OPERATOR_NAME)/deploy/crds/*_cr.yaml
	@echo " "
	@echo " "
	@echo "Your operator pod should now start running. Run \"make stop\" to stop it.."
	@echo "If you wish to publish it with Open Horiizon, run \"make service\"."

stop:
	-kubectl delete route $(MY_ROUTE_NAME)
	-kubectl delete service $(MY_OPERATOR_NAME)-metrics
	-kubectl delete crd $(word 2, $(shell /bin/sh -c "grep 'name:' $(MY_OPERATOR_NAME)/deploy/crds/*_crd.yaml"))
	-kubectl delete deployment $(MY_OPERATOR_NAME)
	-kubectl delete rolebinding $(MY_OPERATOR_NAME)
	-kubectl delete role $(MY_OPERATOR_NAME)
	-kubectl delete serviceaccount $(MY_OPERATOR_NAME)
	@echo " "
	@echo " "
	@echo "Your operator pod is terminated (or is terminating)."

service: stop
	tar -zcvf operator.tar.gz $(MY_OPERATOR_NAME)/deploy/*
	hzn exchange service publish -f horizon/service.json
	@echo " "
	@echo " "
	@echo "Your Open Horizon service is published."
	@echo "If you wish to publish a pattern for this service, run \"make pattern\"."

pattern:
	hzn exchange pattern publish -f horizon/pattern.json
	@echo " "
	@echo " "
	@echo "Your Open Horizon pattern is published."
	@echo "You may now register nodes with \"make register\""

register:
	kubectl -n openhorizon-agent exec -i `kubectl -n openhorizon-agent get pods --selector=app=agent -o jsonpath={.items[*].metadata.name}` -- hzn register -u $(HZN_EXCHANGE_USER_AUTH) -n $(HZN_EXCHANGE_NODE_AUTH) --pattern "$(HZN_ORG_ID)/pattern-$(SERVICE_NAME)-$(ARCH)"
	@echo " "
	@echo " "
	@echo "Your Open Horizon pattern is now registered."
	@echo "You may unregister with \"make unregister\""

unregister:
	kubectl -n openhorizon-agent exec -i `kubectl -n openhorizon-agent get pods --selector=app=agent -o jsonpath={.items[*].metadata.name}` -- hzn unregister -f

clean: stop
	-rm -rf $(MY_OPERATOR_NAME)
	-rm -f ./operator.tar.gz

