This repository contains terraform templates to install a single node HANA instance

 The different pieces of infrastructure are split into modules.  If you would like to use a single node deployment, terraform will need to be run from the ` experiment/modules/single_node_hana` directory.  To create the infrastructure for the HA pair, terraform will be run from the `experiment/modules/ha_pair` directory.  This will allow us to have new modules for each configuration of the HANA database. Currently, both of the databases, `db0` and `db1` have HANA installed, but are not configured in an HA pair.  This configuration will happen in an upcoming PR with the Ansible plays.