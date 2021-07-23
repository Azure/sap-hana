### <img src="../../../assets/images/UnicornSAPBlack256x256.png" width="64px"> SAP Deployment Automation Framework <!-- omit in toc -->
<br/><br/>

# Deployment Workshop <!-- omit in toc -->

<br/>

## Table of contents <!-- omit in toc -->

- [Steps](#steps)
- [Overview](#overview)
- [Close Up](#close-up)
- [Deployer](#deployer)
- [SAP Library](#sap-library)
- [SAP Workload VNET](#sap-workload-vnet)
- [SDU](#sdu)

<br/><br/>

## Steps
1. [SPN Creation](01-spn.md)
2. [Prepare Environment](02-prepare-environment.md)
3. [Deploy SAP Workload Zone](03-workload-zone.md)
4. [Deploy SDU](04-sdu.md)

<br/>

---

<br/>

## Overview
![Overview](assets/BlockOverview.png)

Environment
- Subscription
- Deployer
- SAP Library (1 or more regionally distributed)
- SAP Workload VNET (Harbor - Global and/or Logical Partitioning within region)
- SDU - SAP Deployment Unit (Deploys into SAP Workload VNET)

## Close Up
![Block1](assets/Block1.png)


## Deployer
![Block2](assets/Block2.png)


## SAP Library
![Block3](assets/Block3.png)


## SAP Workload VNET
![Block4](assets/Block4.png)


## SDU
![Block5a](assets/Block5a.png)
![Block5b](assets/Block5b.png)

<br/><br/><br/><br/>


# Next: [Prepare the region](02-prepare-environment.md) <!-- omit in toc -->
