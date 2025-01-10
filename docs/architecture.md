# **HEXAeBPF Architecture**

## **Project Directory Structure**

The HEXAeBPF project is structured as follows:

```plaintext
HEXAeBPF
├── src
│   ├── cli
│   │   ├── hexaebpf_cli.sh              # Basic CLI script for operator mode selection and deployment
│   ├── operators
│   │   ├── HEXAeBPF_Operator
│   │   │   ├── HEXAeBPF-sdcore-eupf-operator
│   │   │   │   ├── hexa-sdcore-eupf-cp-operator
│   │   │   │   └── hexa-sdcore-eupf-up-operator
│   │   │   ├── HEXAeBPF-free5gc-eupf-operator
│   │   │   │   ├── hexa-free5gc-eupf-cp-operator
│   │   │   │   └── hexa-free5gc-eupf-up-operator
│   │   │   ├── HEXAeBPF-open5gs-eupf-operator
│   │   │   │   ├── hexa-open5gs-eupf-cp-operator
│   │   │   │   └── hexa-open5gs-eupf-up-operator
│   │   │   ├── HEXAeBPF-oai-ebpf-operator
│   │   │   |   └── hexa-oai-ebpf-operator
│   │   │   ├── HEXAeBPF-sdcore-oai-upf-ebpf-operator
│   │   │   │   ├── hexa-sdcore-oai-upf-ebpf-cp-operator
│   │   │   │   └── hexa-sdcore-oai-upf-ebpf-up-operator
│   │   │   ├── HEXAeBPF-free5gc-oai-upf-ebpf-operator
│   │   │   │   ├── hexa-free5gc-oai-upf-ebpf-cp-operator
│   │   │   │   └── hexa-free5gc-oai-upf-ebpf-up-operator
│   │   │   ├── HEXAeBPF-open5gs-oai-upf-ebpf-operator
│   │   │   │   ├── hexa-open5gs-oai-upf-ebpf-cp-operator
│   │   │   │   └── hexa-open5gs-oai-upf-ebpf-up-operator
│   │   │   ├── HEXAeBPF-oai-eupf-operator
│   │   │   |   ├── hexa-oai-eupf-cp-operator
│   │   │   |   └── hexa-oai-eupf-up-operator
│   │   │   ├── HEXAeBPF-sdcore-e3-upf-operator
│   │   │   │   ├── hexa-sdcore-e3-upf-cp-operator
│   │   │   │   └── hexa-sdcore-e3-upf-up-operator
│   │   │   ├── HEXAeBPF-free5gc-e3-upf-operator
│   │   │   │   ├── hexa-free5gc-e3-upf-cp-operator
│   │   │   │   └── hexa-free5gc-e3-upf-up-operator
│   │   │   ├── HEXAeBPF-open5gs-e3-upf-operator
│   │   │   │   ├── hexa-open5gs-e3-upf-cp-operator
│   │   │   │   └── hexa-open5gs-e3-upf-up-operator
│   │   │   ├── HEXAeBPF-oai-e3-upf-operator
│   │   │   │   ├── hexa-oai-e3-upf-cp-operator
│   │   │   │   └── hexa-oai-e3-upf-up-operator
│   │   │   ├── HEXAeBPF-ueransim-operator
│   │   │   |   ├── hexa-ueransim-operator
│   │   │   ├── HEXAeBPF-oai-rfsimulator-operator
│   │   │   |   ├── hexa-oai-gnb-operator
│   │   │   |   └── hexa-oai-nr-ue-operator
├── helm_charts
│   ├── HEXA_Helm_Charts.md       # Description of current Helm chart versions
├── docs
│   ├── README.md                 # Detailed project overview
│   ├── THIRD_PARTY_LICENSES.md   # Detailed project overview
│   ├── architecture.md           # Explanation of project architecture
│   ├── images
│   │   ├── cli_demo.gif          # GIF demo of CLI
│   │   └── architecture.png      # Architectural diagrams
├── tests
│   ├── unit                     # Unit tests for individual components
│   ├── integration              # Integration tests
│   └── e2e                      # End-to-end tests
├── examples
│   ├── cr_sample.yaml           # Example Custom Resource definition
│   ├── cp_config_sample.yaml    # Example control plane configuration
│   └── up_config_sample.yaml    # Example user plane configuration
├── Makefile                     # Automates scripts with a single command
└── LICENSE.md                   # License details