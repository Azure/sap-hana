This is a sample hostvars for a single server

```json
{
    "hostvars['x00scs00l373']": {
        "ansible_all_ipv4_addresses": [
            "10.1.1.42"
        ],
        "ansible_all_ipv6_addresses": [
            "fe80::20d:3aff:fe0f:305f"
        ],
        "ansible_apparmor": {
            "status": "enabled"
        },
        "ansible_architecture": "x86_64",
        "ansible_bios_date": "12/07/2018",
        "ansible_bios_version": "090008",
        "ansible_check_mode": false,
        "ansible_cmdline": {
            "BOOT_IMAGE": "/vmlinuz-4.12.14-122.54-default",
            "USE_BY_UUID_DEVICE_NAMES": "1",
            "console": "ttyS0",
            "dis_ucode_ldr": true,
            "earlyprintk": "ttyS0",
            "multipath": "off",
            "net.ifnames": "0",
            "root": "UUID=af42ae91-56c6-4ee1-a8c8-79c68f3bba49",
            "rootdelay": "300",
            "rw": true,
            "scsi_mod.use_blk_mq": "1"
        },
        "ansible_date_time": {
            "date": "2021-01-27",
            "day": "27",
            "epoch": "1611775222",
            "hour": "19",
            "iso8601": "2021-01-27T19:20:22Z",
            "iso8601_basic": "20210127T192022643439",
            "iso8601_basic_short": "20210127T192022",
            "iso8601_micro": "2021-01-27T19:20:22.643553Z",
            "minute": "20",
            "month": "01",
            "second": "22",
            "time": "19:20:22",
            "tz": "UTC",
            "tz_offset": "+0000",
            "weekday": "Wednesday",
            "weekday_number": "3",
            "weeknumber": "04",
            "year": "2021"
        },
        "ansible_default_ipv4": {
            "address": "10.1.1.42",
            "alias": "eth0",
            "broadcast": "10.1.1.63",
            "gateway": "10.1.1.33",
            "interface": "eth0",
            "macaddress": "00:0d:3a:0f:30:5f",
            "mtu": 1500,
            "netmask": "255.255.255.224",
            "network": "10.1.1.32",
            "type": "ether"
        },
        "ansible_default_ipv6": {},
        "ansible_device_links": {
            "ids": {
                "dm-0": [
                    "dm-name-vg_sap-lv_usrsap",
                    "dm-uuid-LVM-2Ae42FOzDAhOWvKky0JTHPwvlyYgzKbQPtObucSTgJWWoM2mLNPsVVvH18vG9wyS"
                ],
                "dm-1": [
                    "dm-name-vg_sap-lv_sapmnt",
                    "dm-uuid-LVM-2Ae42FOzDAhOWvKky0JTHPwvlyYgzKbQFlN4EC3K3xkMZANhBAnel3sIyu32q5fz"
                ],
                "dm-2": [
                    "dm-name-vg_sap-lv_usrsapinstall",
                    "dm-uuid-LVM-2Ae42FOzDAhOWvKky0JTHPwvlyYgzKbQK5MHLUtZ6QVx2A575rxDmtcRvVHDWotw"
                ],
                "sda": [
                    "scsi-14d53465420202020fe5b1c54d09849bd9be69f981cfd7b0b",
                    "scsi-360022480fe5b1c54d0989f981cfd7b0b",
                    "wwn-0x60022480fe5b1c54d0989f981cfd7b0b"
                ],
                "sda1": [
                    "scsi-14d53465420202020fe5b1c54d09849bd9be69f981cfd7b0b-part1",
                    "scsi-360022480fe5b1c54d0989f981cfd7b0b-part1",
                    "wwn-0x60022480fe5b1c54d0989f981cfd7b0b-part1"
                ],
                "sda2": [
                    "scsi-14d53465420202020fe5b1c54d09849bd9be69f981cfd7b0b-part2",
                    "scsi-360022480fe5b1c54d0989f981cfd7b0b-part2",
                    "wwn-0x60022480fe5b1c54d0989f981cfd7b0b-part2"
                ],
                "sda3": [
                    "scsi-14d53465420202020fe5b1c54d09849bd9be69f981cfd7b0b-part3",
                    "scsi-360022480fe5b1c54d0989f981cfd7b0b-part3",
                    "wwn-0x60022480fe5b1c54d0989f981cfd7b0b-part3"
                ],
                "sda4": [
                    "scsi-14d53465420202020fe5b1c54d09849bd9be69f981cfd7b0b-part4",
                    "scsi-360022480fe5b1c54d0989f981cfd7b0b-part4",
                    "wwn-0x60022480fe5b1c54d0989f981cfd7b0b-part4"
                ],
                "sdb": [
                    "scsi-14d53465420202020ddfbf981d2142243a5e5764045eea818",
                    "scsi-360022480ddfbf981d214764045eea818",
                    "wwn-0x60022480ddfbf981d214764045eea818"
                ],
                "sdb1": [
                    "scsi-14d53465420202020ddfbf981d2142243a5e5764045eea818-part1",
                    "scsi-360022480ddfbf981d214764045eea818-part1",
                    "wwn-0x60022480ddfbf981d214764045eea818-part1"
                ],
                "sdc": [
                    "lvm-pv-uuid-JQ4BOw-OeEO-KF7T-cRVV-ezC3-Oszz-3zvo6G",
                    "scsi-14d534654202020200ff9d90a9cf0394c90985bc06941fd43",
                    "scsi-3600224800ff9d90a9cf05bc06941fd43",
                    "wwn-0x600224800ff9d90a9cf05bc06941fd43"
                ],
                "sr0": [
                    "ata-Virtual_CD"
                ]
            },
            "labels": {
                "sda2": [
                    "EFI"
                ],
                "sda3": [
                    "BOOT"
                ],
                "sda4": [
                    "ROOT"
                ]
            },
            "masters": {
                "sdc": [
                    "dm-0",
                    "dm-1",
                    "dm-2"
                ]
            },
            "uuids": {
                "dm-0": [
                    "3e62d488-0fdb-4cb4-9786-9264b551357a"
                ],
                "dm-1": [
                    "dc442871-6ebc-4f8d-8da3-12a7b2e48b4a"
                ],
                "dm-2": [
                    "98b09423-3006-44a1-a2dd-c9f650e2463b"
                ],
                "sda2": [
                    "E7C1-9C93"
                ],
                "sda3": [
                    "b658aa52-6080-43a0-9b17-57fad496a24f"
                ],
                "sda4": [
                    "af42ae91-56c6-4ee1-a8c8-79c68f3bba49"
                ],
                "sdb1": [
                    "d1a3489e-91e6-469d-ad14-0d62d4ae7579"
                ]
            }
        },
        "ansible_devices": {
            "dm-0": {
                "holders": [],
                "host": "",
                "links": {
                    "ids": [
                        "dm-name-vg_sap-lv_usrsap",
                        "dm-uuid-LVM-2Ae42FOzDAhOWvKky0JTHPwvlyYgzKbQPtObucSTgJWWoM2mLNPsVVvH18vG9wyS"
                    ],
                    "labels": [],
                    "masters": [],
                    "uuids": [
                        "3e62d488-0fdb-4cb4-9786-9264b551357a"
                    ]
                },
                "model": null,
                "partitions": {},
                "removable": "0",
                "rotational": "1",
                "sas_address": null,
                "sas_device_handle": null,
                "scheduler_mode": "",
                "sectors": "134217728",
                "sectorsize": "512",
                "size": "64.00 GB",
                "support_discard": "2097152",
                "vendor": null,
                "virtual": 1
            },
            "dm-1": {
                "holders": [],
                "host": "",
                "links": {
                    "ids": [
                        "dm-name-vg_sap-lv_sapmnt",
                        "dm-uuid-LVM-2Ae42FOzDAhOWvKky0JTHPwvlyYgzKbQFlN4EC3K3xkMZANhBAnel3sIyu32q5fz"
                    ],
                    "labels": [],
                    "masters": [],
                    "uuids": [
                        "dc442871-6ebc-4f8d-8da3-12a7b2e48b4a"
                    ]
                },
                "model": null,
                "partitions": {},
                "removable": "0",
                "rotational": "1",
                "sas_address": null,
                "sas_device_handle": null,
                "scheduler_mode": "",
                "sectors": "268435456",
                "sectorsize": "512",
                "size": "128.00 GB",
                "support_discard": "2097152",
                "vendor": null,
                "virtual": 1
            },
            "dm-2": {
                "holders": [],
                "host": "",
                "links": {
                    "ids": [
                        "dm-name-vg_sap-lv_usrsapinstall",
                        "dm-uuid-LVM-2Ae42FOzDAhOWvKky0JTHPwvlyYgzKbQK5MHLUtZ6QVx2A575rxDmtcRvVHDWotw"
                    ],
                    "labels": [],
                    "masters": [],
                    "uuids": [
                        "98b09423-3006-44a1-a2dd-c9f650e2463b"
                    ]
                },
                "model": null,
                "partitions": {},
                "removable": "0",
                "rotational": "1",
                "sas_address": null,
                "sas_device_handle": null,
                "scheduler_mode": "",
                "sectors": "671080448",
                "sectorsize": "512",
                "size": "320.00 GB",
                "support_discard": "2097152",
                "vendor": null,
                "virtual": 1
            },
            "fd0": {
                "holders": [],
                "host": "",
                "links": {
                    "ids": [],
                    "labels": [],
                    "masters": [],
                    "uuids": []
                },
                "model": null,
                "partitions": {},
                "removable": "1",
                "rotational": "1",
                "sas_address": null,
                "sas_device_handle": null,
                "scheduler_mode": "cfq",
                "sectors": "8",
                "sectorsize": "512",
                "size": "4.00 KB",
                "support_discard": "0",
                "vendor": null,
                "virtual": 1
            },
            "sda": {
                "holders": [],
                "host": "",
                "links": {
                    "ids": [
                        "scsi-14d53465420202020fe5b1c54d09849bd9be69f981cfd7b0b",
                        "scsi-360022480fe5b1c54d0989f981cfd7b0b",
                        "wwn-0x60022480fe5b1c54d0989f981cfd7b0b"
                    ],
                    "labels": [],
                    "masters": [],
                    "uuids": []
                },
                "model": "Virtual Disk",
                "partitions": {
                    "sda1": {
                        "holders": [],
                        "links": {
                            "ids": [
                                "scsi-14d53465420202020fe5b1c54d09849bd9be69f981cfd7b0b-part1",
                                "scsi-360022480fe5b1c54d0989f981cfd7b0b-part1",
                                "wwn-0x60022480fe5b1c54d0989f981cfd7b0b-part1"
                            ],
                            "labels": [],
                            "masters": [],
                            "uuids": []
                        },
                        "sectors": "4096",
                        "sectorsize": 512,
                        "size": "2.00 MB",
                        "start": "2048",
                        "uuid": null
                    },
                    "sda2": {
                        "holders": [],
                        "links": {
                            "ids": [
                                "scsi-14d53465420202020fe5b1c54d09849bd9be69f981cfd7b0b-part2",
                                "scsi-360022480fe5b1c54d0989f981cfd7b0b-part2",
                                "wwn-0x60022480fe5b1c54d0989f981cfd7b0b-part2"
                            ],
                            "labels": [
                                "EFI"
                            ],
                            "masters": [],
                            "uuids": [
                                "E7C1-9C93"
                            ]
                        },
                        "sectors": "1048576",
                        "sectorsize": 512,
                        "size": "512.00 MB",
                        "start": "6144",
                        "uuid": "E7C1-9C93"
                    },
                    "sda3": {
                        "holders": [],
                        "links": {
                            "ids": [
                                "scsi-14d53465420202020fe5b1c54d09849bd9be69f981cfd7b0b-part3",
                                "scsi-360022480fe5b1c54d0989f981cfd7b0b-part3",
                                "wwn-0x60022480fe5b1c54d0989f981cfd7b0b-part3"
                            ],
                            "labels": [
                                "BOOT"
                            ],
                            "masters": [],
                            "uuids": [
                                "b658aa52-6080-43a0-9b17-57fad496a24f"
                            ]
                        },
                        "sectors": "2097152",
                        "sectorsize": 512,
                        "size": "1.00 GB",
                        "start": "1054720",
                        "uuid": "b658aa52-6080-43a0-9b17-57fad496a24f"
                    },
                    "sda4": {
                        "holders": [],
                        "links": {
                            "ids": [
                                "scsi-14d53465420202020fe5b1c54d09849bd9be69f981cfd7b0b-part4",
                                "scsi-360022480fe5b1c54d0989f981cfd7b0b-part4",
                                "wwn-0x60022480fe5b1c54d0989f981cfd7b0b-part4"
                            ],
                            "labels": [
                                "ROOT"
                            ],
                            "masters": [],
                            "uuids": [
                                "af42ae91-56c6-4ee1-a8c8-79c68f3bba49"
                            ]
                        },
                        "sectors": "59762655",
                        "sectorsize": 512,
                        "size": "28.50 GB",
                        "start": "3151872",
                        "uuid": "af42ae91-56c6-4ee1-a8c8-79c68f3bba49"
                    }
                },
                "removable": "0",
                "rotational": "1",
                "sas_address": null,
                "sas_device_handle": null,
                "scheduler_mode": "none",
                "sectors": "62914560",
                "sectorsize": "512",
                "size": "30.00 GB",
                "support_discard": "2097152",
                "vendor": "Msft",
                "virtual": 1,
                "wwn": "0x60022480fe5b1c54d0989f981cfd7b0b"
            },
            "sdb": {
                "holders": [],
                "host": "",
                "links": {
                    "ids": [
                        "scsi-14d53465420202020ddfbf981d2142243a5e5764045eea818",
                        "scsi-360022480ddfbf981d214764045eea818",
                        "wwn-0x60022480ddfbf981d214764045eea818"
                    ],
                    "labels": [],
                    "masters": [],
                    "uuids": []
                },
                "model": "Virtual Disk",
                "partitions": {
                    "sdb1": {
                        "holders": [],
                        "links": {
                            "ids": [
                                "scsi-14d53465420202020ddfbf981d2142243a5e5764045eea818-part1",
                                "scsi-360022480ddfbf981d214764045eea818-part1",
                                "wwn-0x60022480ddfbf981d214764045eea818-part1"
                            ],
                            "labels": [],
                            "masters": [],
                            "uuids": [
                                "d1a3489e-91e6-469d-ad14-0d62d4ae7579"
                            ]
                        },
                        "sectors": "67104768",
                        "sectorsize": 512,
                        "size": "32.00 GB",
                        "start": "2048",
                        "uuid": "d1a3489e-91e6-469d-ad14-0d62d4ae7579"
                    }
                },
                "removable": "0",
                "rotational": "1",
                "sas_address": null,
                "sas_device_handle": null,
                "scheduler_mode": "none",
                "sectors": "67108864",
                "sectorsize": "512",
                "size": "32.00 GB",
                "support_discard": "2097152",
                "vendor": "Msft",
                "virtual": 1,
                "wwn": "0x60022480ddfbf981d214764045eea818"
            },
            "sdc": {
                "holders": [
                    "vg_sap-lv_sapmnt",
                    "vg_sap-lv_usrsapinstall",
                    "vg_sap-lv_usrsap"
                ],
                "host": "",
                "links": {
                    "ids": [
                        "lvm-pv-uuid-JQ4BOw-OeEO-KF7T-cRVV-ezC3-Oszz-3zvo6G",
                        "scsi-14d534654202020200ff9d90a9cf0394c90985bc06941fd43",
                        "scsi-3600224800ff9d90a9cf05bc06941fd43",
                        "wwn-0x600224800ff9d90a9cf05bc06941fd43"
                    ],
                    "labels": [],
                    "masters": [
                        "dm-0",
                        "dm-1",
                        "dm-2"
                    ],
                    "uuids": []
                },
                "model": "Virtual Disk",
                "partitions": {},
                "removable": "0",
                "rotational": "1",
                "sas_address": null,
                "sas_device_handle": null,
                "scheduler_mode": "none",
                "sectors": "1073741824",
                "sectorsize": "512",
                "size": "512.00 GB",
                "support_discard": "2097152",
                "vendor": "Msft",
                "virtual": 1,
                "wwn": "0x600224800ff9d90a9cf05bc06941fd43"
            },
            "sr0": {
                "holders": [],
                "host": "IDE interface: Intel Corporation 82371AB/EB/MB PIIX4 IDE (rev 01)",
                "links": {
                    "ids": [
                        "ata-Virtual_CD"
                    ],
                    "labels": [],
                    "masters": [],
                    "uuids": []
                },
                "model": "Virtual CD/ROM",
                "partitions": {},
                "removable": "1",
                "rotational": "1",
                "sas_address": null,
                "sas_device_handle": null,
                "scheduler_mode": "mq-deadline",
                "sectors": "1256",
                "sectorsize": "2048",
                "size": "628.00 KB",
                "support_discard": "0",
                "vendor": "Msft",
                "virtual": 1
            }
        },
        "ansible_diff_mode": false,
        "ansible_distribution": "SLES_SAP",
        "ansible_distribution_file_parsed": true,
        "ansible_distribution_file_path": "/etc/os-release",
        "ansible_distribution_file_variety": "SUSE",
        "ansible_distribution_major_version": "12",
        "ansible_distribution_release": "5",
        "ansible_distribution_version": "12.5",
        "ansible_dns": {
            "nameservers": [
                "168.63.129.16"
            ],
            "search": [
                "stwg4hzj1seerji4jzks50gkbe.cx.internal.cloudapp.net"
            ]
        },
        "ansible_domain": "internal.cloudapp.net",
        "ansible_effective_group_id": 0,
        "ansible_effective_user_id": 0,
        "ansible_env": {
            "COLORTERM": "1",
            "HOME": "/root",
            "LANG": "C.UTF-8",
            "LOGNAME": "root",
            "MAIL": "/var/mail/root",
            "PATH": "/usr/sbin:/usr/bin:/sbin:/bin",
            "PWD": "/home/azureadm",
            "SHELL": "/bin/bash",
            "SHLVL": "1",
            "SUDO_COMMAND": "/bin/sh -c echo BECOME-SUCCESS-keepjorqhkjsvpijwfkllbglvbmymadn ; /usr/bin/python /home/azureadm/.ansible/tmp/ansible-tmp-1611775221.5407777-15191-104505856602959/AnsiballZ_setup.py",
            "SUDO_GID": "100",
            "SUDO_UID": "1000",
            "SUDO_USER": "azureadm",
            "TERM": "xterm-256color",
            "USER": "root",
            "_": "/usr/bin/python"
        },
        "ansible_eth0": {
            "active": true,
            "device": "eth0",
            "features": {
                "esp_hw_offload": "off [fixed]",
                "esp_tx_csum_hw_offload": "off [fixed]",
                "fcoe_mtu": "off [fixed]",
                "generic_receive_offload": "on",
                "generic_segmentation_offload": "on",
                "highdma": "on [fixed]",
                "hw_tc_offload": "off [fixed]",
                "l2_fwd_offload": "off [fixed]",
                "large_receive_offload": "on",
                "loopback": "off [fixed]",
                "netns_local": "off [fixed]",
                "ntuple_filters": "off [fixed]",
                "receive_hashing": "on",
                "rx_all": "off [fixed]",
                "rx_checksumming": "on",
                "rx_fcs": "off [fixed]",
                "rx_gro_hw": "off [fixed]",
                "rx_udp_tunnel_port_offload": "off [fixed]",
                "rx_vlan_filter": "off [fixed]",
                "rx_vlan_offload": "on [fixed]",
                "rx_vlan_stag_filter": "off [fixed]",
                "rx_vlan_stag_hw_parse": "off [fixed]",
                "scatter_gather": "on",
                "tcp_segmentation_offload": "on",
                "tls_hw_record": "off [fixed]",
                "tls_hw_rx_offload": "off [fixed]",
                "tls_hw_tx_offload": "off [fixed]",
                "tx_checksum_fcoe_crc": "off [fixed]",
                "tx_checksum_ip_generic": "off [fixed]",
                "tx_checksum_ipv4": "on",
                "tx_checksum_ipv6": "on",
                "tx_checksum_sctp": "off [fixed]",
                "tx_checksumming": "on",
                "tx_esp_segmentation": "off [fixed]",
                "tx_fcoe_segmentation": "off [fixed]",
                "tx_gre_csum_segmentation": "off [fixed]",
                "tx_gre_segmentation": "off [fixed]",
                "tx_gso_partial": "off [fixed]",
                "tx_gso_robust": "off [fixed]",
                "tx_ipxip4_segmentation": "off [fixed]",
                "tx_ipxip6_segmentation": "off [fixed]",
                "tx_lockless": "off [fixed]",
                "tx_nocache_copy": "off",
                "tx_scatter_gather": "on",
                "tx_scatter_gather_fraglist": "off [fixed]",
                "tx_sctp_segmentation": "off [fixed]",
                "tx_tcp6_segmentation": "on",
                "tx_tcp_ecn_segmentation": "off [fixed]",
                "tx_tcp_mangleid_segmentation": "off",
                "tx_tcp_segmentation": "on",
                "tx_udp_segmentation": "off [fixed]",
                "tx_udp_tnl_csum_segmentation": "off [fixed]",
                "tx_udp_tnl_segmentation": "off [fixed]",
                "tx_vlan_offload": "on [fixed]",
                "tx_vlan_stag_hw_insert": "off [fixed]",
                "udp_fragmentation_offload": "off",
                "vlan_challenged": "off [fixed]"
            },
            "hw_timestamp_filters": [],
            "ipv4": {
                "address": "10.1.1.42",
                "broadcast": "10.1.1.63",
                "netmask": "255.255.255.224",
                "network": "10.1.1.32"
            },
            "ipv6": [
                {
                    "address": "fe80::20d:3aff:fe0f:305f",
                    "prefix": "64",
                    "scope": "link"
                }
            ],
            "macaddress": "00:0d:3a:0f:30:5f",
            "module": "hv_netvsc",
            "mtu": 1500,
            "pciid": "000d3a0f-305f-000d-3a0f-305f000d3a0f",
            "promisc": false,
            "speed": 40000,
            "timestamping": [
                "tx_software",
                "rx_software",
                "software"
            ],
            "type": "ether"
        },
        "ansible_facts": {
            "all_ipv4_addresses": [
                "10.1.1.42"
            ],
            "all_ipv6_addresses": [
                "fe80::20d:3aff:fe0f:305f"
            ],
            "ansible_local": {},
            "apparmor": {
                "status": "enabled"
            },
            "architecture": "x86_64",
            "bios_date": "12/07/2018",
            "bios_version": "090008",
            "cmdline": {
                "BOOT_IMAGE": "/vmlinuz-4.12.14-122.54-default",
                "USE_BY_UUID_DEVICE_NAMES": "1",
                "console": "ttyS0",
                "dis_ucode_ldr": true,
                "earlyprintk": "ttyS0",
                "multipath": "off",
                "net.ifnames": "0",
                "root": "UUID=af42ae91-56c6-4ee1-a8c8-79c68f3bba49",
                "rootdelay": "300",
                "rw": true,
                "scsi_mod.use_blk_mq": "1"
            },
            "date_time": {
                "date": "2021-01-27",
                "day": "27",
                "epoch": "1611775222",
                "hour": "19",
                "iso8601": "2021-01-27T19:20:22Z",
                "iso8601_basic": "20210127T192022643439",
                "iso8601_basic_short": "20210127T192022",
                "iso8601_micro": "2021-01-27T19:20:22.643553Z",
                "minute": "20",
                "month": "01",
                "second": "22",
                "time": "19:20:22",
                "tz": "UTC",
                "tz_offset": "+0000",
                "weekday": "Wednesday",
                "weekday_number": "3",
                "weeknumber": "04",
                "year": "2021"
            },
            "default_ipv4": {
                "address": "10.1.1.42",
                "alias": "eth0",
                "broadcast": "10.1.1.63",
                "gateway": "10.1.1.33",
                "interface": "eth0",
                "macaddress": "00:0d:3a:0f:30:5f",
                "mtu": 1500,
                "netmask": "255.255.255.224",
                "network": "10.1.1.32",
                "type": "ether"
            },
            "default_ipv6": {},
            "device_links": {
                "ids": {
                    "dm-0": [
                        "dm-name-vg_sap-lv_usrsap",
                        "dm-uuid-LVM-2Ae42FOzDAhOWvKky0JTHPwvlyYgzKbQPtObucSTgJWWoM2mLNPsVVvH18vG9wyS"
                    ],
                    "dm-1": [
                        "dm-name-vg_sap-lv_sapmnt",
                        "dm-uuid-LVM-2Ae42FOzDAhOWvKky0JTHPwvlyYgzKbQFlN4EC3K3xkMZANhBAnel3sIyu32q5fz"
                    ],
                    "dm-2": [
                        "dm-name-vg_sap-lv_usrsapinstall",
                        "dm-uuid-LVM-2Ae42FOzDAhOWvKky0JTHPwvlyYgzKbQK5MHLUtZ6QVx2A575rxDmtcRvVHDWotw"
                    ],
                    "sda": [
                        "scsi-14d53465420202020fe5b1c54d09849bd9be69f981cfd7b0b",
                        "scsi-360022480fe5b1c54d0989f981cfd7b0b",
                        "wwn-0x60022480fe5b1c54d0989f981cfd7b0b"
                    ],
                    "sda1": [
                        "scsi-14d53465420202020fe5b1c54d09849bd9be69f981cfd7b0b-part1",
                        "scsi-360022480fe5b1c54d0989f981cfd7b0b-part1",
                        "wwn-0x60022480fe5b1c54d0989f981cfd7b0b-part1"
                    ],
                    "sda2": [
                        "scsi-14d53465420202020fe5b1c54d09849bd9be69f981cfd7b0b-part2",
                        "scsi-360022480fe5b1c54d0989f981cfd7b0b-part2",
                        "wwn-0x60022480fe5b1c54d0989f981cfd7b0b-part2"
                    ],
                    "sda3": [
                        "scsi-14d53465420202020fe5b1c54d09849bd9be69f981cfd7b0b-part3",
                        "scsi-360022480fe5b1c54d0989f981cfd7b0b-part3",
                        "wwn-0x60022480fe5b1c54d0989f981cfd7b0b-part3"
                    ],
                    "sda4": [
                        "scsi-14d53465420202020fe5b1c54d09849bd9be69f981cfd7b0b-part4",
                        "scsi-360022480fe5b1c54d0989f981cfd7b0b-part4",
                        "wwn-0x60022480fe5b1c54d0989f981cfd7b0b-part4"
                    ],
                    "sdb": [
                        "scsi-14d53465420202020ddfbf981d2142243a5e5764045eea818",
                        "scsi-360022480ddfbf981d214764045eea818",
                        "wwn-0x60022480ddfbf981d214764045eea818"
                    ],
                    "sdb1": [
                        "scsi-14d53465420202020ddfbf981d2142243a5e5764045eea818-part1",
                        "scsi-360022480ddfbf981d214764045eea818-part1",
                        "wwn-0x60022480ddfbf981d214764045eea818-part1"
                    ],
                    "sdc": [
                        "lvm-pv-uuid-JQ4BOw-OeEO-KF7T-cRVV-ezC3-Oszz-3zvo6G",
                        "scsi-14d534654202020200ff9d90a9cf0394c90985bc06941fd43",
                        "scsi-3600224800ff9d90a9cf05bc06941fd43",
                        "wwn-0x600224800ff9d90a9cf05bc06941fd43"
                    ],
                    "sr0": [
                        "ata-Virtual_CD"
                    ]
                },
                "labels": {
                    "sda2": [
                        "EFI"
                    ],
                    "sda3": [
                        "BOOT"
                    ],
                    "sda4": [
                        "ROOT"
                    ]
                },
                "masters": {
                    "sdc": [
                        "dm-0",
                        "dm-1",
                        "dm-2"
                    ]
                },
                "uuids": {
                    "dm-0": [
                        "3e62d488-0fdb-4cb4-9786-9264b551357a"
                    ],
                    "dm-1": [
                        "dc442871-6ebc-4f8d-8da3-12a7b2e48b4a"
                    ],
                    "dm-2": [
                        "98b09423-3006-44a1-a2dd-c9f650e2463b"
                    ],
                    "sda2": [
                        "E7C1-9C93"
                    ],
                    "sda3": [
                        "b658aa52-6080-43a0-9b17-57fad496a24f"
                    ],
                    "sda4": [
                        "af42ae91-56c6-4ee1-a8c8-79c68f3bba49"
                    ],
                    "sdb1": [
                        "d1a3489e-91e6-469d-ad14-0d62d4ae7579"
                    ]
                }
            },
            "devices": {
                "dm-0": {
                    "holders": [],
                    "host": "",
                    "links": {
                        "ids": [
                            "dm-name-vg_sap-lv_usrsap",
                            "dm-uuid-LVM-2Ae42FOzDAhOWvKky0JTHPwvlyYgzKbQPtObucSTgJWWoM2mLNPsVVvH18vG9wyS"
                        ],
                        "labels": [],
                        "masters": [],
                        "uuids": [
                            "3e62d488-0fdb-4cb4-9786-9264b551357a"
                        ]
                    },
                    "model": null,
                    "partitions": {},
                    "removable": "0",
                    "rotational": "1",
                    "sas_address": null,
                    "sas_device_handle": null,
                    "scheduler_mode": "",
                    "sectors": "134217728",
                    "sectorsize": "512",
                    "size": "64.00 GB",
                    "support_discard": "2097152",
                    "vendor": null,
                    "virtual": 1
                },
                "dm-1": {
                    "holders": [],
                    "host": "",
                    "links": {
                        "ids": [
                            "dm-name-vg_sap-lv_sapmnt",
                            "dm-uuid-LVM-2Ae42FOzDAhOWvKky0JTHPwvlyYgzKbQFlN4EC3K3xkMZANhBAnel3sIyu32q5fz"
                        ],
                        "labels": [],
                        "masters": [],
                        "uuids": [
                            "dc442871-6ebc-4f8d-8da3-12a7b2e48b4a"
                        ]
                    },
                    "model": null,
                    "partitions": {},
                    "removable": "0",
                    "rotational": "1",
                    "sas_address": null,
                    "sas_device_handle": null,
                    "scheduler_mode": "",
                    "sectors": "268435456",
                    "sectorsize": "512",
                    "size": "128.00 GB",
                    "support_discard": "2097152",
                    "vendor": null,
                    "virtual": 1
                },
                "dm-2": {
                    "holders": [],
                    "host": "",
                    "links": {
                        "ids": [
                            "dm-name-vg_sap-lv_usrsapinstall",
                            "dm-uuid-LVM-2Ae42FOzDAhOWvKky0JTHPwvlyYgzKbQK5MHLUtZ6QVx2A575rxDmtcRvVHDWotw"
                        ],
                        "labels": [],
                        "masters": [],
                        "uuids": [
                            "98b09423-3006-44a1-a2dd-c9f650e2463b"
                        ]
                    },
                    "model": null,
                    "partitions": {},
                    "removable": "0",
                    "rotational": "1",
                    "sas_address": null,
                    "sas_device_handle": null,
                    "scheduler_mode": "",
                    "sectors": "671080448",
                    "sectorsize": "512",
                    "size": "320.00 GB",
                    "support_discard": "2097152",
                    "vendor": null,
                    "virtual": 1
                },
                "fd0": {
                    "holders": [],
                    "host": "",
                    "links": {
                        "ids": [],
                        "labels": [],
                        "masters": [],
                        "uuids": []
                    },
                    "model": null,
                    "partitions": {},
                    "removable": "1",
                    "rotational": "1",
                    "sas_address": null,
                    "sas_device_handle": null,
                    "scheduler_mode": "cfq",
                    "sectors": "8",
                    "sectorsize": "512",
                    "size": "4.00 KB",
                    "support_discard": "0",
                    "vendor": null,
                    "virtual": 1
                },
                "sda": {
                    "holders": [],
                    "host": "",
                    "links": {
                        "ids": [
                            "scsi-14d53465420202020fe5b1c54d09849bd9be69f981cfd7b0b",
                            "scsi-360022480fe5b1c54d0989f981cfd7b0b",
                            "wwn-0x60022480fe5b1c54d0989f981cfd7b0b"
                        ],
                        "labels": [],
                        "masters": [],
                        "uuids": []
                    },
                    "model": "Virtual Disk",
                    "partitions": {
                        "sda1": {
                            "holders": [],
                            "links": {
                                "ids": [
                                    "scsi-14d53465420202020fe5b1c54d09849bd9be69f981cfd7b0b-part1",
                                    "scsi-360022480fe5b1c54d0989f981cfd7b0b-part1",
                                    "wwn-0x60022480fe5b1c54d0989f981cfd7b0b-part1"
                                ],
                                "labels": [],
                                "masters": [],
                                "uuids": []
                            },
                            "sectors": "4096",
                            "sectorsize": 512,
                            "size": "2.00 MB",
                            "start": "2048",
                            "uuid": null
                        },
                        "sda2": {
                            "holders": [],
                            "links": {
                                "ids": [
                                    "scsi-14d53465420202020fe5b1c54d09849bd9be69f981cfd7b0b-part2",
                                    "scsi-360022480fe5b1c54d0989f981cfd7b0b-part2",
                                    "wwn-0x60022480fe5b1c54d0989f981cfd7b0b-part2"
                                ],
                                "labels": [
                                    "EFI"
                                ],
                                "masters": [],
                                "uuids": [
                                    "E7C1-9C93"
                                ]
                            },
                            "sectors": "1048576",
                            "sectorsize": 512,
                            "size": "512.00 MB",
                            "start": "6144",
                            "uuid": "E7C1-9C93"
                        },
                        "sda3": {
                            "holders": [],
                            "links": {
                                "ids": [
                                    "scsi-14d53465420202020fe5b1c54d09849bd9be69f981cfd7b0b-part3",
                                    "scsi-360022480fe5b1c54d0989f981cfd7b0b-part3",
                                    "wwn-0x60022480fe5b1c54d0989f981cfd7b0b-part3"
                                ],
                                "labels": [
                                    "BOOT"
                                ],
                                "masters": [],
                                "uuids": [
                                    "b658aa52-6080-43a0-9b17-57fad496a24f"
                                ]
                            },
                            "sectors": "2097152",
                            "sectorsize": 512,
                            "size": "1.00 GB",
                            "start": "1054720",
                            "uuid": "b658aa52-6080-43a0-9b17-57fad496a24f"
                        },
                        "sda4": {
                            "holders": [],
                            "links": {
                                "ids": [
                                    "scsi-14d53465420202020fe5b1c54d09849bd9be69f981cfd7b0b-part4",
                                    "scsi-360022480fe5b1c54d0989f981cfd7b0b-part4",
                                    "wwn-0x60022480fe5b1c54d0989f981cfd7b0b-part4"
                                ],
                                "labels": [
                                    "ROOT"
                                ],
                                "masters": [],
                                "uuids": [
                                    "af42ae91-56c6-4ee1-a8c8-79c68f3bba49"
                                ]
                            },
                            "sectors": "59762655",
                            "sectorsize": 512,
                            "size": "28.50 GB",
                            "start": "3151872",
                            "uuid": "af42ae91-56c6-4ee1-a8c8-79c68f3bba49"
                        }
                    },
                    "removable": "0",
                    "rotational": "1",
                    "sas_address": null,
                    "sas_device_handle": null,
                    "scheduler_mode": "none",
                    "sectors": "62914560",
                    "sectorsize": "512",
                    "size": "30.00 GB",
                    "support_discard": "2097152",
                    "vendor": "Msft",
                    "virtual": 1,
                    "wwn": "0x60022480fe5b1c54d0989f981cfd7b0b"
                },
                "sdb": {
                    "holders": [],
                    "host": "",
                    "links": {
                        "ids": [
                            "scsi-14d53465420202020ddfbf981d2142243a5e5764045eea818",
                            "scsi-360022480ddfbf981d214764045eea818",
                            "wwn-0x60022480ddfbf981d214764045eea818"
                        ],
                        "labels": [],
                        "masters": [],
                        "uuids": []
                    },
                    "model": "Virtual Disk",
                    "partitions": {
                        "sdb1": {
                            "holders": [],
                            "links": {
                                "ids": [
                                    "scsi-14d53465420202020ddfbf981d2142243a5e5764045eea818-part1",
                                    "scsi-360022480ddfbf981d214764045eea818-part1",
                                    "wwn-0x60022480ddfbf981d214764045eea818-part1"
                                ],
                                "labels": [],
                                "masters": [],
                                "uuids": [
                                    "d1a3489e-91e6-469d-ad14-0d62d4ae7579"
                                ]
                            },
                            "sectors": "67104768",
                            "sectorsize": 512,
                            "size": "32.00 GB",
                            "start": "2048",
                            "uuid": "d1a3489e-91e6-469d-ad14-0d62d4ae7579"
                        }
                    },
                    "removable": "0",
                    "rotational": "1",
                    "sas_address": null,
                    "sas_device_handle": null,
                    "scheduler_mode": "none",
                    "sectors": "67108864",
                    "sectorsize": "512",
                    "size": "32.00 GB",
                    "support_discard": "2097152",
                    "vendor": "Msft",
                    "virtual": 1,
                    "wwn": "0x60022480ddfbf981d214764045eea818"
                },
                "sdc": {
                    "holders": [
                        "vg_sap-lv_sapmnt",
                        "vg_sap-lv_usrsapinstall",
                        "vg_sap-lv_usrsap"
                    ],
                    "host": "",
                    "links": {
                        "ids": [
                            "lvm-pv-uuid-JQ4BOw-OeEO-KF7T-cRVV-ezC3-Oszz-3zvo6G",
                            "scsi-14d534654202020200ff9d90a9cf0394c90985bc06941fd43",
                            "scsi-3600224800ff9d90a9cf05bc06941fd43",
                            "wwn-0x600224800ff9d90a9cf05bc06941fd43"
                        ],
                        "labels": [],
                        "masters": [
                            "dm-0",
                            "dm-1",
                            "dm-2"
                        ],
                        "uuids": []
                    },
                    "model": "Virtual Disk",
                    "partitions": {},
                    "removable": "0",
                    "rotational": "1",
                    "sas_address": null,
                    "sas_device_handle": null,
                    "scheduler_mode": "none",
                    "sectors": "1073741824",
                    "sectorsize": "512",
                    "size": "512.00 GB",
                    "support_discard": "2097152",
                    "vendor": "Msft",
                    "virtual": 1,
                    "wwn": "0x600224800ff9d90a9cf05bc06941fd43"
                },
                "sr0": {
                    "holders": [],
                    "host": "IDE interface: Intel Corporation 82371AB/EB/MB PIIX4 IDE (rev 01)",
                    "links": {
                        "ids": [
                            "ata-Virtual_CD"
                        ],
                        "labels": [],
                        "masters": [],
                        "uuids": []
                    },
                    "model": "Virtual CD/ROM",
                    "partitions": {},
                    "removable": "1",
                    "rotational": "1",
                    "sas_address": null,
                    "sas_device_handle": null,
                    "scheduler_mode": "mq-deadline",
                    "sectors": "1256",
                    "sectorsize": "2048",
                    "size": "628.00 KB",
                    "support_discard": "0",
                    "vendor": "Msft",
                    "virtual": 1
                }
            },
            "discovered_interpreter_python": "/usr/bin/python",
            "distribution": "SLES_SAP",
            "distribution_file_parsed": true,
            "distribution_file_path": "/etc/os-release",
            "distribution_file_variety": "SUSE",
            "distribution_major_version": "12",
            "distribution_release": "5",
            "distribution_version": "12.5",
            "dns": {
                "nameservers": [
                    "168.63.129.16"
                ],
                "search": [
                    "stwg4hzj1seerji4jzks50gkbe.cx.internal.cloudapp.net"
                ]
            },
            "domain": "internal.cloudapp.net",
            "effective_group_id": 0,
            "effective_user_id": 0,
            "env": {
                "COLORTERM": "1",
                "HOME": "/root",
                "LANG": "C.UTF-8",
                "LOGNAME": "root",
                "MAIL": "/var/mail/root",
                "PATH": "/usr/sbin:/usr/bin:/sbin:/bin",
                "PWD": "/home/azureadm",
                "SHELL": "/bin/bash",
                "SHLVL": "1",
                "SUDO_COMMAND": "/bin/sh -c echo BECOME-SUCCESS-keepjorqhkjsvpijwfkllbglvbmymadn ; /usr/bin/python /home/azureadm/.ansible/tmp/ansible-tmp-1611775221.5407777-15191-104505856602959/AnsiballZ_setup.py",
                "SUDO_GID": "100",
                "SUDO_UID": "1000",
                "SUDO_USER": "azureadm",
                "TERM": "xterm-256color",
                "USER": "root",
                "_": "/usr/bin/python"
            },
            "eth0": {
                "active": true,
                "device": "eth0",
                "features": {
                    "esp_hw_offload": "off [fixed]",
                    "esp_tx_csum_hw_offload": "off [fixed]",
                    "fcoe_mtu": "off [fixed]",
                    "generic_receive_offload": "on",
                    "generic_segmentation_offload": "on",
                    "highdma": "on [fixed]",
                    "hw_tc_offload": "off [fixed]",
                    "l2_fwd_offload": "off [fixed]",
                    "large_receive_offload": "on",
                    "loopback": "off [fixed]",
                    "netns_local": "off [fixed]",
                    "ntuple_filters": "off [fixed]",
                    "receive_hashing": "on",
                    "rx_all": "off [fixed]",
                    "rx_checksumming": "on",
                    "rx_fcs": "off [fixed]",
                    "rx_gro_hw": "off [fixed]",
                    "rx_udp_tunnel_port_offload": "off [fixed]",
                    "rx_vlan_filter": "off [fixed]",
                    "rx_vlan_offload": "on [fixed]",
                    "rx_vlan_stag_filter": "off [fixed]",
                    "rx_vlan_stag_hw_parse": "off [fixed]",
                    "scatter_gather": "on",
                    "tcp_segmentation_offload": "on",
                    "tls_hw_record": "off [fixed]",
                    "tls_hw_rx_offload": "off [fixed]",
                    "tls_hw_tx_offload": "off [fixed]",
                    "tx_checksum_fcoe_crc": "off [fixed]",
                    "tx_checksum_ip_generic": "off [fixed]",
                    "tx_checksum_ipv4": "on",
                    "tx_checksum_ipv6": "on",
                    "tx_checksum_sctp": "off [fixed]",
                    "tx_checksumming": "on",
                    "tx_esp_segmentation": "off [fixed]",
                    "tx_fcoe_segmentation": "off [fixed]",
                    "tx_gre_csum_segmentation": "off [fixed]",
                    "tx_gre_segmentation": "off [fixed]",
                    "tx_gso_partial": "off [fixed]",
                    "tx_gso_robust": "off [fixed]",
                    "tx_ipxip4_segmentation": "off [fixed]",
                    "tx_ipxip6_segmentation": "off [fixed]",
                    "tx_lockless": "off [fixed]",
                    "tx_nocache_copy": "off",
                    "tx_scatter_gather": "on",
                    "tx_scatter_gather_fraglist": "off [fixed]",
                    "tx_sctp_segmentation": "off [fixed]",
                    "tx_tcp6_segmentation": "on",
                    "tx_tcp_ecn_segmentation": "off [fixed]",
                    "tx_tcp_mangleid_segmentation": "off",
                    "tx_tcp_segmentation": "on",
                    "tx_udp_segmentation": "off [fixed]",
                    "tx_udp_tnl_csum_segmentation": "off [fixed]",
                    "tx_udp_tnl_segmentation": "off [fixed]",
                    "tx_vlan_offload": "on [fixed]",
                    "tx_vlan_stag_hw_insert": "off [fixed]",
                    "udp_fragmentation_offload": "off",
                    "vlan_challenged": "off [fixed]"
                },
                "hw_timestamp_filters": [],
                "ipv4": {
                    "address": "10.1.1.42",
                    "broadcast": "10.1.1.63",
                    "netmask": "255.255.255.224",
                    "network": "10.1.1.32"
                },
                "ipv6": [
                    {
                        "address": "fe80::20d:3aff:fe0f:305f",
                        "prefix": "64",
                        "scope": "link"
                    }
                ],
                "macaddress": "00:0d:3a:0f:30:5f",
                "module": "hv_netvsc",
                "mtu": 1500,
                "pciid": "000d3a0f-305f-000d-3a0f-305f000d3a0f",
                "promisc": false,
                "speed": 40000,
                "timestamping": [
                    "tx_software",
                    "rx_software",
                    "software"
                ],
                "type": "ether"
            },
            "fibre_channel_wwn": [],
            "fips": false,
            "form_factor": "Desktop",
            "fqdn": "x00scs00l373.internal.cloudapp.net",
            "gather_subset": [
                "all"
            ],
            "hostname": "x00scs00l373",
            "hostnqn": "",
            "interfaces": [
                "lo",
                "eth0"
            ],
            "is_chroot": false,
            "iscsi_iqn": "iqn.1996-04.de.suse:01:a03cdffc3eed",
            "kernel": "4.12.14-122.54-default",
            "lo": {
                "active": true,
                "device": "lo",
                "features": {
                    "esp_hw_offload": "off [fixed]",
                    "esp_tx_csum_hw_offload": "off [fixed]",
                    "fcoe_mtu": "off [fixed]",
                    "generic_receive_offload": "on",
                    "generic_segmentation_offload": "on",
                    "highdma": "on [fixed]",
                    "hw_tc_offload": "off [fixed]",
                    "l2_fwd_offload": "off [fixed]",
                    "large_receive_offload": "off [fixed]",
                    "loopback": "on [fixed]",
                    "netns_local": "on [fixed]",
                    "ntuple_filters": "off [fixed]",
                    "receive_hashing": "off [fixed]",
                    "rx_all": "off [fixed]",
                    "rx_checksumming": "on [fixed]",
                    "rx_fcs": "off [fixed]",
                    "rx_gro_hw": "off [fixed]",
                    "rx_udp_tunnel_port_offload": "off [fixed]",
                    "rx_vlan_filter": "off [fixed]",
                    "rx_vlan_offload": "off [fixed]",
                    "rx_vlan_stag_filter": "off [fixed]",
                    "rx_vlan_stag_hw_parse": "off [fixed]",
                    "scatter_gather": "on",
                    "tcp_segmentation_offload": "on",
                    "tls_hw_record": "off [fixed]",
                    "tls_hw_rx_offload": "off [fixed]",
                    "tls_hw_tx_offload": "off [fixed]",
                    "tx_checksum_fcoe_crc": "off [fixed]",
                    "tx_checksum_ip_generic": "on [fixed]",
                    "tx_checksum_ipv4": "off [fixed]",
                    "tx_checksum_ipv6": "off [fixed]",
                    "tx_checksum_sctp": "on [fixed]",
                    "tx_checksumming": "on",
                    "tx_esp_segmentation": "off [fixed]",
                    "tx_fcoe_segmentation": "off [fixed]",
                    "tx_gre_csum_segmentation": "off [fixed]",
                    "tx_gre_segmentation": "off [fixed]",
                    "tx_gso_partial": "off [fixed]",
                    "tx_gso_robust": "off [fixed]",
                    "tx_ipxip4_segmentation": "off [fixed]",
                    "tx_ipxip6_segmentation": "off [fixed]",
                    "tx_lockless": "on [fixed]",
                    "tx_nocache_copy": "off [fixed]",
                    "tx_scatter_gather": "on [fixed]",
                    "tx_scatter_gather_fraglist": "on [fixed]",
                    "tx_sctp_segmentation": "on",
                    "tx_tcp6_segmentation": "on",
                    "tx_tcp_ecn_segmentation": "on",
                    "tx_tcp_mangleid_segmentation": "on",
                    "tx_tcp_segmentation": "on",
                    "tx_udp_segmentation": "off [fixed]",
                    "tx_udp_tnl_csum_segmentation": "off [fixed]",
                    "tx_udp_tnl_segmentation": "off [fixed]",
                    "tx_vlan_offload": "off [fixed]",
                    "tx_vlan_stag_hw_insert": "off [fixed]",
                    "udp_fragmentation_offload": "off",
                    "vlan_challenged": "on [fixed]"
                },
                "hw_timestamp_filters": [],
                "ipv4": {
                    "address": "127.0.0.1",
                    "broadcast": "host",
                    "netmask": "255.0.0.0",
                    "network": "127.0.0.0"
                },
                "ipv6": [
                    {
                        "address": "::1",
                        "prefix": "128",
                        "scope": "host"
                    }
                ],
                "mtu": 65536,
                "promisc": false,
                "timestamping": [
                    "tx_software",
                    "rx_software",
                    "software"
                ],
                "type": "loopback"
            },
            "lsb": {},
            "lvm": {
                "lvs": {
                    "lv_sapmnt": {
                        "size_g": "128.00",
                        "vg": "vg_sap"
                    },
                    "lv_usrsap": {
                        "size_g": "64.00",
                        "vg": "vg_sap"
                    },
                    "lv_usrsapinstall": {
                        "size_g": "320.00",
                        "vg": "vg_sap"
                    }
                },
                "pvs": {
                    "/dev/sdc": {
                        "free_g": "0",
                        "size_g": "512.00",
                        "vg": "vg_sap"
                    }
                },
                "vgs": {
                    "vg_sap": {
                        "free_g": "0",
                        "num_lvs": "3",
                        "num_pvs": "1",
                        "size_g": "512.00"
                    }
                }
            },
            "machine": "x86_64",
            "machine_id": "c5dd3fea0008780c67ff5cc15fd20e2f",
            "memfree_mb": 15502,
            "memory_mb": {
                "nocache": {
                    "free": 15806,
                    "used": 226
                },
                "real": {
                    "free": 15502,
                    "total": 16032,
                    "used": 530
                },
                "swap": {
                    "cached": 4,
                    "free": 20412,
                    "total": 20479,
                    "used": 67
                }
            },
            "memtotal_mb": 16032,
            "module_setup": true,
            "mounts": [
                {
                    "block_available": 234514,
                    "block_size": 4096,
                    "block_total": 259584,
                    "block_used": 25070,
                    "device": "/dev/sda3",
                    "fstype": "xfs",
                    "inode_available": 523662,
                    "inode_total": 524288,
                    "inode_used": 626,
                    "mount": "/boot",
                    "options": "rw,relatime,attr2,inode64,noquota",
                    "size_available": 960569344,
                    "size_total": 1063256064,
                    "uuid": "b658aa52-6080-43a0-9b17-57fad496a24f"
                },
                {
                    "block_available": 65365,
                    "block_size": 8192,
                    "block_total": 65501,
                    "block_used": 136,
                    "device": "/dev/sda2",
                    "fstype": "vfat",
                    "inode_available": 0,
                    "inode_total": 0,
                    "inode_used": 0,
                    "mount": "/boot/efi",
                    "options": "rw,relatime,fmask=0022,dmask=0022,codepage=437,iocharset=iso8859-1,shortname=mixed,errors=remount-ro",
                    "size_available": 535470080,
                    "size_total": 536584192,
                    "uuid": "E7C1-9C93"
                },
                {
                    "block_available": 6873122,
                    "block_size": 4096,
                    "block_total": 7466684,
                    "block_used": 593562,
                    "device": "/dev/sda4",
                    "fstype": "xfs",
                    "inode_available": 14818673,
                    "inode_total": 14940608,
                    "inode_used": 121935,
                    "mount": "/",
                    "options": "rw,relatime,attr2,inode64,noquota",
                    "size_available": 28152307712,
                    "size_total": 30583537664,
                    "uuid": "af42ae91-56c6-4ee1-a8c8-79c68f3bba49"
                },
                {
                    "block_available": 2545008,
                    "block_size": 4096,
                    "block_total": 8223684,
                    "block_used": 5678676,
                    "device": "/dev/sdb1",
                    "fstype": "ext4",
                    "inode_available": 2097139,
                    "inode_total": 2097152,
                    "inode_used": 13,
                    "mount": "/mnt",
                    "options": "rw,relatime,data=ordered",
                    "size_available": 10424352768,
                    "size_total": 33684209664,
                    "uuid": "d1a3489e-91e6-469d-ad14-0d62d4ae7579"
                },
                {
                    "block_available": 82793296,
                    "block_size": 4096,
                    "block_total": 83844097,
                    "block_used": 1050801,
                    "device": "/dev/mapper/vg_sap-lv_usrsapinstall",
                    "fstype": "xfs",
                    "inode_available": 167770099,
                    "inode_total": 167770112,
                    "inode_used": 13,
                    "mount": "/usr/sap/install",
                    "options": "rw,relatime,attr2,inode64,noquota",
                    "size_available": 339121340416,
                    "size_total": 343425421312,
                    "uuid": "98b09423-3006-44a1-a2dd-c9f650e2463b"
                },
                {
                    "block_available": 16760756,
                    "block_size": 4096,
                    "block_total": 16769024,
                    "block_used": 8268,
                    "device": "/dev/mapper/vg_sap-lv_usrsap",
                    "fstype": "xfs",
                    "inode_available": 33554427,
                    "inode_total": 33554432,
                    "inode_used": 5,
                    "mount": "/usr/sap",
                    "options": "rw,relatime,attr2,inode64,noquota",
                    "size_available": 68652056576,
                    "size_total": 68685922304,
                    "uuid": "3e62d488-0fdb-4cb4-9786-9264b551357a"
                },
                {
                    "block_available": 33529788,
                    "block_size": 4096,
                    "block_total": 33538048,
                    "block_used": 8260,
                    "device": "/dev/mapper/vg_sap-lv_sapmnt",
                    "fstype": "xfs",
                    "inode_available": 67108860,
                    "inode_total": 67108864,
                    "inode_used": 4,
                    "mount": "/sapmnt",
                    "options": "rw,relatime,attr2,inode64,noquota",
                    "size_available": 137338011648,
                    "size_total": 137371844608,
                    "uuid": "dc442871-6ebc-4f8d-8da3-12a7b2e48b4a"
                }
            ],
            "nodename": "x00scs00l373",
            "os_family": "Suse",
            "pkg_mgr": "zypper",
            "proc_cmdline": {
                "BOOT_IMAGE": "/vmlinuz-4.12.14-122.54-default",
                "USE_BY_UUID_DEVICE_NAMES": "1",
                "console": "ttyS0",
                "dis_ucode_ldr": true,
                "earlyprintk": "ttyS0",
                "multipath": "off",
                "net.ifnames": "0",
                "root": "UUID=af42ae91-56c6-4ee1-a8c8-79c68f3bba49",
                "rootdelay": "300",
                "rw": true,
                "scsi_mod.use_blk_mq": "1"
            },
            "processor": [
                "0",
                "GenuineIntel",
                "Intel(R) Xeon(R) CPU E5-2673 v4 @ 2.30GHz",
                "1",
                "GenuineIntel",
                "Intel(R) Xeon(R) CPU E5-2673 v4 @ 2.30GHz",
                "2",
                "GenuineIntel",
                "Intel(R) Xeon(R) CPU E5-2673 v4 @ 2.30GHz",
                "3",
                "GenuineIntel",
                "Intel(R) Xeon(R) CPU E5-2673 v4 @ 2.30GHz"
            ],
            "processor_cores": 2,
            "processor_count": 1,
            "processor_threads_per_core": 2,
            "processor_vcpus": 4,
            "product_name": "Virtual Machine",
            "product_serial": "0000-0017-7437-9893-9723-1229-18",
            "product_uuid": "20A33EF6-2600-E648-B405-EF3C9E9B6E4F",
            "product_version": "7.0",
            "python": {
                "executable": "/usr/bin/python",
                "has_sslcontext": true,
                "type": "CPython",
                "version": {
                    "major": 2,
                    "micro": 17,
                    "minor": 7,
                    "releaselevel": "final",
                    "serial": 0
                },
                "version_info": [
                    2,
                    7,
                    17,
                    "final",
                    0
                ]
            },
            "python_version": "2.7.17",
            "real_group_id": 0,
            "real_user_id": 0,
            "selinux": {
                "status": "Missing selinux Python library"
            },
            "selinux_python_present": false,
            "service_mgr": "systemd",
            "ssh_host_key_dsa_public": "AAAAB3NzaC1kc3MAAACBAMGFNpIkKprb0hbA5fdksMGr4D5Yepcnjl65LA8iVPAoXNSYiVIZlTToAgMalPD5Sa7Ijy0dPr8f0/l6X1xSKuxv1EIQ38D48qdPeCnrb6wE1ajjc8n3Nx8Ar8ji9QU+WN76u9S3Ms3Mdjm8tABpIVfBV3OFXRjfVQWqYiMJW6ShAAAAFQDFTeAb5pDpSpie1gH9iCuMU5GjrQAAAIEApOF11cAWYScqrK7bIVdrjvHV5d4Rh1vljhOpGDdcUlF7fMG5s94umcG3uaMWe2V9+hzq3Wj14kg7tZ1/5sODYOJ8tyMl83+n01AyRGyjrVl3ALlEbpJuR2RZUAgLZhmMQ8K7T97DAYIiUfQjy8fOCy1N6hbby3MfqXu2+SEZK1QAAACAJplnAxH/+5lWxjhYDrUuPl0rxP/PnPCvfsk13MlIa7BzYTgtgjZWDrpuK27DHV1CaLHkYMlpFa54oVyCk53onv59LOiIO9GEzJIbO0OKrKyVx5hTU1GV6ef8Y/QwvF5t/YvgEtlAN52JBN+SODC6+QOGldCDA/UDPT7b4UpgHag=",
            "ssh_host_key_ecdsa_public": "AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBLf4pGg+8Bmhrw/TzNw0xHRQGQSkRRlRDDFlm5RZNX836riQzCT7uJNOYaJ1qJwAO/y+0GBS4paFH2U8RIG62kY=",
            "ssh_host_key_ed25519_public": "AAAAC3NzaC1lZDI1NTE5AAAAIERZpXlAS7/t9ur02+EtbeAK7cIRrLyNPfVkyoH8uFkx",
            "ssh_host_key_rsa_public": "AAAAB3NzaC1yc2EAAAADAQABAAABAQCyHMnMPiznpKbgUjE2O0MdJH7vIRq67mLe9B5zewz4dzMmfjyBe6vheCtp3xRpM4BoLGcJQp/wwgJzxLKR2WhoBpNfDd4odkNlS/Gs1GaT/m5uvEu+tanizUvwJQ5ME4LAylx/+rmtyxyfsNmZI0AiN4+4FqI1w2YwQ0L/9S+T6h1/K/dX3t6IwwQ+Xz+IBn92o6LlYmWOnUSyKZX9Mdj9ER18GGjErAF3UKh97SeSqNItPbH/X/qHqS4tJLhuUHjV8f2ZlRtQAQIUEthNuU7jq3EQ/mNJFih1A5QWnmNLiWYCqfVqoAdnclmFWij8oGPTJjok38bVhFYXFoPKw4zB",
            "swapfree_mb": 20412,
            "swaptotal_mb": 20479,
            "system": "Linux",
            "system_vendor": "Microsoft Corporation",
            "uptime_seconds": 445585,
            "user_dir": "/root",
            "user_gecos": "root",
            "user_gid": 0,
            "user_id": "root",
            "user_shell": "/bin/bash",
            "user_uid": 0,
            "userspace_architecture": "x86_64",
            "userspace_bits": "64",
            "virtualization_role": "guest",
            "virtualization_type": "VirtualPC"
        },
        "ansible_fibre_channel_wwn": [],
        "ansible_fips": false,
        "ansible_forks": 5,
        "ansible_form_factor": "Desktop",
        "ansible_fqdn": "x00scs00l373.internal.cloudapp.net",
        "ansible_host": "10.1.1.42",
        "ansible_hostname": "x00scs00l373",
        "ansible_hostnqn": "",
        "ansible_interfaces": [
            "lo",
            "eth0"
        ],
        "ansible_inventory_sources": [
            "/home/azureadm/Azure_SAP_Automated_Deployment/WORKSPACES/SAP_SYSTEM/NP-EUS2-SAP00-X00/ansible_config_files/new-hosts2.yaml"
        ],
        "ansible_is_chroot": false,
        "ansible_iscsi_iqn": "iqn.1996-04.de.suse:01:a03cdffc3eed",
        "ansible_kernel": "4.12.14-122.54-default",
        "ansible_lo": {
            "active": true,
            "device": "lo",
            "features": {
                "esp_hw_offload": "off [fixed]",
                "esp_tx_csum_hw_offload": "off [fixed]",
                "fcoe_mtu": "off [fixed]",
                "generic_receive_offload": "on",
                "generic_segmentation_offload": "on",
                "highdma": "on [fixed]",
                "hw_tc_offload": "off [fixed]",
                "l2_fwd_offload": "off [fixed]",
                "large_receive_offload": "off [fixed]",
                "loopback": "on [fixed]",
                "netns_local": "on [fixed]",
                "ntuple_filters": "off [fixed]",
                "receive_hashing": "off [fixed]",
                "rx_all": "off [fixed]",
                "rx_checksumming": "on [fixed]",
                "rx_fcs": "off [fixed]",
                "rx_gro_hw": "off [fixed]",
                "rx_udp_tunnel_port_offload": "off [fixed]",
                "rx_vlan_filter": "off [fixed]",
                "rx_vlan_offload": "off [fixed]",
                "rx_vlan_stag_filter": "off [fixed]",
                "rx_vlan_stag_hw_parse": "off [fixed]",
                "scatter_gather": "on",
                "tcp_segmentation_offload": "on",
                "tls_hw_record": "off [fixed]",
                "tls_hw_rx_offload": "off [fixed]",
                "tls_hw_tx_offload": "off [fixed]",
                "tx_checksum_fcoe_crc": "off [fixed]",
                "tx_checksum_ip_generic": "on [fixed]",
                "tx_checksum_ipv4": "off [fixed]",
                "tx_checksum_ipv6": "off [fixed]",
                "tx_checksum_sctp": "on [fixed]",
                "tx_checksumming": "on",
                "tx_esp_segmentation": "off [fixed]",
                "tx_fcoe_segmentation": "off [fixed]",
                "tx_gre_csum_segmentation": "off [fixed]",
                "tx_gre_segmentation": "off [fixed]",
                "tx_gso_partial": "off [fixed]",
                "tx_gso_robust": "off [fixed]",
                "tx_ipxip4_segmentation": "off [fixed]",
                "tx_ipxip6_segmentation": "off [fixed]",
                "tx_lockless": "on [fixed]",
                "tx_nocache_copy": "off [fixed]",
                "tx_scatter_gather": "on [fixed]",
                "tx_scatter_gather_fraglist": "on [fixed]",
                "tx_sctp_segmentation": "on",
                "tx_tcp6_segmentation": "on",
                "tx_tcp_ecn_segmentation": "on",
                "tx_tcp_mangleid_segmentation": "on",
                "tx_tcp_segmentation": "on",
                "tx_udp_segmentation": "off [fixed]",
                "tx_udp_tnl_csum_segmentation": "off [fixed]",
                "tx_udp_tnl_segmentation": "off [fixed]",
                "tx_vlan_offload": "off [fixed]",
                "tx_vlan_stag_hw_insert": "off [fixed]",
                "udp_fragmentation_offload": "off",
                "vlan_challenged": "on [fixed]"
            },
            "hw_timestamp_filters": [],
            "ipv4": {
                "address": "127.0.0.1",
                "broadcast": "host",
                "netmask": "255.0.0.0",
                "network": "127.0.0.0"
            },
            "ipv6": [
                {
                    "address": "::1",
                    "prefix": "128",
                    "scope": "host"
                }
            ],
            "mtu": 65536,
            "promisc": false,
            "timestamping": [
                "tx_software",
                "rx_software",
                "software"
            ],
            "type": "loopback"
        },
        "ansible_local": {},
        "ansible_lsb": {},
        "ansible_lvm": {
            "lvs": {
                "lv_sapmnt": {
                    "size_g": "128.00",
                    "vg": "vg_sap"
                },
                "lv_usrsap": {
                    "size_g": "64.00",
                    "vg": "vg_sap"
                },
                "lv_usrsapinstall": {
                    "size_g": "320.00",
                    "vg": "vg_sap"
                }
            },
            "pvs": {
                "/dev/sdc": {
                    "free_g": "0",
                    "size_g": "512.00",
                    "vg": "vg_sap"
                }
            },
            "vgs": {
                "vg_sap": {
                    "free_g": "0",
                    "num_lvs": "3",
                    "num_pvs": "1",
                    "size_g": "512.00"
                }
            }
        },
        "ansible_machine": "x86_64",
        "ansible_machine_id": "c5dd3fea0008780c67ff5cc15fd20e2f",
        "ansible_memfree_mb": 15502,
        "ansible_memory_mb": {
            "nocache": {
                "free": 15806,
                "used": 226
            },
            "real": {
                "free": 15502,
                "total": 16032,
                "used": 530
            },
            "swap": {
                "cached": 4,
                "free": 20412,
                "total": 20479,
                "used": 67
            }
        },
        "ansible_memtotal_mb": 16032,
        "ansible_mounts": [
            {
                "block_available": 234514,
                "block_size": 4096,
                "block_total": 259584,
                "block_used": 25070,
                "device": "/dev/sda3",
                "fstype": "xfs",
                "inode_available": 523662,
                "inode_total": 524288,
                "inode_used": 626,
                "mount": "/boot",
                "options": "rw,relatime,attr2,inode64,noquota",
                "size_available": 960569344,
                "size_total": 1063256064,
                "uuid": "b658aa52-6080-43a0-9b17-57fad496a24f"
            },
            {
                "block_available": 65365,
                "block_size": 8192,
                "block_total": 65501,
                "block_used": 136,
                "device": "/dev/sda2",
                "fstype": "vfat",
                "inode_available": 0,
                "inode_total": 0,
                "inode_used": 0,
                "mount": "/boot/efi",
                "options": "rw,relatime,fmask=0022,dmask=0022,codepage=437,iocharset=iso8859-1,shortname=mixed,errors=remount-ro",
                "size_available": 535470080,
                "size_total": 536584192,
                "uuid": "E7C1-9C93"
            },
            {
                "block_available": 6873122,
                "block_size": 4096,
                "block_total": 7466684,
                "block_used": 593562,
                "device": "/dev/sda4",
                "fstype": "xfs",
                "inode_available": 14818673,
                "inode_total": 14940608,
                "inode_used": 121935,
                "mount": "/",
                "options": "rw,relatime,attr2,inode64,noquota",
                "size_available": 28152307712,
                "size_total": 30583537664,
                "uuid": "af42ae91-56c6-4ee1-a8c8-79c68f3bba49"
            },
            {
                "block_available": 2545008,
                "block_size": 4096,
                "block_total": 8223684,
                "block_used": 5678676,
                "device": "/dev/sdb1",
                "fstype": "ext4",
                "inode_available": 2097139,
                "inode_total": 2097152,
                "inode_used": 13,
                "mount": "/mnt",
                "options": "rw,relatime,data=ordered",
                "size_available": 10424352768,
                "size_total": 33684209664,
                "uuid": "d1a3489e-91e6-469d-ad14-0d62d4ae7579"
            },
            {
                "block_available": 82793296,
                "block_size": 4096,
                "block_total": 83844097,
                "block_used": 1050801,
                "device": "/dev/mapper/vg_sap-lv_usrsapinstall",
                "fstype": "xfs",
                "inode_available": 167770099,
                "inode_total": 167770112,
                "inode_used": 13,
                "mount": "/usr/sap/install",
                "options": "rw,relatime,attr2,inode64,noquota",
                "size_available": 339121340416,
                "size_total": 343425421312,
                "uuid": "98b09423-3006-44a1-a2dd-c9f650e2463b"
            },
            {
                "block_available": 16760756,
                "block_size": 4096,
                "block_total": 16769024,
                "block_used": 8268,
                "device": "/dev/mapper/vg_sap-lv_usrsap",
                "fstype": "xfs",
                "inode_available": 33554427,
                "inode_total": 33554432,
                "inode_used": 5,
                "mount": "/usr/sap",
                "options": "rw,relatime,attr2,inode64,noquota",
                "size_available": 68652056576,
                "size_total": 68685922304,
                "uuid": "3e62d488-0fdb-4cb4-9786-9264b551357a"
            },
            {
                "block_available": 33529788,
                "block_size": 4096,
                "block_total": 33538048,
                "block_used": 8260,
                "device": "/dev/mapper/vg_sap-lv_sapmnt",
                "fstype": "xfs",
                "inode_available": 67108860,
                "inode_total": 67108864,
                "inode_used": 4,
                "mount": "/sapmnt",
                "options": "rw,relatime,attr2,inode64,noquota",
                "size_available": 137338011648,
                "size_total": 137371844608,
                "uuid": "dc442871-6ebc-4f8d-8da3-12a7b2e48b4a"
            }
        ],
        "ansible_nodename": "x00scs00l373",
        "ansible_os_family": "Suse",
        "ansible_pkg_mgr": "zypper",
        "ansible_playbook_python": "/usr/bin/python3",
        "ansible_proc_cmdline": {
            "BOOT_IMAGE": "/vmlinuz-4.12.14-122.54-default",
            "USE_BY_UUID_DEVICE_NAMES": "1",
            "console": "ttyS0",
            "dis_ucode_ldr": true,
            "earlyprintk": "ttyS0",
            "multipath": "off",
            "net.ifnames": "0",
            "root": "UUID=af42ae91-56c6-4ee1-a8c8-79c68f3bba49",
            "rootdelay": "300",
            "rw": true,
            "scsi_mod.use_blk_mq": "1"
        },
        "ansible_processor": [
            "0",
            "GenuineIntel",
            "Intel(R) Xeon(R) CPU E5-2673 v4 @ 2.30GHz",
            "1",
            "GenuineIntel",
            "Intel(R) Xeon(R) CPU E5-2673 v4 @ 2.30GHz",
            "2",
            "GenuineIntel",
            "Intel(R) Xeon(R) CPU E5-2673 v4 @ 2.30GHz",
            "3",
            "GenuineIntel",
            "Intel(R) Xeon(R) CPU E5-2673 v4 @ 2.30GHz"
        ],
        "ansible_processor_cores": 2,
        "ansible_processor_count": 1,
        "ansible_processor_threads_per_core": 2,
        "ansible_processor_vcpus": 4,
        "ansible_product_name": "Virtual Machine",
        "ansible_product_serial": "0000-0017-7437-9893-9723-1229-18",
        "ansible_product_uuid": "20A33EF6-2600-E648-B405-EF3C9E9B6E4F",
        "ansible_product_version": "7.0",
        "ansible_python": {
            "executable": "/usr/bin/python",
            "has_sslcontext": true,
            "type": "CPython",
            "version": {
                "major": 2,
                "micro": 17,
                "minor": 7,
                "releaselevel": "final",
                "serial": 0
            },
            "version_info": [
                2,
                7,
                17,
                "final",
                0
            ]
        },
        "ansible_python_version": "2.7.17",
        "ansible_real_group_id": 0,
        "ansible_real_user_id": 0,
        "ansible_run_tags": [
            "all"
        ],
        "ansible_selinux": {
            "status": "Missing selinux Python library"
        },
        "ansible_selinux_python_present": false,
        "ansible_service_mgr": "systemd",
        "ansible_skip_tags": [],
        "ansible_ssh_host_key_dsa_public": "AAAAB3NzaC1kc3MAAACBAMGFNpIkKprb0hbA5fdksMGr4D5Yepcnjl65LA8iVPAoXNSYiVIZlTToAgMalPD5Sa7Ijy0dPr8f0/l6X1xSKuxv1EIQ38D48qdPeCnrb6wE1ajjc8n3Nx8Ar8ji9QU+WN76u9S3Ms3Mdjm8tABpIVfBV3OFXRjfVQWqYiMJW6ShAAAAFQDFTeAb5pDpSpie1gH9iCuMU5GjrQAAAIEApOF11cAWYScqrK7bIVdrjvHV5d4Rh1vljhOpGDdcUlF7fMG5s94umcG3uaMWe2V9+hzq3Wj14kg7tZ1/5sODYOJ8tyMl83+n01AyRGyjrVl3ALlEbpJuR2RZUAgLZhmMQ8K7T97DAYIiUfQjy8fOCy1N6hbby3MfqXu2+SEZK1QAAACAJplnAxH/+5lWxjhYDrUuPl0rxP/PnPCvfsk13MlIa7BzYTgtgjZWDrpuK27DHV1CaLHkYMlpFa54oVyCk53onv59LOiIO9GEzJIbO0OKrKyVx5hTU1GV6ef8Y/QwvF5t/YvgEtlAN52JBN+SODC6+QOGldCDA/UDPT7b4UpgHag=",
        "ansible_ssh_host_key_ecdsa_public": "AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBLf4pGg+8Bmhrw/TzNw0xHRQGQSkRRlRDDFlm5RZNX836riQzCT7uJNOYaJ1qJwAO/y+0GBS4paFH2U8RIG62kY=",
        "ansible_ssh_host_key_ed25519_public": "AAAAC3NzaC1lZDI1NTE5AAAAIERZpXlAS7/t9ur02+EtbeAK7cIRrLyNPfVkyoH8uFkx",
        "ansible_ssh_host_key_rsa_public": "AAAAB3NzaC1yc2EAAAADAQABAAABAQCyHMnMPiznpKbgUjE2O0MdJH7vIRq67mLe9B5zewz4dzMmfjyBe6vheCtp3xRpM4BoLGcJQp/wwgJzxLKR2WhoBpNfDd4odkNlS/Gs1GaT/m5uvEu+tanizUvwJQ5ME4LAylx/+rmtyxyfsNmZI0AiN4+4FqI1w2YwQ0L/9S+T6h1/K/dX3t6IwwQ+Xz+IBn92o6LlYmWOnUSyKZX9Mdj9ER18GGjErAF3UKh97SeSqNItPbH/X/qHqS4tJLhuUHjV8f2ZlRtQAQIUEthNuU7jq3EQ/mNJFih1A5QWnmNLiWYCqfVqoAdnclmFWij8oGPTJjok38bVhFYXFoPKw4zB",
        "ansible_swapfree_mb": 20412,
        "ansible_swaptotal_mb": 20479,
        "ansible_system": "Linux",
        "ansible_system_vendor": "Microsoft Corporation",
        "ansible_uptime_seconds": 445585,
        "ansible_user_dir": "/root",
        "ansible_user_gecos": "root",
        "ansible_user_gid": 0,
        "ansible_user_id": "root",
        "ansible_user_shell": "/bin/bash",
        "ansible_user_uid": 0,
        "ansible_userspace_architecture": "x86_64",
        "ansible_userspace_bits": "64",
        "ansible_verbosity": 0,
        "ansible_version": {
            "full": "2.8.17",
            "major": 2,
            "minor": 8,
            "revision": 17,
            "string": "2.8.17"
        },
        "ansible_virtualization_role": "guest",
        "ansible_virtualization_type": "VirtualPC",
        "azure_files_mount_path": "/sapmnt",
        "bom_base_name": "HANA_2_00_053_v001",
        "components": "{{ lookup('file', configs_path + '/components.json') }}",
        "conf_change": {
            "backup": "",
            "changed": false,
            "diff": [
                {
                    "after": "",
                    "after_header": "/etc/waagent.conf (content)",
                    "before": "",
                    "before_header": "/etc/waagent.conf (content)"
                },
                {
                    "after_header": "/etc/waagent.conf (file attributes)",
                    "before_header": "/etc/waagent.conf (file attributes)"
                }
            ],
            "failed": false,
            "msg": ""
        },
        "configs_path": "~/Azure_SAP_Automated_Deployment/sap-hana/deploy/configs",
        "discovered_interpreter_python": "/usr/bin/python",
        "disk_dict": {},
        "download_templates": false,
        "gather_subset": [
            "all"
        ],
        "group_names": [
            "X00_SCS"
        ],
        "groups": {
            "X00_APP": [
                "x00app01l373",
                "x00app02l373"
            ],
            "X00_DB": [
                "x00dhdb00l0373"
            ],
            "X00_PAS": [
                "x00app00l373"
            ],
            "X00_SCS": [
                "x00scs00l373"
            ],
            "X00_WEB": [],
            "X99_APP": [
                "x99app01l373",
                "x99app02l373"
            ],
            "X99_DB": [
                "x99dhdb00l0373"
            ],
            "X99_PAS": [
                "x99app00l373"
            ],
            "X99_SCS": [
                "x99scs00l373"
            ],
            "X99_WEB": [],
            "all": [
                "x00dhdb00l0373",
                "x00scs00l373",
                "x00app00l373",
                "x00app01l373",
                "x00app02l373",
                "x99dhdb00l0373",
                "x99scs00l373",
                "x99app00l373",
                "x99app01l373",
                "x99app02l373"
            ],
            "ungrouped": []
        },
        "hana_database": "{{ hostvars['localhost'].hana_database }}",
        "hana_install_path": "/hana/shared/{{ hana_database.instance.sid }}/install",
        "hana_software_loc": "{{ azure_files_mount_path }}/DB/DATA_UNITS",
        "hdb_comp_list": [],
        "inventory_dir": "/home/azureadm/Azure_SAP_Automated_Deployment/WORKSPACES/SAP_SYSTEM/NP-EUS2-SAP00-X00/ansible_config_files",
        "inventory_file": "/home/azureadm/Azure_SAP_Automated_Deployment/WORKSPACES/SAP_SYSTEM/NP-EUS2-SAP00-X00/ansible_config_files/new-hosts2.yaml",
        "inventory_hostname": "x00scs00l373",
        "inventory_hostname_short": "x00scs00l373",
        "jumpbox_comp_dict": {},
        "linux_comp_list": [],
        "linux_jumpboxes": "{{ hostvars['localhost'].output.jumpboxes.linux }}",
        "module_setup": true,
        "omit": "__omit_place_holder__b95644b92b06f25ebfbd9a4515506316a27d657f",
        "output": "{{ hostvars['localhost'].output }}",
        "packages": {
            "RedHat": [
                "@base",
                "gtk2",
                "libicu",
                "xulrunner",
                "sudo",
                "tcsh",
                "libssh2",
                "expect",
                "cairo",
                "graphviz",
                "iptraf-ng",
                "krb5-workstation",
                "krb5-libs",
                "libpng12",
                "nfs-utils",
                "lm_sensors",
                "rsyslog",
                "openssl",
                "PackageKit-gtk3-module",
                "libcanberra-gtk2",
                "libtool-ltdl",
                "xorg-x11-xauth",
                "numactl",
                "xfsprogs",
                "net-tools",
                "bind-utils",
                "chrony",
                "ntp",
                "gdisk",
                "sg3_utils",
                "lvm2",
                "ntpdate",
                "tuned-profiles-sap-hana",
                "numad",
                "cifs-utils",
                "compat-sap-c++-5"
            ],
            "Suse": [
                "libyui-qt-pkg7",
                "sapconf",
                "saptune",
                "glibc",
                "systemd",
                "tuned",
                "ntp",
                "numad"
            ]
        },
        "playbook_dir": "/home/azureadm/Azure_SAP_Automated_Deployment/centiq-sap-hana/deploy/ansible",
        "sap_filesystems": [
            {
                "dev": "/dev/vg_sap/lv_usrsap",
                "fstype": "xfs",
                "mount_path": "/usr/sap",
                "tier": "all"
            },
            {
                "dev": "/dev/vg_sap/lv_sapmnt",
                "fstype": "xfs",
                "mount_path": "/sapmnt",
                "tier": "SCS"
            },
            {
                "dev": "/dev/vg_sap/lv_usrsapinstall",
                "fstype": "xfs",
                "mount_path": "/usr/sap/install",
                "tier": "SCS"
            },
            {
                "dev": "/dev/vg_sap/lv_sapmnt",
                "fstype": "xfs",
                "mount_path": "/sapmnt",
                "tier": "WEB"
            }
        ],
        "sap_logical_volumes": [
            {
                "lv": "lv_usrsap",
                "opts": "",
                "size": "64g",
                "tier": "all",
                "vg": "vg_sap"
            },
            {
                "lv": "lv_sapmnt",
                "opts": "",
                "size": "128g",
                "tier": "SCS",
                "vg": "vg_sap"
            },
            {
                "lv": "lv_usrsapinstall",
                "opts": "",
                "size": "100%FREE",
                "tier": "SCS",
                "vg": "vg_sap"
            },
            {
                "lv": "lv_sapmnt",
                "opts": "",
                "size": "1g",
                "tier": "WEB",
                "vg": "vg_sap"
            }
        ],
        "sap_sid": "X00",
        "sap_swap": [
            {
                "swap_size_mb": "20480",
                "tier": "SCS"
            },
            {
                "swap_size_mb": "20480",
                "tier": "PAS"
            },
            {
                "swap_size_mb": "20480",
                "tier": "APP"
            },
            {
                "swap_size_mb": "20480",
                "tier": "WEB"
            },
            {
                "swap_size_mb": "2048",
                "tier": "HANA"
            }
        ],
        "sap_volume_groups": [
            {
                "pvs": "/dev/disk/azure/scsi1/lun0",
                "tier": "all",
                "vg": "vg_sap"
            }
        ],
        "sapbits_bom_files": "sapfiles",
        "sapbits_location_base_path": "https://npeus2saplib4b2.blob.core.windows.net/sapbits",
        "start": 0,
        "target_media_location": "/usr/sap/install",
        "tier": "SCS",
        "windows_comp_list": [],
        "windows_jumpboxes": "{{ hostvars['localhost'].output.jumpboxes.windows }}"
    }
}
```