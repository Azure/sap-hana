/*-----------------------------------------------------------------------------8
|                                                                              |
|                              TERRAFORM VERSION                               |
|                                                                              |
+--------------------------------------4--------------------------------------*/
terraform                               { required_version = ">= 0.12"  }


/*-----------------------------------------------------------------------------8
|                                                                              |
|                                  PROVIDERS                                   |
|                                                                              |
+--------------------------------------4--------------------------------------*/
provider azurerm                        { version = "~> 1.0"    }
