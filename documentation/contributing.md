### <img src="documentation/assets/UnicornSAPBlack256x256.png" width="64px"> SAP Automation > V1.0.0 <!-- omit in toc -->
# Contributing Guidelines <!-- omit in toc -->

Master Branch's status: [![Build Status](https://dev.azure.com/azuresaphana/Azure-SAP-HANA/_apis/build/status/Azure.sap-hana?branchName=master&api-version=5.1-preview.1)](https://dev.azure.com/azuresaphana/Azure-SAP-HANA/_build/latest?definitionId=6&branchName=master)

<br>

Thanks for taking the time to contribute!

This document summarizes the deployment principles which govern our project.

<br>

## Building "in the Open"
* Our users appreciate the transparency of our project; in this context, building "in the open" means that anyone can:
  * see the individual pull requests this solution is comprised of;
  * understand particular changes by going back and forth between pull requests;
  * submit pull requests with their own changes.
* In addition, we use open-source software (OSS) tools rather than proprietrary technology to build the solution.

<br>

## Fully Maintained
* Rather than providing a loose collection of scripts that are never updated, we fully maintain our project.
* We strive to provide a high-quality solution by:
  * continuously deploying it using an internal runner to ensure performance and stability;
  * detecting regressions introduced by code changes before merging them.

<br>

## Execution-focused
* We don't just work on some grand plan that may or never be completely executed;
  * instead, we start building out the solution and iterate towards a grand plan.

<br>

## Coding Guidelines
* Test
  * This repository integrates with [Azure Pipelines](https://azure.microsoft.com/en-us/services/devops/pipelines/), which invokes build checks on the submitted pull requests. The pipeline runs the tests on the merge branch. The pull request is required to pass the Azure pipelines test before it can be merged.
* Branch Policy
  * The contributor needs to create a branch in the main repo so that the integrated Azure pipelines can test the submitted pull request.
  
