library(shiny)
library(shinydashboard)
library(apexcharter)
library(connectapi)

client <- connect()

days_back <- as.numeric(Sys.getenv("DAYSBACK", 90))
cache_location <- Sys.getenv("MEMOISE_CACHE_LOCATION", tempdir())
message(cache_location)
report_from <- lubridate::today() - lubridate::ddays(days_back)
report_to <- lubridate::today()

# TODO: better way to do caching...?
cached_usage_shiny <- memoise::memoise(
  get_usage_shiny,
  cache = memoise::cache_filesystem(cache_location),
  omit_args = c("src") # BEWARE: cache can cross connect hosts if you change connect targets
)

cached_usage_static <- memoise::memoise(
  get_usage_static,
  cache = memoise::cache_filesystem(cache_location),
  omit_args = c("src") # BEWARE: cache can cross connect hosts if you change connect targets
)

# Data Fetch -------------------------------------------------------------

# Must include "to" or the cache can get weird!!
data_shiny <- cached_usage_shiny(client, from = report_from, to = report_to, limit = Inf)
data_static <- cached_usage_static(client, from = report_from, to = report_to, limit = Inf) # ~ 3 minutes on a busy server... 😱
data_content <- get_content(client)
data_users <- get_users(client, limit = Inf)

ui <- dashboardPage(
  dashboardHeader(),
  dashboardSidebar(),
  dashboardBody(
    fluidRow(
      apexchartOutput("shiny_time")
    ),
    fluidRow(
      box(
        apexchartOutput("shiny_content"),
        width = 4,
      ),
      box(
        apexchartOutput("shiny_viewer"),
        width = 4,
      ),
      box(
        apexchartOutput("shiny_owner"),
        width = 4,
      )
    ),
    fluidRow(
      verbatimTextOutput("verbatim")
    )
  )
)

safe_filter <- function(data, min_date = NULL, max_date = NULL) {
  data_prep <- data
  if (!is.null(min_date)) {
    data_prep <- data_prep %>% filter(started >= min_date)
  }
  if (!is.null(max_date)) {
    data_prep <- data_prep %>% filter(started <= max_date + 1)
  }
  
  return(data_prep)
}

server <- function(input, output, session) {
  

  # Data Prep -------------------------------------------------------------
  
  shiny_content <- reactive(
    data_shiny %>%
      safe_filter(min_date = minTime(), max_date = maxTime()) %>%
      group_by(content_guid) %>%
      tally() %>%
      left_join(
        data_content %>% select(guid, name, title, description),
        by = c(content_guid = "guid")
      ) %>%
      filter(!is.na(title)) %>%
      arrange(desc(n))
  )
  
  shiny_viewers <- reactive(
    data_shiny %>%
      safe_filter(min_date = minTime(), max_date = maxTime()) %>%
      group_by(user_guid) %>%
      tally() %>%
      left_join(
        data_users %>% select(guid, username),
        by = c(user_guid = "guid")
      ) %>%
      arrange(desc(n))
  )
  
  shiny_owners <- reactive(
    data_shiny %>%
      safe_filter(min_date = minTime(), max_date = maxTime()) %>%
      left_join(
        data_content %>% select(guid, owner_guid),
        by = c(content_guid = "guid")
      ) %>%
      filter(!is.na(owner_guid)) %>% # remove content that was deleted
      group_by(owner_guid) %>%
      tally() %>%
      left_join(
        data_users %>% select(guid, username),
        by = c(owner_guid = "guid")
      ) %>% 
      arrange(desc(n))
  )
  
  shiny_over_time <- reactive(
    data_shiny %>%
      mutate(
        date = lubridate::as_date(lubridate::floor_date(started, "day")),
      ) %>%
      group_by(date) %>%
      tally() %>%
      mutate(
        date_disp = format(date, format="%a %b %d %Y")
      ) %>%
      arrange(date)
  )
  
  # Observers for Selection ----------------------------------------------------------
  
  minTime <- reactiveVal(report_from)
  maxTime <- reactiveVal(report_to)
  
  observeEvent(input$time, {
    input_min <- lubridate::as_date(input$time[[1]]$min)
    input_max <- lubridate::as_date(input$time[[1]]$max)
    # TODO: a way to "deselect" the time series
    if (identical(input_min, input_max)) {
      # treat "equals" as nothing selected
      minTime(report_from)
      maxTime(report_to)
    } else {
      minTime(input_min)
      maxTime(input_max)
    }
  })
  
  # Graph output ----------------------------------------------------------
  
  output$shiny_time <- renderApexchart(
    apexchart(auto_update = FALSE) %>%
      ax_chart(type = "line") %>%
      ax_plotOptions() %>%
      ax_series(list(
        name = "Count",
        data = purrr::map2(shiny_over_time()$date_disp, shiny_over_time()$n, ~ list(.x,.y))
      )) %>%
      ax_xaxis(
        type = "datetime"
      ) %>%
      set_input_selection("time")
  )
  
  output$shiny_content <- renderApexchart(
    apex(
      data = shiny_content() %>% head(20), 
      type = "bar", 
      mapping = aes(title, n)
    ) %>%
      set_input_click("content")
  )
  
  output$shiny_viewer <- renderApexchart(
    apex(
      data = shiny_viewers() %>% head(20), 
      type = "bar", 
      mapping = aes(username, n)
    ) %>%
      set_input_click("viewer")
  )
  
  output$shiny_owner <- renderApexchart(
    apex(
      data = shiny_owners() %>% head(20), 
      type = "bar", 
      mapping = aes(username, n)
    ) %>%
      set_input_click("owner")
  )
  
  output$verbatim <- renderText(capture.output(str(input$time), str(minTime()), str(maxTime()), str(input$content), str(input$viewer), str(input$owner)))
  
}

shinyApp(ui = ui, server = server)
