locals {

  ppg_names = local.zonal_deployment ? (
    [for idx in range(length(local.zones)) :
      format("-z%s%s", local.zones[idx], "-ppg")
    ]) : (
    [format("%s", "-ppg")]
  )

  app_avset_names = local.zonal_deployment ? (
    [for idx in range(length(local.zones)) :
      format("z%s%s", local.zones[idx], "app-avset")
    ]) : (
    [format("%s", "app-avset")]
  )

  scs_avset_names = local.zonal_deployment ? (
    [for idx in range(length(local.zones)) :
      format("z%s%s", local.zones[idx], "scs-avset")
    ]) : (
    [format("%s", "scs-avset")]
  )

  web_avset_names = local.zonal_deployment ? (
    [for idx in range(length(local.zones)) :
      format("z%s%s", local.zones[idx], "web-avset")
    ]) : (
    [format("%s", "web-avset")]
  )

  db_avset_names = local.zonal_deployment ? (
    [for idx in range(length(local.zones)) :
      format("z%s%s", local.zones[idx], "db-avset")
    ]) : (
    [format("%s", "db-avset")]
  )

}