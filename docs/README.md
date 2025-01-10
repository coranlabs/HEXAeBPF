
# **HEXAeBPF: The Future of Interoperable 5G Core Solutions**
*Empowering the next generation of 5G core deployments with simplicity, interoperability, and automation.*

---

## **Introduction**
HEXAeBPF is a Kubernetes (K8s) Operator designed to redefine how open-source 5G core networks are deployed and managed. By integrating and automating the deployment of Control Plane (CP) from Vendor A and eBPF-based User Plane (UP) from Vendor B, HEXAeBPF enables seamless, end-to-end 5G lab setups with minimal effort.
Whether you're a telecom researcher, developer, or operator, HEXAeBPF simplifies deployment processes, fosters interoperability, and accelerates the evolution of 5G core networks.

---

## **Key Features**
- **Interoperable 5G Core Solution:** Integrates CP from one vendor with UP from another, offering unparalleled flexibility.
- **Zero Effort Deployment:** Automates deployment with no prior technical knowledge required.
- **One-Click Deployment (OCD):** A single command sets up the entire 5G core solution.
- **Interactive CLI:** User-friendly terminal interface for configuration and management.
- **E2E Connectivity:** Full integration with RAN simulators for end-to-end testing.
- **Open Source Accessibility:** Promotes collaboration and innovation in the telecom industry.

---

## **Advantages**
1. **Interoperability:** Modular design allows seamless integration between various open-source CP and eUP components.
2. **Efficiency and Speed:** eBPF-based UPF optimizes performance, while one-click deployment drastically reduces setup time.
3. **Future-Ready:** Aligns with the dynamic nature of 5G, ensuring adaptability to modern network demands.
4. **Open Source Collaboration:** A community-driven approach fosters continuous innovation in 5G core solutions.

---

## **Why HEXAeBPF is Built as a Kubernetes Operator?**
Kubernetes Operators are ideal for automated, scalable, and flexible management. HEXAeBPF leverages this technology to provide:
- **Custom Resource Definitions (CRDs):** Simplified configuration of CP and eUP components.
- **Automated Lifecycle Management:** Handles scaling, updates, and self-healing tasks seamlessly.
- **Consistency and Reliability:** Ensures uniform deployment and management across diverse environments.
- **Reduced Complexity:** Abstracts complex networking and configuration challenges.

---

## **How HEXAeBPF Works**
1.	Choose your desired Control Plane.
2.	Select a compatible eBPF-based User Plane that works seamlessly with your chosen Control Plane.
3.	Pick the supported RAN Simulator for end-to-end testing.
4.	Tada! That’s all you need to do—your E2E deployment will be ready within minutes!

---

## **Deployment**
Simplified deployment is the cornerstone of HEXAeBPF. Use the following command for an interactive CLI experience:

```bash
make run_hexaebpf
```

*CLI Demo:*

<div align="left">
  <img src="./images/hexaebpf_cli_demo.gif" alt="HEXAeBPF CLI Demo" width="600" height="400">
</div>

---

## **Supported Topologies**
### **Combined Phases**
| Control Plane       | User Plane           | RAN Simulator  |
|---------------------|----------------------|----------------|
| SD Core             | edgecomllc/eUPF     | UERANSIM       |
| Free5gc             | edgecomllc/eUPF     | UERANSIM       |
| Open5GS             | edgecomllc/eUPF     | UERANSIM       |
| OAI                 | OAI-UPF-eBPF        | OAI-RFSimulator|
| SD Core             | OAI-UPF-eBPF        | UERANSIM       |
| Free5gc             | OAI-UPF-eBPF        | UERANSIM       |
| Open5GS             | OAI-UPF-eBPF        | UERANSIM       |
| OAI                 | edgecomllc/eUPF     | OAI-RFSimulator|
| SD Core             | e3-UPF              | UERANSIM       |
| Free5gc             | e3-UPF              | UERANSIM       |
| Open5GS             | e3-UPF              | UERANSIM       |
| OAI                 | e3-UPF              | UERANSIM       |

---

## **Vision**
HEXAeBPF is more than an operator; it's a gateway to:
- **Flexible 5G Core Design:** Empower users to build custom CP and UP solutions effortlessly.
- **Industry Innovation:** Promote 5G awareness and adoption in labs and enterprises.
- **Future Connectivity:** Foster collaboration and open-source development in 5G telecom ecosystems.

---

## **Contribute**
HEXAeBPF is a community-driven project, and your contributions are welcome! Whether you’re a developer, researcher, or network operator, join us in shaping the future of 5G core networks.

### **How to Contribute**
1. Fork the repository.
2. Create a new branch for your feature/bugfix.
3. Submit a pull request with detailed information about your changes.

---

## **Tutorial and Documentation**
- **Coming in Future Releases:**
  <!-- - HEXAeBPF blog for tutorials and updates.
  - Video demonstrations for hexa operator functionalities. -->

---

## **License**
This project is licensed under **AGPL-3.0 License**. See [LICENSE](../LICENSE.md) for more details.

### Licensing Notice
HEXAeBPF integrates the following open-source components:
- Open5GS (AGPL-3.0): Requires HEXAeBPF to comply with AGPL-3.0.
- Free5GC, eupf, SD-Core (Apache 2.0): These components impose permissive conditions.
- OAI (OAI Public License v1.1): Limited to research/study unless separately negotiated.

Users must ensure compliance with these licenses when using HEXAeBPF. Check [here](./THIRD_PARTY_LICENSES.md) to know more.

---

## **Code of Conduct**
HEXAeBPF adheres to the [GitHub Open Source Code of Conduct](../.github/CODE_OF_CONDUCT.md). By contributing, you agree to uphold this standard.
