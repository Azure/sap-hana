# BoM Validation

Much of the successful deployment of a SAP Application relies on a correctly structured BoM (Bill of Materials). It's time-consuming and error-prone to ensure that the content of a BoM conforms to all the requirements as described in the above documentation. Fortunately, a simple check can be performed, which validates most of the requirments for structure and content.

## Prerequisites

1. The check may be run on your workstation or on the deployer (RTI), as long it has a copy of the BoM needing to be checked.
1. You will require the `yamllint` and `ansible-lint` commands to be installed. If these are not present, the script will remind you and will run without linting checks.
1. You may use the supplied [example](examples/) BoM files to familiarize yourself with the process.

## Execution

Switch to the `util` directory and execute the `check_bom.sh` passing the full location of the BoM file to be tested. Examples:

1. `./check_bom.sh ../documentation/ansible/system-design-deployment/examples/S4HANA_2020_ISS_v001/bom.yml`

   Output looks like (no errors reported):

     ```text
     ... yamllint [ok]
     ... ansible-lint [ok]
     ... bom structure [ok]
     ```

1. `./check_bom.sh ../documentation/ansible/system-design-deployment/examples/S4HANA_2020_ISS_v001/bom_with_errors.yml`

   Output looks like (errors reported):

     ```text
     ../documentation/ansible/system-design-deployment/examples/S4HANA_2020_ISS_v001/bom_with_errors.yml
       178:16    error    too many spaces after colon  (colons)
       179:16    error    too many spaces after colon  (colons)
       180:16    error    too many spaces after colon  (colons)

     ... yamllint [errors]
     ... ansible-lint [ok]
       - Expected to find key 'defaults' in 'bom' (Check name: S4HANA_2020_ISS_v001)
       - Unexpected key 'default in 'bom' (Check name: S4HANA_2020_ISS_v001)
       - Unexpected key 'overide_target_location in 'bom.materials.stackfiles' (Check name: Download Basket Stack text)
     ... bom structure [errors]
     ```
