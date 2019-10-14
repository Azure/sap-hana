# SMP Downloader
This downloader is to download bits from SMP
SMP stands for Service Market Place
DLM stands for Download Manager

## Table of Contents
- [How to Run](#HowToRun)
- [Workflow](#Workflow)

## HowToRun
- add SMP credentials to JSON files `(hdb.json`, `s4.json` are examples for different scenarios).
- `python3 basket.py --help` : check required inputs
- `--config <name of the json>` : Mandatory. It triggers download of bits according to SAP_Scenarios.py and JSON input files
- `--basket`: If set, it triggers download of bits according to SAP_Scenarios.py and JSON input files + the latest files (add in one shot into the basket) from SMP download basket.
- `--dryrun`: If set, it triggers the download without actually download the bits.

## Workflow
![workflow](https://user-images.githubusercontent.com/38501271/66783833-9e96e780-ee8d-11e9-8efa-d1e0d5fc1348.JPG)
