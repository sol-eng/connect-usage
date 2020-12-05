App Visitation
================
josiah parry
2020-12-05

## Objective

The objective of this report is to be able to quickly identify the usage
of all shiny applications used within a specified date range. This is a
complement to the existing [Connect Usage
Dashboard](https://github.com/sol-eng/connect-usage/tree/master/examples/last_30_days).
The Connect Usage Dashboard provides high level statistics about the
usage of shiny apps across the server. Whereas this report tells us
about each individual app.

## Generating the Report

In this code chunk we connect to an existing pin that contains the
enumeration of all pieces of content on the server. Since fetching this
information can be rather slow depending on the amount of content on the
server, it was collected and stored in a pin ahead of time. By doing so,
we increase the speed of the parameterized report. See
`server-content-list.R`.

In order for this example to work you will need to set two environment
variables called `CONNECT_SERVER` and `CONNECT_API_KEY`. The first is
the address of your connect server, for example
`https://connect.organization.com/`. The second is the API key to the
server. Instructions to retrieve this can be found in the [user
guide](https://docs.rstudio.com/connect/user/api-keys/).

``` r
library(connectapi)
library(reactable)
library(dplyr)

# connect to the pin board
pins::board_register_rsconnect(server = Sys.getenv("CONNECT_SERVER"),
                               key = Sys.getenv("CONNECT_API_KEY"))


# get all content listings from pin (this is slow so store it in a pin)
all_content <- pins::pin_get("rsc_content_list")
```

Here we connect to the RStudio Connect (RSC) API using the `connectapi`
package. We then fetch usage statistics for Shiny apps within the range
specified by the input parameters stored in the objects `params`.

    ## Defining Connect with host: https://colorado.rstudio.com/rsc

The below chunk calculates visit duration, joins to the content listing
(`all_content` object), and then summarizes the visitation for each app.

``` r
# select only desired shiny data
shiny <- shiny_use %>% 
  mutate(duration = ended - started) %>%
  select(content_guid, user_guid, duration)


cleaned_metrics <- all_content %>% 
  select(guid, title, url, owner_username) %>% 
  inner_join(shiny, by = c("guid" = "content_guid")) %>% 
  # summarise statistics
  group_by(guid, owner_username, url, title) %>%
  summarise(duration_mins = round(as.numeric(sum(duration), units = "mins"), 2),
            max_duration = round(as.numeric(max(duration), units = "mins"), 2),
            n_visits = n()) %>%
  ungroup() %>%
  select(-guid) %>%
  arrange(-duration_mins) 
```

| owner\_username | url                                                                     | title                                        | duration\_mins | max\_duration | n\_visits |
| :-------------- | :---------------------------------------------------------------------- | :------------------------------------------- | -------------: | ------------: | --------: |
| andrie          | <https://colorado.rstudio.com/rsc/shimmer_and_shiny/>                   | Shimmer and Shiny                            |         760.15 |         70.03 |       439 |
| cole            | <https://colorado.rstudio.com/rsc/google-survey/>                       | Google Survey                                |         753.47 |        427.73 |         7 |
| edgar           | <https://colorado.rstudio.com/rsc/access-to-care/dashboard/>            | Access to Care - Dashboard                   |         388.50 |         76.13 |         9 |
| kris            | <https://colorado.rstudio.com/rsc/model-management/model-dashboard/>    | Model Management - Model Dashboard           |         206.58 |        100.62 |         5 |
| andrie          | <https://colorado.rstudio.com/rsc/team-admin/binary-packages-exercise/> | Team admin 3.3 R startup and binary packages |         200.58 |         84.25 |         3 |
| sean            | <https://colorado.rstudio.com/rsc/myhybrid/>                            | Reticulated Shiny                            |         187.50 |         60.32 |        17 |
| alex.gold       | <https://colorado.rstudio.com/rsc/bike_predict_app/>                    | Bike Predict App                             |         180.43 |         60.47 |        14 |
| cole            | <https://colorado.rstudio.com/rsc/learndrake/static/>                   | Learn Drake - Static                         |         157.38 |         77.83 |         4 |
| andrie          | <https://colorado.rstudio.com/rsc/team-admin/security-rsp-exercise/>    | Team admin 3.2 Authenticating                |         153.03 |         84.15 |         5 |
| cole            | <https://colorado.rstudio.com/rsc/learndrake/changes/>                  | Learn Drake - Changes                        |         117.37 |         96.90 |         5 |
