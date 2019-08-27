# RStudio Connect Usage Report

This R Markdown report can be published as-is to your RStudio Connect server or 
used as a starting point for your own analysis. You can schedule the report and 
distribute it via email (the email will include inline graphics!)

Sample Report: http://colorado.rstudio.com/rsc/usage

<center><img src="email-preview.png" width = "400px" height = "400x"></center>

The report is generated using the [RStudio Connect Server API](https://docs.rstudio.com/connect/api). The `helpers.R` file contains example code for querying the various API endpoints. The API and data collection are both available as of RStudio Connect 1.7.0. The API contains data to help answer questions like:

- What content is most visited?
- Who is visiting my content?
- What reports are most common?
- Has viewership increased over time?
- Did my CEO actually visit this app?

**A data science team's time is precious, this data will help you focus and justify your efforts.**

The report uses the environment variables `RSTUDIO_CONNECT_SERVER` and `RSTUDIO_CONNECT_API_KEY` to collect the data. To limit the results to a single publisher, use a publisher API key.

### Common Questions

- Could this be a shiny app instead of a report? Of course! Let us know what you come up with.
- Can I use the API from another language besides R? Absolutely, the API includes a spec to get you started.
- Will you provide an R client for accessing the API? Please start a topic on [RStudio Community](https://community.rstudio.com/c/r-admin) (in the R Admins section) if this sounds interesting.
- What is the `manifest.json` file? This file aids in programmatic deployments, a new RStudio Connect feature.

## Full example

The following example was created to be easily copy/pasted and run in your local R session.  Make sure to update the RStudio Connect server, and have your key available.

```r
library(ggplot2)
library(dplyr)

# Bring the needed functions into your project by copying the helper.R file
if(!file.exists("helpers.R")) {
  helpers <- "https://raw.githubusercontent.com/sol-eng/connect-usage/master/helpers.R"
  writeLines(readLines(helpers), "helpers.R")
}
source("helpers.R")

# Load the Server and API KEY variables
Sys.setenv("RSTUDIO_CONNECT_SERVER"  = "https://colorado.rstudio.com/rsc") # Update with your RSC server name
Sys.setenv("RSTUDIO_CONNECT_API_KEY" = rstudioapi::askForPassword("Enter Connect Token:")) 

# Get and clean the Shiny usage data
shiny_rsc <- get_shiny_usage() %>% 
  clean_data()

# Get the title of each Shiny app
shiny_rsc_names <- shiny_rsc %>%
  count(content_guid) %>% 
  pull(content_guid) %>%
  purrr::map_dfr(~tibble(content_guid = .x, content_name = get_content_name(.x)))

# Calculate the average session duration and sort
app_sessions <- shiny_rsc %>%
  group_by(content_guid) %>%
  summarise(avg_session = mean(session_duration)) %>%
  ungroup() %>%
  arrange(desc(avg_session))
  
# Plot the top 10 used content
app_sessions %>%
  head(10) %>%
  inner_join(shiny_rsc_names, by = "content_guid") %>%
  ggplot(aes(content_name, avg_session)) +
  geom_col() +
  geom_text(aes(y = avg_session + 200, label = round(avg_session)), size = 3) +
  coord_flip() +
  theme_bw() +
  labs(title = "RStudio Connect - Top 10", subtitle = "Shiny Apps", x = "", y = "Average session time (seconds)")
```

<center><img src="ggplot-usage.png" width = "600px" height = "300x"></center>

Here are the glimpses into each stage of the data transformations.  They are presented after the code to allow you to easily copy and paste the full script above.

```r
glimpse(shiny_rsc)
```
```
## Observations: 1,343
## Variables: 6
## $ content_guid     <chr> "7ffb6265-a426-483b-84dd-29b3ffbe86da", "f9f1d131-7c57-4f80-81d8-afa…
## $ user_guid        <chr> "anonymous", "anonymous", "anonymous", "anonymous", "anonymous", "an…
## $ started          <dttm> 2019-07-28 19:40:21, 2019-07-28 21:19:06, 2019-07-28 22:23:36, 2019…
## $ ended            <dttm> 2019-07-28 20:40:41, 2019-07-28 21:20:11, 2019-07-28 22:23:54, 2019…
## $ data_version     <list> [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, …
## $ session_duration <drtn> 3620 secs, 65 secs, 18 secs, 18 secs, 3617 secs, 65 secs, 90 secs, …
```
```r
glimpse(shiny_rsc_names)
```
```
## Observations: 122
## Variables: 2
## $ content_guid <chr> "0076bbb3-429e-4f99-9f85-674b1f8ea3b7", "030de800-7c9f-4d18-a5c4-c87b79a…
## $ content_name <chr> "Bitbucket - Demo", "Pro Admin Training 7-1 exercise: Install RSPM", "Sa…
```
```r
glimpse(app_sessions)
```

```
Observations: 122
Variables: 2
$ content_guid <chr> "b5d0744a-09b0-43e6-974f-73654e47f0b6", "f3da2c68-5ce5-47a5-bd2b-c2a5eeb…
$ avg_session  <drtn> 4790.000 secs, 4264.250 secs, 3645.000 secs, 3617.000 secs, 3617.000 se…
```

Learn more about programmatic deployments, calling the server API, and custom emails [here](https://docs.rstudio.com/user).
