# Helm Chart for OAI Location Management Function (LMF)

The helm-chart is tested on [Minikube](https://minikube.sigs.k8s.io/docs/) and [Red Hat Openshift](https://www.redhat.com/fr/technologies/cloud-computing/openshift) 4.10-4.16. There are no special resource requirements for this NF. 


## Disclaimer

Starting version 2.0.0 of OAI 5G Core network functions their configuration will be in `config.yaml` and all infrastructure related information including image definition will be in `values.yaml`.

## Introduction

OAI-LMF follows 3GPP release 16, more information about the feature set can be found on [LMFs WiKi page](https://gitlab.eurecom.fr/oai/cn5g/oai-cn5g-lmf/-/wikis/home). The source code be downloaded from [GitLab](https://gitlab.eurecom.fr/oai/cn5g/oai-cn5g-lmf)

OAI [Jenkins Platform](https://jenkins-oai.eurecom.fr/job/OAI-CN5G-LMF/) publishes every `develop` and `master` branch image of OAI-LMF on [docker-hub](https://hub.docker.com/r/oaisoftwarealliance/oai-lmf) with tag `develop` and `latest` respectively. Apart from that you can find tags for every release `VX.X.X`. We only publish Ubuntu 22.04 images. We do not publish RedHat/UBI images. These images you have to build from the source code on your RedHat systems or Openshift Platform. You can follow this [tutorial](../../../openshift/README.md) for that. 

The helm chart of OAI-LMF creates multiples Kubernetes resources,

1. Service
2. Role Base Access Control (RBAC) (role and role bindings)
3. Deployment
4. Configmap (Contains mounted configuration file of LMF)
5. Service account
6. PVC (optional only when enabled): It is used for saving pcaps. 

The directory structure

```
├── Chart.yaml
├── templates
│   ├── configmap.yaml
│   ├── deployment.yaml
│   ├── _helpers.tpl
│   ├── NOTES.txt
│   ├── pvc.yaml (optional only when enabled): It is used for saving pcaps. 
│   ├── rbac.yaml
│   ├── serviceaccount.yaml
│   └── service.yaml
├── config.yaml (Configuration of the network function)
└── values.yaml

1 directory, 10 files
```

## Parameters

[Values.yaml](./values.yaml) contains all the configurable parameters. Below table defines the configurable parameters. 


|Parameter                    |Allowed Values                 |Remark                                   |
|-----------------------------|-------------------------------|-----------------------------------------|
|kubernetesDistribution               |Vanilla/Openshift              |Vanilla Kubernetes or Openshift          |
|nfimage.repository           |Image Name                     |                                         |
|nfimage.version              |Image tag                      |                                         |
|nfimage.pullPolicy           |IfNotPresent or Never or Always|                                         |
|imagePullSecrets.name        |String                         |Good to use for docker hub               |
|serviceAccount.create        |true/false                     |                                         |
|serviceAccount.annotations   |String                         |                                         |
|serviceAccount.name          |String                         |                                         |
|podSecurityContext.runAsUser |Integer (0,65534)              |Mandatory to use 0                       |
|podSecurityContext.runAsGroup|Integer (0,65534)              |Mandatory to use 0                       |


Only needed if you are doing advanced debugging


|Parameter                        |Allowed Values                 |Remark                                        |
|---------------------------------|-------------------------------|----------------------------------------------|
|start.lmf                       |true/false                     |If true lmf container will go in sleep mode  |
|start.tcpdump                    |true/false                     |If true tcpdump container will go in sleepmode|
|includeTcpDumpContainer          |true/false                     |If false no tcpdump container will be there   |
|tcpdumpimage.repository          |Image Name                     |                                              |
|tcpdumpimage.version             |Image tag                      |                                              |
|tcpdumpimage.pullPolicy          |IfNotPresent or Never or Always|                                              |
|persistent.sharedvolume          |true/false                     |Save the pcaps in a shared volume with LMF    |
|persistent.storageClass          |String                         |Storage class else default SC of your cluster will be used|
|persistent.size                  |In Gi/Mi                       |Size of PVC                                   |
|resources.define                 |true/false                     |                                              |
|resources.limits.tcpdump.cpu     |string                         |Unit m for milicpu or cpu                     |
|resources.limits.tcpdump.memory  |string                         |Unit Mi/Gi/MB/GB                              |
|resources.limits.nf.cpu          |string                         |Unit m for milicpu or cpu                     |
|resources.limits.nf.memory       |string                         |Unit Mi/Gi/MB/GB                              |
|resources.requests.tcpdump.cpu   |string                         |Unit m for milicpu or cpu                     |
|resources.requests.tcpdump.memory|string                         |Unit Mi/Gi/MB/GB                              |
|resources.requests.nf.cpu        |string                         |Unit m for milicpu or cpu                     |
|resources.requests.nf.memory     |string                         |Unit Mi/Gi/MB/GB                              |
|readinessProbe                   |true/false                     |default true                                  |
|livenessProbe                    |true/false                     |default false                                 |
|terminationGracePeriodSeconds    |5                              |In seconds (default 5)                        |
|nodeSelector                     |Node label                     |                                              |
|nodeName                         |Node Name                      |                                              |


## Installation

Better to use the parent charts from:

1. [oai-5g-basic](../oai-5g-basic/README.md) for basic deployment of OAI-5G Core

```bash
helm install oai-lmf .
```

## Note

1. If you are using tcpdump container to take pcaps automatically (`start.tcpdump` is true) you can enable `persistent.sharedvolume` and configure the storage class. To store the pcaps of all the NFs in one location. It is to ease the automated collection of pcaps.
