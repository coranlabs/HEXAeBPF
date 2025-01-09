# Copyright 2018-present Open Networking Foundation
#
# SPDX-License-Identifier: Apache-2.0

SHELL		:= /bin/bash
MAKEDIR		:= $(dir $(realpath $(firstword $(MAKEFILE_LIST))))
BUILD		?= $(MAKEDIR)/build
M           	?= $(BUILD)/milestones
SCRIPTDIR	:= $(MAKEDIR)/scripts
RESOURCEDIR	:= $(MAKEDIR)/resources
WORKSPACE	?= $(HOME)
VENV		?= $(BUILD)/venv/aiab

NS?=hexa
HELM_ARGS?=--create-namespace
HELM_ACTION?=install

4G_CORE_VALUES       ?= $(MAKEDIR)/sd-core-4g-values.yaml
5G_CORE_VALUES       ?= $(MAKEDIR)/sd-core-5g-values.yaml
5G_UPF_VALUES        ?= $(MAKEDIR)/upf-5g-values.yaml
OAISIM_VALUES        ?= $(MAKEDIR)/oaisim-values.yaml
ROC_VALUES           ?= $(MAKEDIR)/roc-values.yaml
ROC_DEFAULTENT_MODEL ?= $(MAKEDIR)/roc-defaultent-model.json
ROC_4G_MODELS        ?= $(MAKEDIR)/roc-4g-models.json
ROC_5G_MODELS        ?= $(MAKEDIR)/roc-5g-models.json
TEST_APP_VALUES      ?= $(MAKEDIR)/5g-test-apps-values.yaml
UPF_COUNT             = $(MAKEDIR)/upf-count.txt
GET_HELM              = get_helm.sh

KUBESPRAY_VERSION ?= release-2.17
DOCKER_VERSION    ?= '20.10'
HELM_VERSION	  ?= v3.10.3
KUBECTL_VERSION   ?= v1.23.15

RKE2_K8S_VERSION  ?= v1.25.15+rke2r2
K8S_VERSION       ?= v1.25.6
LPP_VERSION       ?= v0.0.24

OAISIM_UE_IMAGE ?= andybavier/lte-uesoftmodem:1.1.0-$(shell uname -r)
ENABLE_ROUTER ?= true
ENABLE_OAISIM ?= true
ENABLE_GNBSIM ?= false
ENABLE_SUBSCRIBER_PROXY ?= false
GNBSIM_COLORS ?= true

K8S_INSTALL ?= rke2
CTR_CMD     := sudo /var/lib/rancher/rke2/bin/ctr --address /run/k3s/containerd/containerd.sock --namespace k8s.io

PROXY_ENABLED   ?= false
HTTP_PROXY      ?= ${http_proxy}
HTTPS_PROXY     ?= ${https_proxy}
NO_PROXY        ?= ${no_proxy}

ONECLOUD	?= false

DATA_IFACE ?= data
ifeq ($(DATA_IFACE), data)
	RAN_SUBNET := 192.168.251.0/24
