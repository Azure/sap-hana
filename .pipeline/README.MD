# Azure Pipeline Test

## Backgound
The purpose to automate test in azure pipeline is to make PR review process easier.
We separate the test into two types to reduce failure points as well as runtime for PR checks.

## Principle
- **unit test**: executed for PR against feature/* -> more agile, verify the impact of the PR by comparing result before/after the PR code change.
- **integration test**: executed for PR against master and beta -> takes longer, verify the code change E2E.
- **release pipeline**: CI trigger against master and beta -> takes longer, to re-create persist resources used in unit test.

## Tests Included
https://dev.azure.com/azurecat-sapdeploy/sap_deployment_automation/_build

### Teraform Unit Test
- tf-deployer-test.yml
- tf-saplandscape-test.yml
- tf-saplib-test.yml
- tf-sapsystem-anydb-test.yml
- tf-sapsystem-test.yml

### Integration Test
- tf-integration-test.yml

### Release Pipeline
- tf-release.yml

### Ansible Test
- ansible-test.yml

## Additional Notes
1. Shared SSH key pair among all pipelines (this is to make it possible to access persist resources).
1. Set terraform output to sensitive so it does not show in the log.
1. Persist resources and naming (following naming convention document)
    - deployer (rg: `UNIT-EAUS-DEP00-INFRASTRUCTURE`)
    - SAP library (rg: `UNIT-EAUS-SAP_LIBRARY`)
    - SAP landscapes  (rg: `UNIT-EAUS-SAP0-INFRASTRUCTURE`)
    - SAP systems (rg: `SLES/RHEL-EAUS-SAP-PRD`)
1. Disposable resources naming
    - deployer (rg: `<buildId>-EAUS-DEP00-INFRASTRUCTURE`)
    - sap library (rg: `<buildId>-EAUS-SAP_LIBRARY`)
    - sap landscape/system (rg: `<buildId>-EAUS-SAP-PRD`)
