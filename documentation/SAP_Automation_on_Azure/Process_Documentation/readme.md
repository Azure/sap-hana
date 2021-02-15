# Process overview #

This document describes the overall process flow and the design activities needed to prepare and deploy an SAP estate to Azure.

## Architectural overview ##

[SAP Estate](./assets/SAP_estate.jpg)

## Preparing the environment ##

Before we can deploy the SAP Systems to Azure we need to prepare the environments in Azure that they will be deployed to.

## Technical details needed before starting the SAP infrastructure deployment ##

the following information should be available before starting the deployment

## Customizing the deployment ##

It is possible to customize some of the deployment aspects. 

### Changing the naming convention ###

The automation uses a default naming convention which is defined in the Standard naming conventin document [standards-naming.md](.//Software_Documentation/standards-naming.md)

It is possible to implement a customer specific naming convention, for more details see [Changing_the_naming_convention.md](./Changing_the_naming_convention.md)

Using marketplace images or custom images

### Changing disk sizing ###

 [Using_custom_disk_sizing.md](./Using_custom_disk_sizing.md)
