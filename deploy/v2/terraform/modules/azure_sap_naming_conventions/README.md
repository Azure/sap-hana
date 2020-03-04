# Terraform Module: Azure SAP Naming Conventions

This module allows separation of concerns in keeping any naming convention
implementation separate from the architectural design in a SAP system. It
allows the customer/user the ability to extend and modify how their SAP Azure
resources are named with minimal (ideally no) changes to the more complex
infrastructure definitions.

## Usage

First call the module and pass in the main component name (e.g. `hdb` for all
things relating to HANA):

```
module "hana_resource_names" {
  source = "../azure_sap_naming_conventions"
  name   = "hdb"
}
```

The result is an object that can be used to reference all the names for related
resources, configured to that particular resource type. For example:

| Reference                          | Value                                  |
+------------------------------------+----------------------------------------+
| `module.hana_resource_names.rg`    | `PRD-EAUS-VNT-INFRASTRUCTURE`          |
| `module.hana_resource_names.lb`    | `PRD-EAUS-VNT-DEV0-S4-Z00-hdb-alb`     |

## Extension and Modification

- Add simple naming rules just by adding new entries to `output.tf`.
- Add more complex naming rules by adding new module calls to `main.tf` and
  referencing them in the `output.tf` entries.
