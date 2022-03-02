library(shiny)
library(apexcharter)
library(connectapi)
library(dplyr)
library(tidyr)

client <- connect()

report_from <- lubridate::now() - lubridate::dhours(2)


get_usage_cumulative <- function(client) {
  raw_data <- connectapi::get_usage_shiny(client, from = report_from, limit = Inf)
  prep <- raw_data %>%
    filter(started >= report_from) %>%
    arrange(started, ended) %>%
    mutate(row_id = row_number()) %>%
    filter(!is.na(started)) # should never happen
  
  tall_dat <- prep %>%
    gather(key = "type", value = "ts", started, ended) %>%
    mutate(value = case_when(type == "started" ~ 1, type == "ended" ~ -1)) %>% 
    filter(!is.na(ts)) %>%
    arrange(ts) %>%
    mutate(n = cumsum(value)) %>%
    mutate(
      ts_disp = format(ts, format="%Y-%m-%dT%H:%M:%S")
    )
  
  return(tall_dat)
}

get_usage <- function(client) {
  raw_data <- connectapi::get_usage_shiny(client, from = report_from, limit = Inf)
  message(glue::glue("Got {nrow(raw_data)} records"))
  prep <- raw_data %>%
    filter(started >= report_from) %>%
    mutate(ts = lubridate::floor_date(started, "minute")) %>%
    group_by(ts) %>%
    tally() %>%
    mutate(
      ts_disp = format(ts, format="%Y-%m-%dT%H:%M:%S")
    ) %>%
    arrange(ts)
  
}

ui <- fluidPage(
  apexchartOutput("shiny_realtime")
)

server <- function(input, output) {
  
  data_today <- reactiveVal(get_usage_cumulative(client))
  
  observe({
    data_today(get_usage_cumulative(client))
    invalidateLater(10000)
  })
  
  output$shiny_realtime <- renderApexchart(
    apexchart(auto_update = TRUE) %>%
      ax_chart(type = "line") %>%
      ax_title("By Minute") %>%
      ax_plotOptions() %>%
      ax_series(list(
        name = "Count",
        data = purrr::map2(data_today()$ts_disp, data_today()$n, ~ list(.x, .y))
      )) %>%
    ax_xaxis(
      type = "datetime"
    )
  )
}

shinyApp(ui = ui, server = server)
