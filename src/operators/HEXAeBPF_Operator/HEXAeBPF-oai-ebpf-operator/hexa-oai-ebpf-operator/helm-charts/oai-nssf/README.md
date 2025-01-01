# Helm Chart for OAI Authentication Server Function (LMF)

The helm-chart is tested on [Minikube](https://minikube.sigs.k8s.io/docs/) and [Red Hat Openshift](https://www.redhat.com/fr/technologies/cloud-computing/openshift) 4.10-4.16. There are no special resource requirements for this NF. 


## Disclaimer

Starting version 2.0.0 of OAI 5G Core network functions their configuration will be in `config.yaml` and all infrastructure related information including image definition will be in `values.yaml`.

## Introduction

OAI-LMF follows 3GPP release 16, more information about the feature set can be found on [NSSFs WiKi page](https://gitlab.eurecom.fr/oai/cn5g/oai-cn5g-nssf/-/wikis/home). The source code be downloaded from [GitLab](https://gitlab.eurecom.fr/oai/cn5g/oai-cn5g-nssf)

OAI [Jenkins Platform](https://jenkins-oai.eurecom.fr/job/OAI-CN5G-LMF/) publishes every `develop` and `master` branch image of OAI-AMF on [docker-hub](https://hub.docker.com/r/oaisoftwarealliance/oai-amf) with tag `develop` and `latest` respectively. Apart from that you can find tags for every release `VX.X.X`. We only publish Ubuntu 22.04 images. We do not publish RedHat/UBI images. These images you have to build from the source code on your RedHat systems or Openshift Platform. You can follow this [tutorial](../../../openshift/README.md) for that.

The helm chart of OAI-LMF creates multiples Kubernetes resources,

1. Service
2. Role Base Access Control (RBAC) (role and role bindings)
3. Deployment
4. Configmap (Contains the configuration file for AMF)
5. Service account

The directory structure

```
├── Chart.yaml
├── README.md
├── templates
│   ├── configmap.yaml
│   ├── deployment.yaml
│   ├── _helpers.tpl
│   ├── NOTES.txt
│   ├── rbac.yaml
│   ├── serviceaccount.yaml
│   └── service.yaml
└── values.yaml (Parent file contains all the configurable parameters)
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


## Advanced Debugging Parameters

Only needed if you are doing advanced debugging


|Parameter                        |Allowed Values                 |Remark                                        |
|---------------------------------|-------------------------------|----------------------------------------------|
|start.nssf                        |true/false                    |If true nssf container will go in sleep mode  |
|start.tcpdump                    |true/false                     |If true tcpdump container will go in sleepmode|
|includeTcpDumpContainer          |true/false                     |If false no tcpdump container will be there   |
|tcpdumpimage.repository          |Image Name                     |                                              |
|tcpdumpimage.version             |Image tag                      |                                              |
|tcpdumpimage.pullPolicy          |IfNotPresent or Never or Always|                                              |
|persistent.sharedvolume          |true/false                     |Save the pcaps in a shared volume with NRF    |
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

1. [oai-5g-advance](../oai-5g-slicing/README.md) for basic deployment with NSSF extra

```
helm install nssf oai-nssf
```

## Note

1. If you are using tcpdump container to take pcaps automatically (`start.tcpdump` is true) you can enable `persistent.sharedvolume` and [persistent volume](./oai-nrf/values.yaml) in NRF. To store the pcaps of all the NFs in one location. It is to ease the automated collection of pcaps.
