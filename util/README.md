### <img src="../documentation/assets/UnicornSAPBlack256x256.png" width="64px"> SAP Automation > V1.0.0 <!-- omit in toc -->
# Utility Scripts <!-- omit in toc -->

Master Branch's status: [![Build Status](https://dev.azure.com/azuresaphana/Azure-SAP-HANA/_apis/build/status/Azure.sap-hana?branchName=master&api-version=5.1-preview.1)](https://dev.azure.com/azuresaphana/Azure-SAP-HANA/_build/latest?definitionId=6&branchName=master)

<br>

This directory contains some simple bash scripts that aid usage of the main codebase.
The scripts are intended to be run on the user's workstation, and not on the machines deployed in Azure.
The scripts should be run as and when directed as part of [the main usage guide](../deploy/USAGE.md).

All scripts have been tested with [`shellcheck`](https://www.shellcheck.net/) v0.7.0.

From the project root directory, run the following to check all scripts: `shellcheck util/*.sh`
