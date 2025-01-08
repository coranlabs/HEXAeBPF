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

GET_HELM              = get_helm.sh

# KUBESPRAY_VERSION ?= release-2.17
DOCKER_VERSION    ?= '20.10'
HELM_VERSION	  ?= v3.10.3
KUBECTL_VERSION   ?= v1.23.15

RKE2_K8S_VERSION  ?= v1.25.15+rke2r2
K8S_VERSION       ?= v1.25.6
LPP_VERSION       ?= v0.0.24

# OAISIM_UE_IMAGE ?= andybavier/lte-uesoftmodem:1.1.0-$(shell uname -r)
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


NODE_IP ?= $(shell ip route get 8.8.8.8 | grep -oP 'src \K\S+')
ifndef NODE_IP
$(error NODE_IP is not set)
endif

# MME_IP  ?=

HELM_GLOBAL_ARGS ?=


cpu_family	:= $(shell lscpu | grep 'CPU family:' | awk '{print $$3}')
cpu_model	:= $(shell lscpu | grep 'Model:' | awk '{print $$2}')
os_vendor	:= $(shell lsb_release -i -s)
os_release	:= $(shell lsb_release -r -s)
USER		:= $(shell whoami)

.PHONY: node-prep clean

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


ifeq ($(K8S_INSTALL),rke2)
$(M)/initial-setup: | $(M)
	# sudo $(SCRIPTDIR)/cloudlab-disksetup.sh
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
	#helm repo add hexaebpf https://coranlabs.github.io/HEXA_UPF_Helm_Charts/
	touch $@
endif

/opt/cni/bin/static: | $(M)/k8s-ready
	mkdir -p $(BUILD)/cni-plugins; cd $(BUILD)/cni-plugins; \
	wget https://github.com/containernetworking/plugins/releases/download/v0.8.2/cni-plugins-linux-amd64-v0.8.2.tgz && \
	tar xvfz cni-plugins-linux-amd64-v0.8.2.tgz
	sudo cp $(BUILD)/cni-plugins/static /opt/cni/bin/

node-prep: | $(M)/helm-ready /opt/cni/bin/static


clean-systemd:
	cd /etc/systemd/network && sudo rm -f */macvlan.conf
	cd /etc/systemd/system && sudo rm -f && sudo systemctl daemon-reload

ifeq ($(K8S_INSTALL),rke2)
clean: | clean-systemd
	sudo /usr/local/bin/rke2-uninstall.sh || true
	sudo rm -rf /usr/local/bin/kubectl
	rm -rf $(M)
	rm -rf $(BUILD)
	rm -rf $(MAKEDIR)/get_helm.sh
endif

# Target to set up Kubernetes resources
setup_k8s_resources:
	@echo "Creating namespace 'hexa'..."
	kubectl create ns hexa || echo "Namespace 'hexa' already exists."
	@echo "Applying IPPool configuration..."
	kubectl apply -f /home/ubuntu/HEXAeBPF/src/cli/eupf-ippool.yaml
	sudo apt install tmux -y
	touch $(M)/setup_k8s_resources-done

# Target to run HEXAeBPF CLI
run_hexaebpf: node-prep setup_k8s_resources
	@echo "Running HEXAeBPF CLI..."
	python3 /home/ubuntu/HEXAeBPF/src/cli/hexaebpf_cli.py
