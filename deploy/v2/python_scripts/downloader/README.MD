# SMP Downloader
This downloader is to download bits from SMP
SMP stands for Service Market Place
DLM stands for Download Manager

## Table of Contents
- [How to Run](#HowToRun)
- [FileStructure](#FileStructure)
- [Workflow](#Workflow)

## HowToRun
- add SMP credentials to JSON files `(hdb.json`, `s4.json` are examples for different scenarios).
- `python3 basket.py --help` : check required inputs
- `--config <name of the json>` : Mandatory. It triggers download of bits according to SAP_Scenarios.py and JSON input files
- `--basket`: If set, it triggers download of bits according to SAP_Scenarios.py and JSON input files + the latest files (add in one shot into the basket) from SMP download basket.
- `--dryrun True`: If set, it triggers the download without actually download the bits.

## FileStructure
├───deploy
│   ├───v2
│   │   ├───python_scripts
│   │   │   └───downloader
│   │   │           basket.py
│   │   │           hdb.json
│   │   │           helper.py
│   │   │           s4.json
│   │   │           SAP_DLM.py
│   │   │           SAP_Scenarios.py
│   │   │           SAP_SMP.py

## Workflow
