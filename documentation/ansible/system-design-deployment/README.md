# SAP System Design and Deployment

This document outlines a process that enables a SAP Basis System Administrator to produce repeatable baseline [SAP system landscapes](https://help.sap.com/doc/saphelp_afs64/6.4/en-US/de/6b0d84f34d11d3a6510000e835363f/content.htm) running in Azure.
The repeatability applies both across different SAP products _and_ over time, as new SAP software versions are released.
For example, an administrator may have a requirement to deploy a consistent [3-tier system landscape](https://help.sap.com/doc/saphelp_afs64/6.4/en-US/de/6b0da2f34d11d3a6510000e835363f/content.htm?no_cache=true) for S/4HANA 1909 SPS02 over the course of a few months, where Production is not required until 2-3 months after the Development system is required.
This can be a challenge when SAP removes available software versions, or a customer’s technical SAP personnel changes over time.

The process is aimed at users with some prior experience of both deploying SAP systems and with the Azure cloud platform.
For example, users should be familiar with: _SAP Launchpad_, _SAP Maintenance Planner_, _SAP Download Manager_, and _Azure Portal_.

The process described here consists of 3 distinct phases:

1. **_Acquisition_** of the SAP installation media, configuration files and tools;
1. **_Preparation_** of the SAP media library, and generation of the files required for automated deployments;
1. **_Deployment_** of the SAP landscape into Azure.

Two other phases are involved in the overall end-to-end lifecycle, but these are described elsewhere:

- **_Bootstrapping_** to deploy and configure the SAP Deployer and the SAP Library must be completed before _Preparation_;
- **_Provisioning_** to deploy the SAP target VMs into Azure must be completed before _Deployment_.

## Process Index

### SAP HANA

1. **Acquisition**
   1. [Acquisition of Media](./hana/acquire-media.md)
1. **Preparation**
   1. [Upload of Installation Media](./hana/prepare-sap-library.md)
   1. [Generate Installation Templates](./hana/prepare-ini.md)
   1. [Generate Bill of Materials](./hana/prepare-bom.md)
1. **Deployment**
   1. [Deploy SAP HANA SID](./hana/deploy-sid.md)

### SAP Application

1. **Acquisition**
   1. [Acquisition of Media](./app/acquire-media.md)
1. **Preparation**
   1. [Upload of Installation Media](./app/prepare-sap-library.md)
   1. [Generate Installation Templates](./app/prepare-ini.md)
   1. [Generate Bill of Materials](./app/prepare-bom.md)
1. **Deployment**
   1. [Deploy SAP HANA SID](./app/deploy-sid.md)

## Notes

The SAP HANA and SAP Application processes have been separated, because in the overall SAP journey, a set of the SAP HANA Database deployment materials obtained by following the SAP HANA process is likely to be reused by more than one SAP Application, e.g. S/4HANA, BW/4HANA, etc.

The Application Bill of Materials (BoM) will contain a reference to a SAP HANA BoM. This allows the process for the Application BoM generation and deployment to be completed separately, and multiple times without requiring the generation of a new SAP HANA BoM.
