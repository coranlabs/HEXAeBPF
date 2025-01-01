# Parent Helm Charts for Deploying Basic OAI-5G Core Network

Basic deployment contains

1. OAI-AMF
2. OAI-SMF
3. OAI-NRF
4. OAI-UDR
5. OAI-AUSF
6. OAI-UDM
7. OAI-UPF
8. OAI-LMF
9. MYSQL (Subscriber database)

**Disclaimer**: Starting version 2.0.0 of OAI 5G Core network functions their configuration will be in `config.yaml` and all infrastructure related information including image definition will be in `values.yaml`.

If the gNB is in a different cluster or different subnet than pod subnet. Then you need to make sure AMF and SPGWU/UPF is reachable from the gNB host machine. You can use AMF and UPF multus interface. In SPGWU/UPF `n3Interface` should be able to reach gNB host machine/pod/container.

Once you are sure with the configuration parameters you can deploy these charts following the below steps. 

1. Perform a dependency update whenever you change anything in the sub-charts or if you have recently clone the repository. 

```bash
helm dependency update
```

2. Install the parent charts using

```bash
helm install oai-5g-basic .
```

## Note:

If you want to use `oai-upf` with a single interface then you can enable any one out of three interfaces. Lets say we enable `multus.n3Interface.create`. Then change the below configuration parameters 

```
    n3If: "n3"   # n3 if multus.n3Interface.create is true
    n4If: "eth0" # n4 if multus.n4Interface.create is true
    n6If: "eth0"  # n6 multus.n6Interface.create is true
```

Make sure `n3` subnet is reachable from gNB. 
