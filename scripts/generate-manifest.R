exclude_projs <- c("connectAnalytics")
all_projs <- fs::dir_ls(rprojroot::find_rstudio_root_file("examples/"))
manifest_projs <- purrr::discard(all_projs, ~ any(stringr::str_detect(.x, exclude_projs)))

purrr::map(
  manifest_projs,
  function(.x) {message(glue::glue("Generating manifest for: {.x}")); rsconnect::writeManifest(.x)}
)
