# Inspired by: https://drsimonj.svbtle.com/creating-corporate-colour-palettes-for-ggplot2

#' RStudio ggplot2 Theme
#' @import ggplot2
#' @export
theme_rstudio <- function() {
  theme_minimal(base_size = 12, base_family = "sans") %+replace%
    theme(
      plot.title = element_text(size = 14, margin = margin(b = 1, unit = "cm"), hjust = 0),
      title = element_text(color = '#585858'),
      legend.direction = 'horizontal',
      legend.position = 'bottom'
    )
}


rstudio_cols <- c(
  blue ="#75aadb",
  darkblue ="#4c83b6",
  lightblue ="#e3eef8",
  lightgrey ="#f8f8f8",
  superlightgrey ="#e0e0e0",
  mediumgrey ="#c8c8c8",
  mediumdarkgrey ="#a0a0a0",
  darkgrey ="#585858",
  orange  ="#e6553a",
  darkorange ="#d54a30",
  brown ="#5d4c45",
  darkbrown ="#4d3c35",
  lightbrown ="#8d817c",
  yellow ="#fcbf49",
  darkyellow ="#f9b02d",
  green ="#a3c586",
  darkgreen ="#789d57"
)


#' Return RStudio Color Values
#'
#' @param ... Pass in the names of the desired colors. To see available color
#'   names, run the function with no arguments.
#'
#' @export
get_rstudio_cols <- function(...) {
  cols <- c(...)
  
  if (is.null(cols))
    return(rstudio_cols)
  
  rstudio_cols[cols]
}

rstudio_pals <- list(
  main = get_rstudio_cols('blue', 'green','orange', 'yellow'),
  grey = get_rstudio_cols('mediumgrey','mediumdarkgrey', 'darkgrey'),
  cool = get_rstudio_cols('lightblue', 'blue', 'mediumdarkgrey', 'darkgrey')
)

get_rstudio_pal <- function(palette = "main",  ...) {
  pal <- rstudio_pals[[palette]]
  grDevices::colorRampPalette(pal, ...)
}

#' RStudio Color Scheme
#'
#' @param palette One of main, grey, or cool
#' @param discrete Whether or not the color aesthetic is discrete or numeric.
#' @param ... Other arguments to \code(discrete_scale) or
#'   \code(scale_color_gradient)
#'
#' @export
scale_color_rstudio <- function(palette = "main", discrete = TRUE, ...) {
  pal <- get_rstudio_pal(palette)
  if (discrete) {
    discrete_scale("colour" , paste0('rstudio_', palette), pal, ...)
  } else {
    scale_color_gradientn(colours = pal(256), ...)
  }
}

#' RStudio Fill Scheme
#'
#' @param palette One of main, grey, or cool
#' @param discrete Whether or not the fill aesthetic is discrete or numeric.
#' @param ... Other arguments to \code(discrete_scale) or
#'   \code(scale_fill_gradient)
#'
#' @export
scale_fill_rstudio <- function(palette = "main", discrete = TRUE, ...) {
  pal <- get_rstudio_pal(palette)
  if (discrete) {
    discrete_scale("fill" , paste0('rstudio_', palette), pal, ...)
  } else {
    scale_fill_gradientn(colours = pal(256), ...)
  }
}
