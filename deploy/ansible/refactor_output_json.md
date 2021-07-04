Output.JSON Depracation


REDUCED
```json
{                                                                 -------
  "databases":[                                                   -------
    {                                                             -------
      "authentication":{                                          -------
        "password":"hdb_vm_password",                             ?
        "type":"key",                                             ?
        "username":"azureadm"                                     ?
      },                                                          -------
      "credentials":{                                             -------
        "cockpit_admin_password":"cockpit_admin_password",        ANSIBLE                       password_cockpit_admin
        "db_systemdb_password":"db_systemdb_password",            ANSIBLE                       password_db_systemdb
        "ha_cluster_password":"ha_cluster_password",              ANSIBLE                       password_ha_db_cluster
        "os_sapadm_password":"os_sapadm_password",                ANSIBLE                       password_os_sapadm
        "os_sidadm_password":"os_sidadm_password",                ANSIBLE                       password_os_sidadm
        "xsa_admin_password":"xsa_admin_password"                 ANSIBLE                       password_db_xsa_admin
      },                                                          -------
      "db_version":"2.00.050",                                    DEPRECATE
      "filesystem":"xfs",                                         DEPRECATE
      "high_availability":false,                                  ?
      "instance":{                                                -------
        "instance_number":"01",                                   ?
        "sid":"X00"                                               ANSIBLE                       sap_sid
      },                                                          -------
      "loadbalancer":{                                            -------
        "frontend_ip":"10.1.1.4"                                  ?
      },                                                          -------
      "nodes":[                                                   -------
        {                                                         -------
          "dbname":"x00dhdb00l0373",                              INVENTORY
          "ip_admin_nic":"10.1.1.74",                             INVENTORY
          "ip_db_nic":"10.1.1.10",                                ANSIBLE DISCOVERABLE
          "role":"worker"                                         ?
        }                                                         -------
      ],                                                          -------
      "os":{                                                      -------
        "offer":"sles-sap-12-sp5",                                ANSIBLE DISCOVERABLE
        "publisher":"SUSE",                                       ANSIBLE DISCOVERABLE
        "sku":"gen1",                                             DEPRECATE
        "source_image_id":""                                      DEPRECATE
      },                                                          -------
      "platform":"HANA",                                          ANSIBLE
      "size":"Demo",                                              ANSIBLE
      "xsa":{                                                     -------
        "routing":"ports"                                         ?
      }                                                           -------
    }                                                             -------
  ],                                                              -------
  "infrastructure":{                                              -------
    "iscsi":{                                                     -------
      "iscsi_nic_ips":[[]]                                        INVENTORY
    }                                                             -------
  },                                                              -------
  "options":{                                                     -------
    "enable_prometheus":true,                                     ANSIBLE
    "enable_secure_transfer":true                                 ?
  },                                                              -------
  "software":{                                                    -------
    "storage_account_sapbits":{                                   -------
      "blob_container_name":"",                                   ?
      "name":"",                                                  ?
      "storage_access_key":""                                     ?
    }                                                             -------
  }                                                               -------
}                                                                 -------
```