else
	RAN_SUBNET := $(shell ip route | grep $${DATA_IFACE} | awk '/kernel/ {print $$1}' | head -1)
	DATA_IFACE_PATH := $(shell find /*/systemd/network -maxdepth 1 -not -type d -name '*$(DATA_IFACE).network' -print)
	DATA_IFACE_CONF ?= $(shell basename $(DATA_IFACE_PATH)).d
endif

# systemd-networkd and systemd configs
LO_NETCONF            := /etc/systemd/network/20-aiab-lo.network
OAISIM_NETCONF        := $(LO_NETCONF) /etc/systemd/network/10-aiab-enb.netdev /etc/systemd/network/20-aiab-enb.network
ROUTER_POD_NETCONF    := /etc/systemd/network/10-aiab-dummy.netdev /etc/systemd/network/20-aiab-dummy.network
ROUTER_HOST_NETCONF   := /etc/systemd/network/10-aiab-access.netdev /etc/systemd/network/20-aiab-access.network /etc/systemd/network/10-aiab-core.netdev /etc/systemd/network/20-aiab-core.network /etc/systemd/network/$(DATA_IFACE_CONF)/macvlan.conf
UE_NAT_CONF           := /etc/systemd/system/aiab-ue-nat.service

# monitoring
RANCHER_MONITORING_CRD_CHART := rancher/rancher-monitoring-crd
RANCHER_MONITORING_CHART     := rancher/rancher-monitoring
MONITORING_VALUES            ?= $(MAKEDIR)/monitoring.yaml

NODE_IP ?= $(shell ip route get 8.8.8.8 | grep -oP 'src \K\S+')
ifndef NODE_IP
$(error NODE_IP is not set)
endif

MME_IP  ?=

HELM_GLOBAL_ARGS ?=

ifneq ("$(wildcard $(UPF_COUNT))","")
  UPF_NUMBER = $(shell cat $(UPF_COUNT))
else
  UPF_NUMBER = 0
endif

# Allow installing local charts or specific versions of published charts.
# E.g., to install the Aether 1.5 release:
#    CHARTS=release-1.5 make test
# Default is to install from the local charts.
CHARTS     ?= local
CONFIGFILE := configs/$(CHARTS)
include $(CONFIGFILE)

cpu_family	:= $(shell lscpu | grep 'CPU family:' | awk '{print $$3}')
cpu_model	:= $(shell lscpu | grep 'Model:' | awk '{print $$2}')
os_vendor	:= $(shell lsb_release -i -s)
os_release	:= $(shell lsb_release -r -s)
USER		:= $(shell whoami)

.PHONY: 4g-core 5g-core oaisim test reset-test reset-ue reset-5g-test node-prep clean hexaupf

$(M):
	mkdir -p $(M)

$(M)/system-check: | $(M)
	@if [[ $(cpu_family) -eq 6 ]]; then \
		if [[ $(cpu_model) -lt 60 ]]; then \
			echo "FATAL: haswell CPU or newer is required."; \
			exit 1; \
		fi \
	else \
		echo "FATAL: unsupported CPU family."; \
		exit 1; \
	fi
	@if [[ $(os_vendor) =~ (Ubuntu) ]]; then \
		if [[ ! $(os_release) =~ (18.04) ]]; then \
			echo "WARN: $(os_vendor) $(os_release) has not been tested."; \
		fi; \
		if dpkg --compare-versions 4.15 gt $(shell uname -r); then \
			echo "FATAL: kernel 4.15 or later is required."; \
			echo "Please upgrade your kernel by running" \
			"apt install --install-recommends linux-generic-hwe-$(os_release)"; \
			exit 1; \
		fi \
	else \
		echo "FAIL: unsupported OS."; \
		exit 1; \
	fi
	touch $@

$(M)/interface-check: | $(M)
ifeq ($(DATA_IFACE_CONF), .d)
	@echo
	@echo FATAL: Could not find systemd-networkd config for interface $(DATA_IFACE), exiting now!; exit 1
endif
	@echo "Add network configuration for enb interface"
	@if [[ "${ONECLOUD}" ==  "true" ]]; then \
		sudo cp netplan/01-enb-static-config.yaml /etc/netplan ; \
		sudo netplan apply ; \
		sleep 1 ; \
	fi
	touch $@

ifeq ($(K8S_INSTALL),kubespray)
$(M)/setup: | $(M) $(M)/interface-check
	sudo $(SCRIPTDIR)/cloudlab-disksetup.sh
	sudo apt update; sudo apt install -y software-properties-common python3 python3-pip python3-venv jq httpie ipvsadm
	touch $@
endif

ifeq ($(K8S_INSTALL),rke2)
$(M)/initial-setup: | $(M) $(M)/interface-check
	sudo $(SCRIPTDIR)/cloudlab-disksetup.sh
	sudo apt update; sudo apt install -y software-properties-common python3 python3-pip python3-venv jq httpie ipvsadm apparmor apparmor-utils
	systemctl list-units --full -all | grep "docker.service" || sudo apt install -y docker.io
	sudo adduser $(USER) docker || true
	touch $(M)/initial-setup

ifeq ($(PROXY_ENABLED),true)
$(M)/proxy-setting: | $(M)
	echo "Defaults env_keep += \"HTTP_PROXY HTTPS_PROXY NO_PROXY http_proxy https_proxy no_proxy\"" | sudo EDITOR='tee -a' visudo -f /etc/sudoers.d/proxy
	echo "HTTP_PROXY=$(HTTP_PROXY)" >> rke2-server
	echo "HTTPS_PROXY=$(HTTPS_PROXY)" >> rke2-server
	echo "NO_PROXY=$(NO_PROXY),.cluster.local,.svc,$(NODE_IP),192.168.84.0/24,192.168.85.0/24,$(RAN_SUBNET)" >> rke2-server
	sudo mv rke2-server /etc/default/
	echo "[Service]" >> http-proxy.conf
	echo "Environment='HTTP_PROXY=$(HTTP_PROXY)'" >> http-proxy.conf
	echo "Environment='HTTPS_PROXY=$(HTTPS_PROXY)'" >> http-proxy.conf
	echo "Environment='NO_PROXY=$(NO_PROXY)'" >> http-proxy.conf
	sudo mkdir -p /etc/systemd/system/docker.service.d
	sudo mv http-proxy.conf /etc/systemd/system/docker.service.d
	sudo systemctl daemon-reload
	sudo systemctl restart docker
	touch $(M)/proxy-setting
else
$(M)/proxy-setting: | $(M)
	@echo -n ""
	touch $(M)/proxy-setting
endif

$(M)/setup: | $(M)/initial-setup $(M)/proxy-setting
	touch $@
endif

$(BUILD)/kubespray: | $(M)/setup
	mkdir -p $(BUILD)
	cd $(BUILD); git clone https://github.com/kubernetes-incubator/kubespray.git -b $(KUBESPRAY_VERSION)

$(VENV)/bin/activate: | $(M)/setup
	python3 -m venv $(VENV)
	source "$(VENV)/bin/activate" && \
	python -m pip install -U pip && \
	deactivate

$(M)/kubespray-requirements: $(BUILD)/kubespray | $(VENV)/bin/activate
	source "$(VENV)/bin/activate" && \
	pip install -r $(BUILD)/kubespray/requirements.txt
	touch $@

ifeq ($(K8S_INSTALL),kubespray)
$(M)/k8s-ready: | $(M)/setup $(BUILD)/kubespray $(VENV)/bin/activate $(M)/kubespray-requirements
	source "$(VENV)/bin/activate" && cd $(BUILD)/kubespray; \
	ansible-playbook -b -i inventory/local/hosts.ini \
		-e "{'http_proxy' : $(HTTP_PROXY)}" \
		-e "{'https_proxy' : $(HTTPS_PROXY)}" \
		-e "{'no_proxy' : $(NO_PROXY)}" \
		-e "{'override_system_hostname' : False, 'disable_swap' : True}" \
		-e "{'docker_version' : $(DOCKER_VERSION)}" \
		-e "{'docker_iptables_enabled' : True}" \
		-e "{'kube_version' : $(K8S_VERSION)}" \
		-e "{'kube_network_plugin_multus' : True, 'multus_version' : stable, 'multus_cni_version' : 0.3.1}" \
		-e "{'kube_proxy_metrics_bind_address' : 0.0.0.0:10249}" \
		-e "{'kube_pods_subnet' : 192.168.84.0/24, 'kube_service_addresses' : 192.168.85.0/24}" \
		-e "{'kube_apiserver_node_port_range' : 2000-36767}" \
		-e "{'kubeadm_enabled': True}" \
		-e "{'kube_feature_gates' : [SCTPSupport=True]}" \
		-e "{'kubelet_custom_flags' : [--allowed-unsafe-sysctls=net.*, --node-ip=$(NODE_IP)]}" \
		-e "{'dns_min_replicas' : 1}" \
		-e "{'helm_enabled' : True, 'helm_version' : $(HELM_VERSION)}" \
		cluster.yml
	mkdir -p $(HOME)/.kube
	sudo cp -f /etc/kubernetes/admin.conf $(HOME)/.kube/config
	sudo chown $(shell id -u):$(shell id -g) $(HOME)/.kube/config
	kubectl wait pod -n kube-system --for=condition=Ready --all
	sudo adduser $(USER) docker
	touch $@

$(M)/helm-ready: | $(M)/k8s-ready
	# helm repo add incubator https://charts.helm.sh/incubator
	# helm repo add cord https://charts.opencord.org
	# helm repo add atomix https://charts.atomix.io
	# helm repo add onosproject https://charts.onosproject.org
	# helm repo add aether https://charts.aetherproject.org
	# helm repo add rancher http://charts.rancher.io/
	touch $@
endif

ifeq ($(K8S_INSTALL),rke2)
$(M)/k8s-ready: | $(M)/setup
	sudo mkdir -p /etc/rancher/rke2/
	[ -d /usr/local/etc/emulab ] && [ ! -e /var/lib/rancher ] && sudo ln -s /var/lib/rancher /mnt/extra/rancher || true  # that link gets deleted on cleanup
	echo "cni: multus,calico" >> config.yaml
	echo "cluster-cidr: 192.168.84.0/24" >> config.yaml
	echo "service-cidr: 192.168.85.0/24" >> config.yaml
	echo "kubelet-arg:" >> config.yaml
	echo "- --allowed-unsafe-sysctls="net.*"" >> config.yaml
	echo "- --node-ip="$(NODE_IP)"" >> config.yaml
	echo "pause-image: k8s.gcr.io/pause:3.3" >> config.yaml
	echo "kube-proxy-arg:" >> config.yaml
	echo "- --metrics-bind-address="0.0.0.0:10249"" >> config.yaml
	echo "- --proxy-mode="ipvs"" >> config.yaml
	echo "kube-apiserver-arg:" >> config.yaml
	echo "- --service-node-port-range="2000-36767"" >> config.yaml
	sudo mv config.yaml /etc/rancher/rke2/
	curl -sfL https://get.rke2.io | sudo INSTALL_RKE2_VERSION=$(RKE2_K8S_VERSION) sh -
	sudo systemctl enable rke2-server.service
	sudo systemctl start rke2-server.service
	sudo /var/lib/rancher/rke2/bin/kubectl --kubeconfig /etc/rancher/rke2/rke2.yaml wait nodes --for=condition=Ready --all --timeout=300s
	sudo /var/lib/rancher/rke2/bin/kubectl --kubeconfig /etc/rancher/rke2/rke2.yaml wait deployment -n kube-system --for=condition=available --all --timeout=300s
	@$(eval STORAGE_CLASS := $(shell /var/lib/rancher/rke2/bin/kubectl --kubeconfig /etc/rancher/rke2/rke2.yaml get storageclass -o name))
	@echo "STORAGE_CLASS: ${STORAGE_CLASS}"
	if [ "$(STORAGE_CLASS)" == "" ]; then \
		sudo /var/lib/rancher/rke2/bin/kubectl --kubeconfig /etc/rancher/rke2/rke2.yaml apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/$(LPP_VERSION)/deploy/local-path-storage.yaml --wait=true; \
		sudo /var/lib/rancher/rke2/bin/kubectl --kubeconfig /etc/rancher/rke2/rke2.yaml patch storageclass local-path -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'; \
	fi
	curl -LO "https://dl.k8s.io/release/$(KUBECTL_VERSION)/bin/linux/amd64/kubectl"
	sudo chmod +x kubectl
	sudo mv kubectl /usr/local/bin/
	kubectl version --client
	mkdir -p $(HOME)/.kube
	sudo cp /etc/rancher/rke2/rke2.yaml $(HOME)/.kube/config
	sudo chown -R $(shell id -u):$(shell id -g) $(HOME)/.kube
	touch $@
	kubectl apply -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/v0.72.0/example/prometheus-operator-crd/monitoring.coreos.com_servicemonitors.yaml

$(M)/helm-ready: | $(M)/k8s-ready
	curl -fsSL -o ${GET_HELM} https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
	chmod 700 ${GET_HELM}
	sudo DESIRED_VERSION=$(HELM_VERSION) ./${GET_HELM}
	helm repo add incubator https://charts.helm.sh/incubator
	helm repo add cord https://charts.opencord.org
	helm repo add atomix https://charts.atomix.io
	helm repo add onosproject https://charts.onosproject.org
	helm repo add aether https://charts.aetherproject.org
	helm repo add rancher http://charts.rancher.io/
	helm repo add hexaebpf https://charts.coranlabs.com/helm/charts/
	touch $@
endif

/opt/cni/bin/static: | $(M)/k8s-ready
	mkdir -p $(BUILD)/cni-plugins; cd $(BUILD)/cni-plugins; \
	wget https://github.com/containernetworking/plugins/releases/download/v0.8.2/cni-plugins-linux-amd64-v0.8.2.tgz && \
	tar xvfz cni-plugins-linux-amd64-v0.8.2.tgz
	sudo cp $(BUILD)/cni-plugins/static /opt/cni/bin/

node-prep: | $(M)/helm-ready /opt/cni/bin/static

router-pod: | $(M)/router-pod
$(M)/router-pod: $(ROUTER_POD_NETCONF)
	sudo systemctl restart systemd-networkd
	DATA_IFACE=$(DATA_IFACE) envsubst < $(RESOURCEDIR)/router.yaml | kubectl apply -f -
	kubectl wait pod -n default --for=condition=Ready -l app=router --timeout=300s
	@touch $@

$(M)/router-host: $(ROUTER_HOST_NETCONF) $(UE_NAT_CONF)
	sudo systemctl daemon-reload
	sudo systemctl enable aiab-ue-nat.service
	sudo systemctl start aiab-ue-nat.service
	sudo systemctl restart systemd-networkd
	$(eval oiface := $(shell ip route list default | awk -F 'dev' '{ print $$2; exit }' | awk '{ print $$1 }'))
	@touch $@

4g-core: node-prep
ifeq ($(ENABLE_ROUTER),true)
ifeq ($(ENABLE_OAISIM),true)
4g-core: $(M)/router-pod
else
4g-core: $(M)/router-host
endif
endif
4g-core: $(M)/omec
$(M)/omec:
	@if [[ "${CHARTS}" == "local" || "${CHARTS}" == "local-sdcore" ]]; then \
		helm dep up $(SD_CORE_CHART); \
	else \
		helm repo update; \
	fi
	NODE_IP=${NODE_IP} DATA_IFACE=${DATA_IFACE} RAN_SUBNET=${RAN_SUBNET} envsubst < $(4G_CORE_VALUES) | \
	helm upgrade --create-namespace --install --wait $(HELM_GLOBAL_ARGS) \
		--namespace omec \
		--values - \
		sd-core \
		$(SD_CORE_CHART)
	@if [[ "${ENABLE_OAISIM}" == "false" ]]; then \
		$(eval mme_ip := $(shell ip -4 -o addr show $${DATA_IFACE} | awk '{print $$4}' | cut -d'/' -f1)) \
		echo "Your MME IP is $(mme_ip)"; \
	fi
	@touch $@

hexa: node-prep
ifeq ($(ENABLE_ROUTER),true)
ifeq ($(ENABLE_GNBSIM),true)
hexa: $(M)/router-pod
else
hexa: $(M)/router-host
endif
endif
hexa: $(M)/hexa
$(M)/hexa:
	NODE_IP=${NODE_IP} DATA_IFACE=${DATA_IFACE} RAN_SUBNET=${RAN_SUBNET} ENABLE_GNBSIM=${ENABLE_GNBSIM} envsubst < $(5G_CORE_VALUES) | \
	helm upgrade --create-namespace --install --wait $(HELM_GLOBAL_ARGS) \
		--namespace $(NS) \
		--values - \
		hexa-core \
		$(SD_CORE_CHART)
		-- timeout 10m

	@echo "1" > ${UPF_COUNT}
	touch $@
hexaupf:
	helm $(HELM_ACTION) \
		hexaupf hexaebpf/hexa-upf \
		--version 1.0.0 \
		-n $(NS) \
		$(HELM_ARGS)


# Install additional UPF(s)
5g-upf:
	@if [[ $(UPF_NUMBER) -lt 1 ]]; then \
	      echo "Deploy '5g-core' before adding additional UPF(s)"; \
				exit 1; \
	fi
	$(eval IP_ID=$(shell echo $$((3+$(UPF_NUMBER)))))
	$(eval IP_UE_ID=$(shell echo $$((250-$(UPF_NUMBER)))))
	NODE_IP=${NODE_IP} DATA_IFACE=${DATA_IFACE} RAN_SUBNET=${RAN_SUBNET} IP_ID=${IP_ID} IP_UE_ID=${IP_UE_ID} envsubst < $(5G_UPF_VALUES) | \
	helm upgrade --create-namespace --install --wait $(HELM_GLOBAL_ARGS) \
		--namespace upf-${UPF_NUMBER} \
		--values - \
		bess-upf \
		$(UPF_CHART)
	kubectl -n default exec -ti router -- ip route add 172.$(IP_UE_ID).0.0/16 via 192.168.250.$(IP_ID)
	$(eval UPF_NUMBER=$(shell echo $$(($(UPF_NUMBER)+1))))
	@echo $(UPF_NUMBER) > ${UPF_COUNT}

# UE images includes kernel module, ue_ip.ko
# which should be built in the exactly same kernel version of the host machine
$(BUILD)/openairinterface: | $(M)/setup
	mkdir -p $(BUILD)
	cd $(BUILD); git clone https://github.com/opencord/openairinterface.git

ifeq ($(K8S_INSTALL),kubespray)
download-ue-image: | $(M)/k8s-ready $(BUILD)/openairinterface
	sg docker -c "docker pull ${OAISIM_UE_IMAGE} && \
		docker tag ${OAISIM_UE_IMAGE} omecproject/lte-uesoftmodem:1.1.0"
	touch $(M)/ue-image

$(M)/ue-image: | $(M)/k8s-ready $(BUILD)/openairinterface
	cd $(BUILD)/openairinterface; \
	sg docker -c "docker build . --target lte-uesoftmodem \
		--network=host \
		--build-arg http_proxy=$(HTTP_PROXY)/ \
		--build-arg build_base=omecproject/oai-base:1.1.0 \
		--file Dockerfile.ue \
		--tag omecproject/lte-uesoftmodem:1.1.0"
	touch $@
endif

ifeq ($(K8S_INSTALL),rke2)
download-ue-image: | $(M)/k8s-ready $(BUILD)/openairinterface
	sg docker -c "docker pull ${OAISIM_UE_IMAGE} && \
		docker tag ${OAISIM_UE_IMAGE} omecproject/lte-uesoftmodem:1.1.0 && \
		docker save -o /tmp/lte-uesoftmodem.tar omecproject/lte-uesoftmodem:1.1.0"
	$(CTR_CMD) images import /tmp/lte-uesoftmodem.tar
	touch $(M)/ue-image

$(M)/ue-image: $(M)/k8s-ready $(BUILD)/openairinterface
	cd $(BUILD)/openairinterface; \
	sg docker -c "docker build . --target lte-uesoftmodem \
		--network=host \
		--build-arg http_proxy=$(HTTP_PROXY)/ \
		--build-arg build_base=omecproject/oai-base:1.1.0 \
		--file Dockerfile.ue \
		--tag omecproject/lte-uesoftmodem:1.1.0 && \
		docker save -o /tmp/lte-uesoftmodem.tar omecproject/lte-uesoftmodem:1.1.0"
	$(CTR_CMD) images import /tmp/lte-uesoftmodem.tar
	touch $@
endif

/etc/systemd/%:
	@sudo mkdir -p $(@D)
	@sed 's/DATA_IFACE/$(DATA_IFACE)/g' $(MAKEDIR)/systemd/$(@F) > /tmp/$(@F)
	@sudo cp /tmp/$(@F) $@
	echo "Installed $@"

oaisim-standalone: | $(M)/helm-ready $(M)/ue-image $(LO_NETCONF)
	sudo systemctl restart systemd-networkd
	@ip link show $(DATA_IFACE) > /dev/null || (echo DATA_IFACE is not set or does not exist; exit 1)
	@if [[ "${MME_IP}" == "" ]]; then \
	        echo MME_IP is not set; \
	        exit 1; \
	else \
	        ping -c 3 $(MME_IP) > /dev/null || (echo MME $(MME_IP) is not reachable; exit 1) \
	fi
	sudo ip route add 192.168.252.0/24 via $(MME_IP)
	helm repo update
	helm upgrade --create-namespace --install $(HELM_GLOBAL_ARGS) --namespace omec oaisim cord/oaisim -f $(OAISIM_VALUES) \
	        --set config.enb.networks.s1u.interface=$(DATA_IFACE) \
	        --set config.enb.networks.s1_mme.interface=$(DATA_IFACE) \
	        --set config.enb.mme.address=$(MME_IP) \
	        --set config.enb.mme.isLocal=false \
	        --set images.pullPolicy=IfNotPresent
	kubectl rollout status -n omec statefulset ue
	@echo "Test: registration"
	@timeout 60s bash -c \
	"until ip addr show oip1 | grep -q inet; \
	do \
	        echo 'Waiting for UE 1 gets IP address'; \
	        sleep 3; \
	done"
	@echo "Test: ping from UE to 8.8.8.8"
	ping -I oip1 8.8.8.8 -c 3
	@touch $(M)/oaisim $(M)/omec

oaisim: | $(M)/oaisim
$(M)/oaisim: | $(M)/ue-image $(M)/router-pod $(OAISIM_NETCONF)
	sudo systemctl restart systemd-networkd
	sleep 1
	helm upgrade --create-namespace --install $(HELM_GLOBAL_ARGS) --namespace omec oaisim cord/oaisim -f $(OAISIM_VALUES) \
		--set images.pullPolicy=IfNotPresent
	kubectl rollout status -n omec statefulset ue
	@timeout 60s bash -c \
	"until ip addr show oip1 | grep -q inet; \
	do \
		echo 'Waiting for UE 1 gets IP address'; \
		sleep 3; \
	done"
	touch $@

roc: $(M)/roc
$(M)/roc: $(M)/helm-ready
	kubectl get namespace aether-roc 2> /dev/null || kubectl create namespace aether-roc
	helm repo update
	if [ "$(CHARTS)" == "local" ]; then helm dep up $(AETHER_ROC_UMBRELLA_CHART); fi
	if [ "$(CHARTS)" == "release-2.0" -o "$(CHARTS)" == "release-1.6" ]; then \
		helm upgrade --install --wait $(HELM_GLOBAL_ARGS) \
			--namespace kube-system \
			--values $(ROC_VALUES) \
			atomix-controller \
			$(ATOMIX_CONTROLLER_CHART); \
		helm upgrade --install --wait $(HELM_GLOBAL_ARGS) \
			--namespace kube-system \
			--values $(ROC_VALUES) \
			atomix-raft-storage \
			$(ATOMIX_RAFT_STORAGE_CHART); \
	else \
		helm upgrade --install --wait $(HELM_GLOBAL_ARGS) \
			--namespace kube-system \
			--values $(ROC_VALUES) \
			atomix \
			$(ATOMIX_CHART); \
	fi
	helm upgrade --install --wait $(HELM_GLOBAL_ARGS) \
		--namespace kube-system \
		--values $(ROC_VALUES) \
		onos-operator \
		$(ONOS_OPERATOR_CHART)
	helm upgrade --install --wait $(HELM_GLOBAL_ARGS) \
		--namespace aether-roc \
		--values $(ROC_VALUES) \
		aether-roc-umbrella \
		$(AETHER_ROC_UMBRELLA_CHART)
	touch $@

# Load the ROC 4G models.  Disable loading network slice from SimApp.
roc-4g-models: $(M)/roc
	sed -i 's/provision-network-slice: true/provision-network-slice: false/' $(4G_CORE_VALUES)
	sed -i 's/# syncUrl/syncUrl/' $(4G_CORE_VALUES)
	if [ "${ENABLE_SUBSCRIBER_PROXY}" == "true" ] ; then \
		sed -i 's/# sub-proxy-endpt:/sub-proxy-endpt:/' $(4G_CORE_VALUES) ; \
		sed -i 's/#   addr: sub/  addr: sub/' $(4G_CORE_VALUES) ; \
		sed -i 's/#   port: 5000/  port: 5000/' $(4G_CORE_VALUES) ; \
	fi
	@$(eval ONOS_CLI_POD := $(shell kubectl -n aether-roc get pods -l name=onos-cli -o name))
	echo "ONOS CLI pod: ${ONOS_CLI_POD}"
	@$(eval API_SERVICE := $(shell kubectl -n aether-roc get --no-headers=true services -l app.kubernetes.io/name=aether-roc-api | awk '{print $$1}'))
	echo "API SERVICE : ${API_SERVICE}"
	if [ "$(CHARTS)" != "release-2.0" -a "$(CHARTS)" != "release-1.6" ]; then \
        until kubectl -n aether-roc exec ${ONOS_CLI_POD} -- \
            curl -s -f -L -X PATCH "http://${API_SERVICE}:8181/aether-roc-api" \
            --header 'Content-Type: application/json' \
            --data-raw "$$(cat ${ROC_DEFAULTENT_MODEL})"; do sleep 5; done; \
	fi
	until kubectl -n aether-roc exec ${ONOS_CLI_POD} -- \
		curl -s -f -L -X PATCH "http://${API_SERVICE}:8181/aether-roc-api" \
		--header 'Content-Type: application/json' \
		--data-raw "$$(cat ${ROC_4G_MODELS})"; do sleep 5; done

# Load the ROC 5G models.  Disable loading network slice from SimApp.
roc-5g-models: $(M)/roc
	sed -i 's/provision-network-slice: true/provision-network-slice: false/' $(5G_CORE_VALUES)
	sed -i 's/# syncUrl/syncUrl/' $(5G_CORE_VALUES)
	if [ "${ENABLE_SUBSCRIBER_PROXY}" == "true" ] ; then \
		sed -i 's/# sub-proxy-endpt:/sub-proxy-endpt:/' $(5G_CORE_VALUES) ; \
		sed -i 's/#   addr: sub/  addr: sub/' $(5G_CORE_VALUES) ; \
		sed -i 's/#   port: 5000/  port: 5000/' $(5G_CORE_VALUES) ; \
	fi
	@$(eval ONOS_CLI_POD := $(shell kubectl -n aether-roc get pods -l name=onos-cli -o name))
	echo "ONOS CLI pod: ${ONOS_CLI_POD}"
	@$(eval API_SERVICE := $(shell kubectl -n aether-roc get --no-headers=true services -l app.kubernetes.io/name=aether-roc-api | awk '{print $$1}'))
	echo "API SERVICE : ${API_SERVICE}"
	if [ "$(CHARTS)" != "release-2.0" -a "$(CHARTS)" != "release-1.6" ]; then \
        until kubectl -n aether-roc exec ${ONOS_CLI_POD} -- \
            curl -s -f -L -X PATCH "http://${API_SERVICE}:8181/aether-roc-api" \
            --header 'Content-Type: application/json' \
            --data-raw "$$(cat ${ROC_DEFAULTENT_MODEL})"; do sleep 5; done; \
	fi
	until kubectl -n aether-roc exec ${ONOS_CLI_POD} -- \
		curl -s -f -L -X PATCH "http://${API_SERVICE}:8181/aether-roc-api" \
		--header 'Content-Type: application/json' \
		--data-raw "$$(cat ${ROC_5G_MODELS})"; do sleep 5; done

roc-clean:
	@echo "This could take 2-3 minutes..."
	sed -i 's/provision-network-slice: false/provision-network-slice: true/' $(4G_CORE_VALUES)
	sed -i 's/  syncUrl/  # syncUrl/' $(4G_CORE_VALUES)
	sed -i 's/  sub-proxy-endpt:/  # sub-proxy-endpt:/' $(4G_CORE_VALUES)
	sed -i 's/    addr: sub/  #   addr: sub/' $(4G_CORE_VALUES)
	sed -i 's/    port: 5000/  #   port: 5000/' $(4G_CORE_VALUES)
	sed -i 's/provision-network-slice: false/provision-network-slice: true/' $(5G_CORE_VALUES)
	sed -i 's/  syncUrl/  # syncUrl/' $(5G_CORE_VALUES)
	sed -i 's/  sub-proxy-endpt:/  # sub-proxy-endpt:/' $(5G_CORE_VALUES)
	sed -i 's/    addr: sub/  #   addr: sub/' $(5G_CORE_VALUES)
	sed -i 's/              port: 5000/            #   port: 5000/' $(5G_CORE_VALUES)
	kubectl delete namespace aether-roc || true
	rm -rf $(M)/roc
	rm -f ${GET_HELM}

monitoring: $(M)/monitoring
$(M)/monitoring: $(M)/helm-ready
	helm upgrade --install --wait $(HELM_GLOBAL_ARGS) \
		--namespace=cattle-monitoring-system \
		--create-namespace \
		--values=$(MONITORING_VALUES) \
		rancher-monitoring-crd \
		$(RANCHER_MONITORING_CRD_CHART)
	helm upgrade --install --wait $(HELM_GLOBAL_ARGS) \
		--namespace=cattle-monitoring-system \
		--create-namespace \
		--values=$(MONITORING_VALUES) \
		rancher-monitoring \
		$(RANCHER_MONITORING_CHART)
	touch $(M)/monitoring

monitoring-4g: $(M)/monitoring
	kubectl create namespace omec || true
	kubectl create namespace cattle-dashboards || true
	kubectl apply -k resources/4g-monitoring

monitoring-5g: $(M)/monitoring
	kubectl create namespace omec || true
	kubectl create namespace cattle-dashboards || true
	kubectl apply -k resources/5g-monitoring

enodebd:
	helm upgrade --install --wait $(HELM_GLOBAL_ARGS) \
		--namespace=aether-apps \
		--create-namespace \
		enodebd \
		${ENODEBD_CHART}
	touch $(M)/enodebd

enodebd-clean:
	helm -n aether-apps delete enodebd || true
	rm $(M)/enodebd

monitoring-clean:
	helm -n cattle-monitoring-system delete rancher-monitoring || true
	helm -n cattle-monitoring-system delete rancher-monitoring-crd || true
	kubectl delete namespace cattle-dashboards cattle-monitoring-system || true
	rm $(M)/monitoring

upf-clean:
	$(eval TO_REMOVE=$(shell echo $$(($(UPF_NUMBER)-1))))
	@echo Removing $(TO_REMOVE) additional UPFs
	@number=$(UPF_NUMBER) ; \
	while [[ $$number -gt 1 ]] ; do \
					((number = number - 1)) ; \
					((addr = 250 - number)) ; \
					helm delete -n upf-$$number $$(helm -n upf-$$number ls -qa) || true ; \
					echo "Wait for all pods to terminate..." ; \
					kubectl wait -n upf-$$number --for=delete --all=true -l app!=ue pod --timeout=180s || true ; \
					kubectl delete namespace upf-$$number || true ; \
					kubectl -n default exec -ti router -- ip route delete 172.$$addr.0.0/16 || true ; \
					echo "" ; \
	done
	@echo "1" > ${UPF_COUNT}

hexa-clean: upf-clean
	helm delete -n hexa $$(helm -n hexa ls -qa) || true
	kubectl delete namespace hexa || true
	@rm -f $(UPF_COUNT)
	@echo ""
	@echo "Wait for all pods to terminate..."
	kubectl wait -n omec --for=delete --all=true -l app!=ue pod --timeout=180s || true

router-clean:
	@kubectl delete net-attach-def router-net 2>/dev/null || true
	@kubectl delete po router 2>/dev/null || true
	kubectl wait --for=delete -l app=router pod --timeout=180s 2>/dev/null || true
	sudo ip link del access || true
	sudo ip link del core || true
	$(eval oiface := $(shell ip route list default | awk -F 'dev' '{ print $$2; exit }' | awk '{ print $$1 }'))
	sudo iptables -t nat -D POSTROUTING -s 172.250.0.0/16 -o $(oiface) -j MASQUERADE || true
	@sudo ip link del data 2>/dev/null || true
	@cd $(M); rm -f router-pod router-host

oaisim-clean: reset-ue
	@sudo ip addr del 127.0.0.2/8 dev lo 2>/dev/null || true
	@sudo ip link del enb 2>/dev/null || true
	@sudo ip route del 192.168.252.0/24 || true
	@cd $(M); rm -f oaisim-lo

4g-test: test
test: | 4g-core $(M)/oaisim
	@sleep 5
	@echo "Test1: ping from UE to SGI network gateway"
	ping -I oip1 192.168.250.1 -c 15
	@if [ "${PROXY_ENABLED}" == "false" ] ; then \
		@echo "Test2: ping from UE to 8.8.8.8" ; \
		ping -I oip1 8.8.8.8 -c 3 ; \
		@echo "Test3: ping from UE to google.com" ; \
		ping -I oip1 google.com -c 3 ; \
	fi
	@echo "Finished to test"

5g-test: | 5g-core
	@if [[ "${CHARTS}" == "release-1.6" ]]; then echo "[NOTE] 5G Test not supported for Aether 1.6, exiting..."; exit 1; fi
	@echo "Test: Registration + UE initiated PDU Session Establishment + User Data packets"
	@sleep 60
	@rm -f /tmp/gnbsim.out
	@if [[ ${GNBSIM_COLORS} == "true" ]]; then \
		kubectl -n omec exec gnbsim-0 -- ./gnbsim 2>&1 | tee /tmp/gnbsim.out; \
	else \
		kubectl -n omec exec gnbsim-0 -- ./gnbsim 2>&1 | sed -u "s,\x1B\[[0-9;]*[a-zA-Z],,g" | tee /tmp/gnbsim.out; \
	fi
	@grep -q "Simulation Result: PASS\|Profile Status: PASS" /tmp/gnbsim.out

reset-test: | oaisim-clean omec-clean router-clean
	@cd $(M); rm -f omec oaisim 5g-core

reset-ue:
	helm delete -n omec oaisim || true
	kubectl wait -n omec --for=delete pod enb-0 || true
	kubectl wait -n omec --for=delete pod ue-0 || true
	cd $(M); rm -f oaisim

reset-5g-test: hexa-clean
	cd $(M); rm -f 5g-core

reset-dbtestapp:
	helm uninstall --namespace omec 5g-test-app

refresh-4g: reset-ue
	kubectl -n omec delete pod mme-0
	kubectl wait -n omec --for='condition=ready' pod mme-0 --timeout=300s

dbtestapp:
	helm repo update
	if [ "$(CHARTS)" == "local" ]; then helm dep up $(5G_TEST_APPS_CHART); fi
	helm upgrade --install --wait $(HELM_GLOBAL_ARGS) \
		--namespace omec \
		5g-test-app \
		--values $(TEST_APP_VALUES) \
		$(5G_TEST_APPS_CHART)
	@echo "Finished to dbtestapp"

clean-systemd:
	cd /etc/systemd/network && sudo rm -f 10-aiab* 20-aiab* */macvlan.conf
	cd /etc/systemd/system && sudo rm -f aiab*.service && sudo systemctl daemon-reload

ifeq ($(K8S_INSTALL),rke2)
clean: | roc-clean oaisim-clean router-clean clean-systemd
	sudo /usr/local/bin/rke2-uninstall.sh || true
	sudo rm -rf /usr/local/bin/kubectl
	helm repo remove hexaupf
	rm -rf $(M)
endif

ifeq ($(K8S_INSTALL),kubespray)
clean: | roc-clean oaisim-clean router-clean clean-systemd
	source "$(VENV)/bin/activate" && cd $(BUILD)/kubespray; \
	ansible-playbook -b -i inventory/local/hosts.ini reset.yml --extra-vars "reset_confirmation=yes"
	@if [ -d /usr/local/etc/emulab ]; then \
		mount | grep /mnt/extra/kubelet/pods | cut -d" " -f3 | sudo xargs umount; \
		sudo rm -rf /mnt/extra/kubelet; \
	fi
	rm -rf $(M)
endif
