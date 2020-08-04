User Usage
================

This document illustrates how to fetch user-level usage on your RStudio
Connect server. This information can be useful for understand who is
accessing Connect how many times, and for how long (for shiny apps).
Note that this document will only return information that you are privy
to. It is recommended for a user with admin privileges do this for the
most complete data.

This document will walk you though:

1.  Getting your users.
2.  Getting usage statistics for all non-shiny content by user. This
    provides visit totals.
3.  Getting usage statitistics for shiny applications by user. This
    provides durations or visit totals.

## Environment Configuration

To ensure that your R session can communicate with the Connect API you
must have the `CONNECT_API_KEY` and `CONNECT_SERVER` environment
variables set. The recommended way to do this is with a `.Renviron`
file. Alternatively you can use code like the below.

``` r
## ACTION REQUIRED: Change the server URL below to your server's URL
Sys.setenv("CONNECT_SERVER"  = "https://connect.example.com/rsc") 

## ACTION REQUIRED: Make sure to have your API key ready
Sys.setenv("CONNECT_API_KEY" = "your-api-key-here")) 
```

## Example

Load requisite libraries and Connect to the API.

``` r
library(connectapi)
library(tidyverse)

client <- connect()
```

Fetch all of your users

``` r
users <- get_users(client, page_size = Inf)
```

### Fetch Usage

In order to get complete usage statistics we need to get usage for Shiny
apps and non-shiny apps. First we will grab usage statistics for all
content from the past 200 days with `get_usage_static()`. For the
purposes of a license renewal it is suggested to use your `from` date as
the license start date. Following we will grab usage stats for shiny
applications as well.

``` r
total_usage <- get_usage_static(client,
                                limit = Inf, 
                                from = Sys.Date() - 200,
                                to = Sys.Date())


shiny_use <- get_usage_shiny(client,
                limit = Inf, 
                from = Sys.Date() - 200,
                to = Sys.Date())
```

### Summarize Usage

For static content visits we can only know how many times a piece of
content was visited. As such we will count the number of visits by each
user. For shiny applications we can calculate the amount of time spent
on a shiny application as well as the number of visits.

``` r
# count non-shiny visits
count(total_usage, user_guid, sort = TRUE) %>% 
# join to shiny visits 
  left_join(
    shiny_use %>% 
      group_by(user_guid) %>% 
      summarise(shiny_usage = sum(ended-started),
                n_shiny_visits = n()) 
  ) %>% 
  rename(content_visits = n) %>% 
  # join to users for user identification
  left_join(select(users, first_name, last_name, user_guid = guid), 
            by = "user_guid") %>% 
  select(-user_guid)
```