ORIGINAL
```json
{                                                                 -------
  "databases":[                                                   -------
    {                                                             -------
      "authentication":{                                          -------
        "password":"hdb_vm_password",                             ?
        "type":"key",                                             ?
        "username":"azureadm"                                     ?
      },                                                          -------
      "components":{                                              -------
        "hana_database":[]                                        DEPRECATE
      },                                                          -------
      "credentials":{                                             -------
        "cockpit_admin_password":"cockpit_admin_password",        ANSIBLE                       password_cockpit_admin
        "db_systemdb_password":"db_systemdb_password",            ANSIBLE                       password_db_systemdb
        "ha_cluster_password":"ha_cluster_password",              ANSIBLE                       password_ha_db_cluster
        "os_sapadm_password":"os_sapadm_password",                ANSIBLE                       password_os_sapadm
        "os_sidadm_password":"os_sidadm_password",                ANSIBLE                       password_os_sidadm
        "xsa_admin_password":"xsa_admin_password"                 ANSIBLE                       password_db_xsa_admin
      },                                                          -------
      "db_version":"2.00.050",                                    DEPRECATE
      "filesystem":"xfs",                                         DEPRECATE
      "high_availability":false,                                  ?
      "instance":{                                                -------
        "instance_number":"01",                                   ?
        "sid":"X00"                                               ANSIBLE                       sap_sid
      },                                                          -------
      "loadbalancer":{                                            -------
        "frontend_ip":"10.1.1.4"                                  ?
      },                                                          -------
      "nodes":[                                                   -------
        {                                                         -------
          "dbname":"x00dhdb00l0373",                              INVENTORY
          "ip_admin_nic":"10.1.1.74",                             INVENTORY
          "ip_db_nic":"10.1.1.10",                                ANSIBLE DISCOVERABLE
          "role":"worker"                                         ?
        }                                                         -------
      ],                                                          -------
      "os":{                                                      -------
        "offer":"sles-sap-12-sp5",                                ANSIBLE DISCOVERABLE
        "publisher":"SUSE",                                       ANSIBLE DISCOVERABLE
        "sku":"gen1",                                             DEPRECATE
        "source_image_id":""                                      DEPRECATE
      },                                                          -------
      "platform":"HANA",                                          ANSIBLE
      "shine":{                                                   DEPRECATE
        "email":"shinedemo@microsoft.com"                         DEPRECATE
      },                                                          DEPRECATE
      "size":"Demo",                                              ANSIBLE
      "xsa":{                                                     -------
        "routing":"ports"                                         ?
      }                                                           -------
    }                                                             -------
  ],                                                              -------
  "infrastructure":{                                              -------
    "iscsi":{                                                     -------
      "iscsi_nic_ips":[[]]                                        INVENTORY
    },                                                            -------
    "ppg":{                                                       -------
      "arm_id":[],                                                DEPRECATE
      "is_existing":false,                                        DEPRECATE
      "name":["NP-EUS2-SAP-X00-ppg"]                              DEPRECATE
    },                                                            -------
    "resource_group":{                                            -------
      "arm_id":"",                                                DEPRECATE
      "is_existing":false,                                        DEPRECATE
      "name":"NP-EUS2-SAP-X00"                                    DEPRECATE
    },                                                            -------
    "vnets":{                                                     -------
      "sap":{                                                     -------
        "subnet_admin":{                                          -------
          "arm_id":"",                                            DEPRECATE
          "is_existing":false,                                    DEPRECATE
          "name":"NP-EUS2-SAP-X00_admin-subnet",                  DEPRECATE
          "nsg":{                                                 -------
            "arm_id":"",                                          DEPRECATE
            "is_existing":false,                                  DEPRECATE
            "name":"NP-EUS2-SAP-X00_adminSubnet-nsg"              DEPRECATE
          },                                                      -------
          "prefix":"10.1.1.64/27"                                 DEPRECATE
        },                                                        -------
        "subnet_app":{                                            -------
          "arm_id":"",                                            DEPRECATE
          "is_existing":false,                                    DEPRECATE
          "name":"NP-EUS2-SAP-X00_app-subnet",                    DEPRECATE
          "nsg":{                                                 -------
            "arm_id":"",                                          DEPRECATE
            "is_existing":false,                                  DEPRECATE
            "name":"_NP-EUS2-SAP-X00appSubnet-nsg"                DEPRECATE
          },                                                      -------
          "prefix":"10.1.1.32/27"                                 DEPRECATE
        },                                                        -------
        "subnet_db":{                                             -------
          "arm_id":"",                                            DEPRECATE
          "is_existing":false,                                    DEPRECATE
          "name":"NP-EUS2-SAP-X00_db-subnet",                     DEPRECATE
          "nsg":{                                                 -------
            "arm_id":"",                                          DEPRECATE
            "is_existing":false,                                  DEPRECATE
            "name":"NP-EUS2-SAP-X00_dbSubnet-nsg"                 DEPRECATE
          },                                                      -------
          "prefix":"10.1.1.0/28"                                  DEPRECATE
        }                                                         -------
      }                                                           -------
    }                                                             -------
  },                                                              -------
  "options":{                                                     -------
    "ansible_execution":false,                                    DEPRECATE
    "enable_prometheus":true,                                     ANSIBLE
    "enable_secure_transfer":true                                 ?
  },                                                              -------
  "software":{                                                    -------
    "downloader":{                                                -------
      "credentials":{                                             -------
        "sap_password":"sap_smp_password",                        DEPRECATE
        "sap_user":"sap_smp_user"                                 DEPRECATE
      },                                                          -------
      "debug":{                                                   -------
        "cert":"charles.pem",                                     ?
        "enabled":false,                                          ?
        "proxies":{                                               -------
          "http":"http://127.0.0.1:8888",                         ?
          "https":"https://127.0.0.1:8888"                        ?
        }                                                         -------
      },                                                          -------
      "scenarios":[                                               -------
        {                                                         -------
          "components":["PLATFORM"],                              DEPRECATE
          "os_type":"LINUX_X64",                                  DEPRECATE
          "os_version":"SLES12.3",                                DEPRECATE
          "product_name":"HANA",                                  DEPRECATE
          "product_version":"2.0",                                DEPRECATE
          "scenario_type":"DB"                                    DEPRECATE
        },                                                        -------
        {                                                         -------
          "os_type":"LINUX_X64",                                  DEPRECATE
          "product_name":"RTI",                                   DEPRECATE
          "scenario_type":"RTI"                                   DEPRECATE
        },                                                        -------
        {                                                         -------
          "os_type":"NT_X64",                                     DEPRECATE
          "scenario_type":"BASTION"                               DEPRECATE
        },                                                        -------
        {                                                         -------
          "os_type":"LINUX_X64",                                  DEPRECATE
          "scenario_type":"BASTION"                               DEPRECATE
        }                                                         -------
      ]                                                           -------
    },                                                            -------
    "storage_account_sapbits":{                                   -------
      "blob_container_name":"",                                   ?
      "file_share_name":"",                                       DEPRECATE
      "name":"",                                                  ?
      "storage_access_key":""                                     ?
    }                                                             -------
  }                                                               -------
}                                                                 -------
```
