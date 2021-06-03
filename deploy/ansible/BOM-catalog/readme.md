
| Label    | Format                   | Description   |
| -------- | ------------------------ | ------------- |
| BOM Name | \<PRODUCT\>_v####ms      | <table><tr><td>\<PRODUCT\></td><td>Ex. S41909SPS03 for S/4 1909 SPS 03.</td></tr><tr><td>####</td><td>a serial version number for a product BOM.</td></tr><tr><td>ms</td><td>denotes a Microsoft Supplied BOM.</td></tr></table>|
| BOM File | \<PRODUCT\>_v####ms.yaml | |

<br/><br/><br/>
BOM Catalog Directory Structure
```
<root>
  +-  <PRODUCT>_v####ms                                BOM NAME
        +-  <PRODUCT>_v####ms.yaml                     BOM File
        +-  stackfiles
              +-  plan xls
              +-  plan pdf
              +-  stack txt
              +-  stack xml
              +-  download txt
              +-  plan media list txt
              +-  plan media links txt
        +-  templates
              +-  <PRODUCT>_v####ms.j2                 template file
```