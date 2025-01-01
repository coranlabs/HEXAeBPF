# Helm Chart for OAI Traffic Server

The helm-chart is tested on [Minikube](https://minikube.sigs.k8s.io/docs/) and [Red Hat Openshift](https://www.redhat.com/fr/technologies/cloud-computing/openshift) 4.10-4.16. There are no special resource requirements for this NF. 


**NOTE**: All the extra interfaces/multus interfaces created inside the pod are using `macvlan` mode. If your environment does not allow using `macvlan` then you need to change the multus definition.

## Introduction

OAI-Traffic-Server image is built using this [dockerfile](). The traffic server is used as iperf3 server. 

The helm chart of OAI-Traffic-Server creates multiples Kubernetes resources,

1. Role Base Access Control (RBAC) (role and role bindings)
2. Deployment
3. Configmap (Contains the mounted configuration file for SMF)
4. Service account
5. Network-attachment-definition (Optional only when multus is used)

The directory structure

```
├── Chart.yaml
├── README.md
├── templates
│   ├── configmap.yaml
│   ├── deployment.yaml
│   ├── _helpers.tpl
│   ├── multus.yaml
│   ├── NOTES.txt
│   ├── rbac.yaml
│   ├── serviceaccount.yaml
├── config.yaml (Configuration of the network function)
└── values.yaml (Parent file contains all the configurable parameters)
```

## Parameters

[Values.yaml](./values.yaml) contains all the configurable parameters. Below table defines the configurable parameters. 



|Parameter                    |Allowed Values                 |Remark                                   |
|-----------------------------|-------------------------------|-----------------------------------------|
|kubernetesDistribution       |Vanilla/Openshift              |Vanilla Kubernetes or Openshift          |
|trafficServer.repository     |Image Name                     |                                         |
|trafficServer.version        |Image tag                      |                                         |
|trafficServer.pullPolicy     |IfNotPresent or Never or Always|                                         |
|imagePullSecrets.name        |String                         |Good to use for docker hub               |
|serviceAccount.create        |true/false                     |                                         |
|serviceAccount.annotations   |String                         |                                         |
|serviceAccount.name          |String                         |                                         |
|podSecurityContext.runAsUser |Integer (0,65534)              |Mandatory to use 0                       |
|podSecurityContext.runAsGroup|Integer (0,65534)              |Mandatory to use 0                       |
|multus.create                |true/false                     |default false                            |
|multus.ipAdd                 |IPV4                           |NA                                       |
|multus.netmask               |netmask                        |NA                                       |
|multus.gateway(optional)     |netmask                        |NA                                       |
|multus.defaultGateway        |IPV4                           |Default route inside container (optional)|
|multus.hostInterface         |HostInterface Name             |NA                                       |                             |


## Advanced Debugging Parameters

Only needed if you are doing advanced debugging


|Parameter                    |Allowed Values          |Remark                   |
|-----------------------------|------------------------|-------------------------|
|config.ueroute               |Any                     |ue subnet                |
|config.upfHost               |UPF ip-address or fqdn  |                         |
|config.noOfIperf3Server      |number of iperf3 servers|                         |
|resources.define             |true/false              |default false            |
|resources.limits.cpu         |string                  |Unit m for milicpu or cpu|
|resources.limits.memory      |string                  |Unit Mi/Gi/MB/GB         |
|resources.requests.cpu       |string                  |Unit m for milicpu or cpu|
|resources.requests.memory    |string                  |Unit Mi/Gi/MB/GB         |
|readinessProbe               |true/false              |default true             |
|livenessProbe                |true/false              |default false            |
|terminationGracePeriodSeconds|5                       |In seconds (default 5)   |
|nodeSelector                 |Node label              |                         |
|nodeName                     |Node Name               |                         |

