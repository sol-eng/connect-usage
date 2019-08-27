library(magrittr)

# helper function to return character instead of NULL 
null_char <- function(x, default) {
 if (is.null(x) || is.na(x))
   return(default)
 x
}

null_chars <- function(x, default) {
  sapply(x, null_char, default)
}

# generate auth header
connect_auth <- function() {
  apiKey <- Sys.getenv("RSTUDIO_CONNECT_API_KEY")
  httr::add_headers(Authorization = paste("Key", apiKey))
}

# shared function to call the RSC API
connect_api <- function(endpoint) {
  connectServer <- Sys.getenv("RSTUDIO_CONNECT_SERVER")
  if (!stringr::str_detect(connectServer, ".*/$")) 
    connectServer <- paste0(connectServer, "/")
  
  apiPrefix <- sprintf("__api__/v1/%s", endpoint)
  authHeader <- connect_auth()
  resp <- httr::GET(
    paste0(connectServer, apiPrefix),
    authHeader
  )
  if (!httr::http_error(resp)) {
    return(resp)
  } else {
    stop(sprintf('Error accessing: %s', endpoint))
  }
}

# shared function to add a date filter
add_from_filter <- function(endpoint, datetime) {
  # todo input validation
  # todo proper timezone handling, our API expects the RFC3339 format
  from  <- paste0(strftime(datetime, format = "%Y-%m-%dT%H:%M:%S"), "-00:00")
  paste0(endpoint, '&from=', from)
}

# shared function to add a content filter
add_content_guid_filter <- function(endpoint, content_guid) {
  if (!is.null(content_guid) && !is.na(content_guid)) {
    paste0(endpoint, '&content_guid=', content_guid)
  } else {
    endpoint
  }
}
  

# helper function to hget a single user
get_a_user <- function(guid) {
  endpoint <- sprintf('users/%s', guid)
  resp <- connect_api(endpoint)
  httr::content(resp) 
}

# helper function to return a data frame of all users
get_all_users <- function(){
  endpoint <- 'users?page_size=25'
  resp <- connect_api(endpoint) 

  #init result set
  result <- data.frame(username = vector("character"), 
                       guid = vector("character"), 
                       stringsAsFactors = FALSE)
  
  # get the first page
  payload <- httr::content(resp)
  
  while (length(payload$result) > 0) {
    
    # process payload
    result <- rbind(result, purrr::map_df(payload$results, ~data.frame(username = .x$username,
                                                                       guid = .x$guid,
                                                                       stringsAsFactors = FALSE)))
    
    # get the next page
    nextPage <- payload$current_page + 1
    resp <- connect_api(paste0(endpoint,'&page_number=', nextPage))
    payload <- httr::content(resp)
  }
  result
}

# helper function to join usernames to a dataframe with user guids
join_users <- function(user_guids) { 
  tmp <- data.frame(user_guids = user_guids, stringsAsFactors = FALSE)
  # todo, cache this value
  users <- get_all_users()
  dplyr::left_join(tmp, users, by = c("user_guids" = "guid")) %>% 
    dplyr::pull(username)
}

# get usage data for an app, optionally filtering by content GUID and datetime
get_shiny_usage <- function(content_guid = NA, 
                            from = lubridate::now() - lubridate::ddays(30)) {
  
  endpoint <- "instrumentation/shiny/usage?limit=100"
  
  resp <- endpoint %>% 
    add_content_guid_filter(content_guid) %>% 
    add_from_filter(from) %>% 
    connect_api()
  
  
  # process first page
  payload <- httr::content(resp)
  result <- payload$results
  
  # now step through the remaining pages
  while (!is.null(payload$paging[["next"]])) {
    resp <- httr::GET(payload$paging[["next"]],  connect_auth())
    
    payload <- httr::content(resp)
    result <- c(result, payload$results)
  }
  
  result <- do.call(rbind, result) %>%
    as.data.frame() %>%
    dplyr::mutate(
      started = purrr::map_chr(started, 1), # or could use unlist()
      content_guid = purrr::map_chr(content_guid, 1),
      user_guid = purrr::map_chr(user_guid, null_char, "anonymous"),
      ended = purrr::map_chr(ended, null_char, as.character(Sys.time()))
    )
  
  result
}

# get content by guid
get_content <- function(content_guid) {
  tryCatch({resp <- connect_api(sprintf("experimental/content/%s", content_guid))
  httr::content(resp)}, error = function(e) 'Unknown (Deleted Content?)')
  
}

get_content_name <- function(content_guid) {
  tryCatch({content <- get_content(content_guid)
  null_char(content$title, content$name)},error = function(e) 'Unknown (Deleted Content?)')
}

# get usage data for content, optionally filtering by content GUID and datetime
get_content_usage <- function(content_guid = NA, 
                              from = lubridate::now() - lubridate::ddays(30)) {
  endpoint <- "instrumentation/content/visits?limit=100"
  
  resp <- endpoint %>% 
    add_content_guid_filter(content_guid) %>% 
    add_from_filter(from) %>% 
    connect_api()
  
  # process first page
  payload <- httr::content(resp)
  result <- payload$results
  
  # now step through the remaining pages
  while (!is.null(payload$paging[["next"]])) {
    resp <- httr::GET(payload$paging[["next"]], connect_auth())
    
    payload <- httr::content(resp)
    result <- c(result, payload$results)
  }
  
  result <- do.call(rbind, result) %>%
    as.data.frame() %>%
    dplyr::mutate(
      time = purrr::map_chr(time, 1), # or could use unlist()
      content_guid = purrr::map_chr(content_guid, 1),
      user_guid = purrr::map_chr(user_guid, null_char, "anonymous")
    )
  
  result
}

clean_data <- function(data){
  # this function takes the data frame from get_shiny_usage
  data$started <- lubridate::ymd_hms(data$started)
  data$ended <- lubridate::ymd_hms(data$ended)
  data$session_duration <- data$ended - data$started
  dplyr::filter(data, session_duration > lubridate::dseconds(5))
}
