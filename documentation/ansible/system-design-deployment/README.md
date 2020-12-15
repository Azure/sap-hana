# SAP System Design and Deployment

This document outlines a process that enables a SAP Basis System Administrator to produce repeatable baseline [SAP system landscapes](https://help.sap.com/doc/saphelp_afs64/6.4/en-US/de/6b0d84f34d11d3a6510000e835363f/content.htm) running in Azure.
The repeatability applies both across different SAP products _and_ over time, as new SAP software versions are released.
For example, an administrator may have a requirement to deploy a consistent [3-tier system landscape](https://help.sap.com/doc/saphelp_afs64/6.4/en-US/de/6b0da2f34d11d3a6510000e835363f/content.htm?no_cache=true) for S/4HANA 1909 SPS02 over the course of a few months, where Production is not required until 2-3 months after the Development system is required.
This can be a challenge when SAP removes available software versions, or a customer’s technical SAP personnel changes over time.

The process is aimed at users with some prior experience of both deploying SAP systems and with the Azure cloud platform.
For example, users should be familiar with: _SAP Launchpad_, _SAP Maintenance Planner_, _SAP Download Manager_, and _Azure Portal_.

The process is split between SAP HANA and SAP Application to promote modularity and reuse in the overall SAP journey.
The SAP HANA Database deployment materials obtained by following the SAP HANA process is likely to be reused by more than one SAP Application deployment - both for different versions of the same product, and different products.

In turn, these two processes both consist of 3 distinct phases:

1. **_Acquisition_** of the SAP installation media, configuration files and tools;
1. **_Preparation_** of the SAP media library, and generation of the _Bill of Materials_ (BoM);
1. **_Deployment_** of the SAP landscape into Azure.

**Notes:**

- To prevent unecessary duplication with the Acquisition phase, the installation media and tools for all systems are stored in a single flat directory.
- To keep the SAP Application and SAP HANA proccesses modular, the SAP Application BoM contains a (nested) reference to a SAP HANA BoM, allowing them to be updated and used independently.

Two other phases are involved in the overall end-to-end lifecycle, but these are described elsewhere:

- **_Bootstrapping_** to deploy and configure the SAP Deployer and the SAP Library must be completed before _Preparation_;
- **_Provisioning_** to deploy the SAP target VMs into Azure must be completed before _Deployment_.

## Process Index

### Database

#### SAP HANA

1. **Acquisition**
   1. [Acquire Media](./hana/acquire-media.md)
1. **Preparation**

   :hand: The Preparation phase for SAP HANA should only be completed once for each version of SAP HANA used.
   Once the installation media, Bill of Materials, and installation template are uploaded to the SAP Library proceed with the **SAP Application** documentation.

   1. [Prepare Media](./hana/prepare-sap-library.md)
   1. [Prepare Bill of Materials](./hana/prepare-bom.md)
   1. [Modify Existing Deployment Process](./interim-playbook-preparation.md)
   1. [Prepare Installation Template](./hana/prepare-ini.md)

### SAP Application

1. **Prepare System**:
   1. [Prepare System](./app/prepare-system.md)
1. **Acquisition**
   1. [Acquire Media](./app/acquire-media.md)
1. **Preparation**

   :hand: The Preparation phase for the SAP Application should only be completed once for each version of the specific SAP product used, e.g. S/4HANA 2020 ISS. Once the installation media, Bill of Materials, and installation template for that product/version are uploaded to the SAP Library proceed with the **Deployment** documentation.

   1. [Prepare Media](./app/prepare-sap-library.md)
   1. [Prepare Bill of Materials](./app/prepare-bom.md)
   1. [Prepare Installation Template](./app/prepare-ini.md)

### Deployment

1. [Modify Existing Deployment Process](./interim-playbook-preparation.md)
1. [Deploy SAP HANA SID](./hana/deploy-sid.md)
1. [Deploy SAP Application SID](./app/deploy-sid.md)
