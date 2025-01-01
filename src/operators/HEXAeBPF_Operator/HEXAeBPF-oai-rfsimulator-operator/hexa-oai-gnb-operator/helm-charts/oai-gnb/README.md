# Helm Chart for OAI Next Generation Node B (OAI-gNB)

This helm-chart is tested with 
- [RF Simulated oai-gnb](https://gitlab.eurecom.fr/oai/openairinterface5g/-/blob/develop/radio/rfsimulator/README.md). 
- They are designed to be used with:
  - USRP B2XX
  - USRP N3XX
  - USRP X3XX

You can define dedicated interfaces for fronthaul, N2 and N3. In `template/deployment.yaml` there is a section to use it with USB based USRPs. The option to use RFSIM, USRPs or Radio Units is decided via configuration file. The container image always remains the same. 

Before using this helm-chart we recommend you read about OAI codebase and its working from the documents listed on [OAI gitlab](https://gitlab.eurecom.fr/oai/openairinterface5g/-/tree/develop/doc)

**Note**: This chart is tested on [Minikube](https://minikube.sigs.k8s.io/docs/) and [Red Hat Openshift](https://www.redhat.com/fr/technologies/cloud-computing/openshift) 4.10-4.16. RFSIM-GNB requires minimum 2CPU and 2Gi RAM and [multus-cni](https://github.com/k8snetworkplumbingwg/multus-cni) plugin for multiple interfaces if they are used.

All the extra interfaces/multus interfaces created inside the pod are using `macvlan` mode. If your environment does not allow using `macvlan` then you need to change the multus definitions. 

## Introduction

To know more about the feature set of OpenAirInterface you can check it [here](https://gitlab.eurecom.fr/oai/openairinterface5g/-/blob/develop/doc/FEATURE_SET.md#openairinterface-5g-nr-feature-set). 

The [codebase](https://gitlab.eurecom.fr/oai/openairinterface5g/-/tree/develop) for gNB, CU, DU, CU-CP/CU-UP, NR-UE is the same. Everyweek on [docker-hub](https://hub.docker.com/r/oaisoftwarealliance/oai-gnb) our [Jenkins Platform](https://jenkins-oai.eurecom.fr/view/RAN/) publishes two docker-images 

1. `oaisoftwarealliance/oai-gnb` for monolithic gNB, DU, CU, CU-CP 
2. `oaisoftwarealliance/oai-nr-cuup` for CU-UP. 

Each image has develop tag and a dedicated week tag for example `2024.w32`. We only publish Ubuntu 22.04 images. We do not publish RedHat/UBI images. These images you have to build from the source code on your RedHat systems or Openshift Platform. You can follow this [tutorial](../../../openshift/README.md) for that.

The helm chart of OAI-GNB creates multiples Kubernetes resources,

1. Service
2. Role Base Access Control (RBAC) (role and role bindings)
3. Deployment
4. Configmap
5. Service account
6. Network-attachment-definition (Optional only when multus is used)

The directory structure

```
.
├── Chart.yaml
├── templates
│   ├── configmap.yaml (All the configuration is there)
│   ├── deployment.yaml
│   ├── _helpers.tpl
│   ├── multus.yaml
│   ├── NOTES.txt
│   ├── rbac.yaml
│   ├── serviceaccount.yaml
│   └── service.yaml
└── values.yaml
```

## Parameters

[Values.yaml](./values.yaml) contains all the configurable parameters. Below table defines the configurable parameters. You need a dedicated interface for Fronthaul. Creating deadicated interfaces for N2 and N3 is optional. You can use a single interface for N2 and N3.



|Parameter                       |Allowed Values                 |Remark                                          |
|--------------------------------|-------------------------------|------------------------------------------------|
|kubernetesDistribution                  |Vanilla/Openshift              |Vanilla Kubernetes or Openshift                 |
|nfimage.repository              |Image Name                     |                                                |
|nfimage.version                 |Image tag                      |                                                |
|nfimage.pullPolicy              |IfNotPresent or Never or Always|                                                |
|imagePullSecrets.name           |String                         |Good to use for docker hub                      |
|serviceAccount.create           |true/false                     |                                                |
|serviceAccount.annotations      |String                         |                                                |
|serviceAccount.name             |String                         |                                                |
|podSecurityContext.runAsUser    |Integer (0,65534)              |                                                |
|podSecurityContext.runAsGroup   |Integer (0,65534)              |                                                |
|multus.n2Interface.ipAdd            |IPV4                           |NA                                       |
|multus.n2Interface.netmask          |netmask                        |NA                                       |
|multus.n2Interface.gateway(optional)|netmask                        |NA                                       |
|multus.n2Interface.name (optional)  |Interface name inside container|NA                                       |
|multus.n2Interface.routes (optional)|Routes                         |NA                                       |
|multus.n3Interface.create           |true/false                     |default false                            |
|multus.n3Interface.ipAdd            |IPV4                           |NA                                       |
|multus.n3Interface.netmask          |netmask                        |NA                                       |
|multus.n3Interface.gateway(optional)|netmask                        |NA                                       |
|multus.n3Interface.name (optional)  |Interface name inside container|NA                                       |
|multus.n3Interface.routes (optional)|Routes                         |NA                                       |
|multus.ruInterface.create           |true/false                     |default false                           |
|multus.ruInterface.ipAdd            |IPV4                           |NA                                       |
|multus.ruInterface.netmask          |netmask                        |NA                                       |
|multus.ruInterface.gateway(optional)|netmask                        |NA                                       |
|multus.ruInterface.name (optional)  |Interface name inside container|NA                                       |
|multus.ruInterface.routes (optional)|Routes                         |NA                                       |
|multus.defaultGateway               |IPV4                           |Default route inside container (optional)|
|multus.hostInterface                |HostInterface Name             |

The config parameters mentioned in `config` block of `values.yaml` are limited on purpose to maintain simplicity. They do not allow changing a lot of parameters of oai-gnb. If you want to use your own configuration file for oai-gnb. It is recommended to copy it in `templates/configmap.yaml`. The command line for gnb is provided in `config.useAdditionalOptions`.

The charts are configured to be used with primary CNI of Kubernetes. When you will mount the configuration file you have to define static ip-addresses for N2, N3 and RU. Most of the primary CNIs do not allow static ip-address allocation. To overcome this we are using multus-cni with static ip-address allocation. At minimum you have to create one multus interface which you can use for N2, N3 and RU. If you want you can create dedicated interfaces.

You can find [here](https://gitlab.eurecom.fr/oai/openairinterface5g/-/tree/develop/targets/PROJECTS/GENERIC-NR-5GC/CONF) different sample configuration files for different bandwidths and frequencies. The binary of oai-gnb is called as `nr-softmodem`. To know more about its functioning and command line parameters you can visit this [page](https://gitlab.eurecom.fr/oai/openairinterface5g/-/blob/develop/doc/RUNMODEM.md)

## Advanced Debugging Parameters

Only needed if you are doing advanced debugging

|Parameter                        |Allowed Values                 |Remark                                        |
|---------------------------------|-------------------------------|----------------------------------------------|
|start.gnb                        |true/false                     |If true gnb container will go in sleep mode   |
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

## How to use

0. Make sure the core network is running else you need to first start the core network. You can follow any of the below links
  - [OAI 5G Core Basic](../../oai-5g-basic/README.md)
  - [OAI 5G Core Mini](../../oai-5g-mini/README.md)

1. Check the networking, config parameters of the file in `templates/configmap.yaml`. Once the GNB is configured.

```bash
helm install oai-gnb .
```

2. Deploy NR-UE

```bash
helm install oai-nr-ue ../oai-nr-ue
```

3. Once NR-UE is connected you can go inside the pod and ping via `oai` interface. If you do not see this interface then the UE is not connected to gNB or have some issues at core network.

```bash
kubectl exec -it <oai-nr-ue-pod-name> -- bash
#ping towards spgwu/upf
ping -I oaitun_ue1 12.1.1.1
#ping towards google dns
ping -I oaitun_ue1 8.8.8.8
```

## Note

1. If you are using multus then make sure it is properly configured and if you don't have a gateway for your multus interface then avoid using gateway and defaultGateway parameter. Either comment them or leave them empty. Wrong gateway configuration can create issues with pod networking and pod will not be able to resolve service names.
