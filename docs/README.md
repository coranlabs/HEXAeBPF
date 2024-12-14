<p align="center">
  <a href="https://github.com/coranlabs/HEXAeBPF"><img src="./images/HEXAeBPF_logo.png" width="200" title="HEXAeBPF"></a>
</p>
<h1 align="left">HEXAeBPF: The Future of Interoperable 5G Core Solutions</h1>
<p align="left">
<img src="https://img.shields.io/badge/HEXAeBPF-v2.0-silver" />
<a href="#license"><img src="https://img.shields.io/badge/License-Apache--2.0-blue"/></a>
<img src="https://img.shields.io/badge/eBPF-yellow" />
<img src="https://img.shields.io/badge/5G-Core-green" />
</p>

**HEXAeBPF** is an innovative Kubernetes (k8s) operator designed to revolutionize the deployment and management of open-source 5G core networks. By acting as an intermediary, HEXAeBPF allows seamless integration and interoperability between any 5G core control plane (CP) and user plane (UP). This project aims to simplify and accelerate the deployment of 5G core networks with one-click customization and end-to-end delivery, leveraging Kubernetes Custom Resource Definitions (CRDs) for optimal flexibility and automation.

## Key Features

**Custom Resource Definitions (CRDs):** HEXAeBPF utilizes Kubernetes CRDs to define and manage CP and UP configurations, allowing users to specify desired states and automate the deployment process.

**Automated Lifecycle Management:** The operator continuously monitors the 5G core components, ensuring that the actual state aligns with the desired state. It automates tasks such as scaling, updates, and self-healing, reducing manual intervention.

**Interoperability:** HEXAeBPF’s modular design supports integration with various open-source CP and UP implementations, providing flexibility in building customized 5G core networks.

**One-Click Deployment:** Users can deploy their chosen CP and UP components with a single command, simplifying the setup of complex 5G core architectures.

## Advantages of HEXAeBPF

**Enhanced Interoperability:** HEXAeBPF bridges the gap between control plane and user plane solutions, enabling multi-vendor integration.

**Reduced Complexity:** Kubernetes operators abstract away the complexities of deployment and management, allowing developers to focus on innovation.

**Efficiency and Speed:** One-click deployments drastically reduce setup time, enabling faster iteration and deployment cycles.

**Future-Ready:** HEXAeBPF aligns with 5G’s modular and dynamic nature, making it a perfect fit for modern network demands.

**Open Source Collaboration:** Foster a community-driven approach to innovation in 5G core development and deployment.

**Consistency and Reliability:** The operator ensures consistent deployment and management practices across different environments, enhancing the reliability of 5G services.

## Why HEXAeBPF is Built as a Kubernetes Operator?

HEXAeBPF leverages Kubernetes Operators to deliver an automated, scalable, and flexible solution for deploying and managing 5G core networks. By embedding operational expertise into software, HEXAeBPF simplifies complex tasks like deployment, scaling, and maintenance, making it an ideal choice for integrating Control Plane (CP) and User Plane (UP) components.

### Key Advantages of HEXAeBPF as an Operator

**Automation:** Handles deployment, scaling, self-healing, and updates with minimal user intervention.

**Custom Resource Management:** Uses CRDs to define and manage CP and UP configurations, enabling tailored, error-free deployments.

**Reusability and Scalability:** Supports replicable configurations and seamless scaling for dynamic network demands.

**Consistency Across Environments:** Ensures uniform deployments in development, testing, and production.

## Why HEXAeBPF?

HEXAeBPF simplifies 5G core deployment by abstracting complexity and enabling one-click integration of CP and UP components. As a Kubernetes Operator, it ensures interoperability, flexibility, and reliability, offering a future-proof solution for the ever-evolving telecom industry.


## Getting Started with HEXAeBPF

You can deploy HEXAeBPF easily, check out the [Installation Guide](./installation.md) for further proceeding.

## Project Roadmap

<p align="left">
  <a><img src="./images/HEXAeBPF_roadmap_summary.png" width="800" title="HEXAeBPF_roadmap_summary"></a>
</p>

## Integration with open source eBPF tools

Integration of varied eBPF-based tools for advanced capabilities in a 5G environment:

- [ ] **L3AF**: A project under the LFN, integrated to manage the lifecycle of multiple eBPF programs within the kernel
- [ ] **pwru**: A project under Cilium, utilized for sophisticated filtering capabilities and aiding in precise network diagnostics space (e.g. XDP Hook)
- [ ] **LoxiLB**: A hyperscale software load balancer designed to balance the cloud-native workload of the 5G ecosystem
- [ ] **Coroot**: An observability tool that converts telemetry data into actionable insights, enabling quick identification and resolution of Network Functions (NF) component issues
- [ ] **Caretta**: A Kubernetes service map tool that traces network traffic between pods and visualizes the network traffic between services in a Kubernetes cluster, providing additional insights into network traffic between NFs
- [ ] **Hubble**: Another project under Cilium, offering deep visibility into the communication and behavior of network services

## Integration with Cloud Native Ecosystems

- **Canonical Juju-Powered Charmed Implementation**: Charmed HEXAeBPF is a highly scalable and reliable core solution featuring model-driven, declarative cluster management with charmed Kubernetes, ensuring high availability.

- **Nephio-driven infrastructure**: Nephio HEXAeBPF will utilize cloud-native technologies and declarative automation to optimize the deployment, management, and scaling of NFs across multiple sites, ensuring quick deployment and efficient resource use across multi-cloud and edge infrastructures.

## Documentation

- The documentation of HEXAeBPF is available on:
  - [HEXAeBPF Blog](#documentation) ## to be added

## Tutorials

- ##Video to be added


## Community and Support

- **General Discussion** <br>

  - Check out general discussion about HEXAeBPF [here](https://github.com/coranlabs/HEXAeBPF/discussions)

- **Engagements** <br>

  - [Isovalent: eBPF Newsletter](https://isovalent-9197153.hs-sites.com/echo-news-episode-60-ebpf-summit-cfp.-netkit-accelerates-cilium?ecid=ACsprvuHHALebZx_3k5FXlwC8Nn8ZH9tiYizqzc0Xu9pZl6jl7Eagaxhtt9i2GP2EqauBxoRkF_f)
  <!-- - [HEXAeBPF in LFN](https://wiki.lfnetworking.org/plugins/servlet/mobile?contentId=136806595#content/view/136806595) -->

<!-- - **Meetups and Presentation** <br>

  - -->

## License

@ SPDX-License-Identifier: Apache-2.0

@ Copyright 2024 CORAN LABS

This project is under [Apache 2.0](./LICENSE) License

## Code of Conduct

The project has adpoted the [Github Open Source Code of Conduct](./.github/CODE_OF_CONDUCT.md)

## Vision

HEXAeBPF is more than just an operator; it is a cornerstone for building a robust, flexible, and interoperable 5G core. It empowers developers, researchers, and telecom operators to create tailored 5G solutions with ease, fostering a future of seamless connectivity and collaboration in the telecommunications ecosystem.

## Contribute

HEXAeBPF is a community-driven project. We welcome contributions from developers, researchers, and telecom operators to enhance its capabilities and adapt to emerging 5G technologies. 

You can contribute in many ways: report issues, help us reproduce issues, fix bugs, add features, give us advice on GitHub discussion, and so on.

