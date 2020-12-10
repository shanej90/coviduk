#' Create a dataframe of deaths data, according to the specifications you set.
#'
#' Makes API call to UK Government coronavirus dashboard and collects data on deaths according to the parameters you set. Data will be by nation, region or local authority (upper or lower tier). Note only 1,000 results max returned and that throttling can be implemented if you make too many requests.
#'
#' @param area_type Specify the name of the area for which you want to get the data.
#' @param area_name Specify the area (by name, not code) for which you would like to pull the data.
#' @param start_date Specify the first date for which you wish to collect the data. ymd format.
#' @param end_date Specify the last date for which you wish to collect the data. ymd format.
#' @return A dataframe containing deaths data by the specified area type, by date reported and of death. Note not all variables are available for all area types.
#' @export

get_deaths_data <- function(area_type, area_name, start_date, end_date) {

  #area data---------------

  #local authorities
  las <- read.csv("http://geoportal1-ons.opendata.arcgis.com/datasets/3e4f4af826d343349c13fb7f0aa2a307_0.csv")

  #nations
  nations <- c("England", "Northern Ireland", "Scotland", "Wales")

  #regions
  regions <- c("East of England", "London", "East Midlands", "West Midlands", "North East", "Yorkshire and The Humber", "North West", "South East", "South West")


  #error handling----------------------------------

  #area type
  if(!area_type %in% c("nation", "region", "utla", "ltla")) stop("area_type must be one of: nation; region; utla; ltla")

  #valid areas
  if(area_type == "nation" & !area_name %in% nations) stop("nation must be one of: England; Northern Ireland; Scotland; Wales")
  if(area_type == "region" & !area_name %in% regions) stop("region must be one of: East Midlands; East of England; North East; North West; South East; South West; West Midlands; Yorkshire and The Humber")
  if(area_type == "utla" & !area_name %in% las$UTLA19NM) stop("utla must be as per http://geoportal1-ons.opendata.arcgis.com/datasets/3e4f4af826d343349c13fb7f0aa2a307_0.csv")
  if(area_type == "ltla" & !area_name %in% las$LTLA19NM) stop("ltla must be as per http://geoportal1-ons.opendata.arcgis.com/datasets/3e4f4af826d343349c13fb7f0aa2a307_0.csv")

  #make sure end date greater than or equal to start date
  if(lubridate::ymd(end_date) < lubridate::ymd(start_date)) stop("end date must be later than, or same as, start date")

  #make sure start date no earlier than 2020-01-30
  if(lubridate::ymd(start_date) < lubridate::ymd("2020-01-30")) stop("Minimum start date is 2020-01-30")

  #sequence of dates to call-----------------------------------------
  dates_to_call <- seq.Date(lubridate::ymd(start_date), lubridate::ymd(end_date), by = "days") %>%
    format(., "%Y-%m-%d")

  #create query parameters-------------------------------------

  call_api <- function(.date) {

    #filter settings
    filter_settings <- c(
      glue::glue("areaType={area_type}"),
      glue::glue("areaName={area_name}"),
      glue::glue("date={.date}")
    )

    #structure settings
    structure_settings <- list(
      date = .date,
      area = list(code =  "areaCode", name = "areaName"),
      reported = list(new = "newDeaths28DaysByPublishDate", total = "cumDeaths28DaysByPublishDate"),
      of_death = list(new = "newDeaths28DaysByDeathDate", total = "cumDeaths28DaysByDeathDate")
    )

    #query-------------------------------------

    #base url
    endpoint <- "https://api.coronavirus.data.gov.uk/v1/data"

    #TODO: when polite package containing politely function released on CRAN, do things politely
    #polite_get <- polite::politely(httr::GET, verbose = T)

    #call api and convert to appropriate format
    result <- httr::GET(
      url = endpoint,
      #convert queries into JSON format
      query = list(
        filters = paste(filter_settings, collapse = ";"),
        structure = jsonlite::toJSON(structure_settings, auto_unbox = T)
      ),
      httr::timeout(10)
    )

    if(result$status_code >= 400) {
      err_msg = httr::http_status(result)
      stop(err_msg)
    }

    #result text
    result_text <- httr::content(result, "text")

    #turn into dataframe
    jsonlite::fromJSON(result_text)[["data"]] %>%
      #sort out listed nature of dataframe..probably a better way of doing this
      dplyr::mutate(
        area_code = area$code,
        area_name = area$name,
        reported_new = reported$new,
        reported_total = reported$total,
        of_death_new = of_death$new,
        of_death_total = of_death$total
      ) %>%
      #remove unnecessary columns
      dplyr::select(-reported, -of_death, -area) %>%
      #set sensible names
      #set sensible names
      stats::setNames(c("date", "area_code", "area_name", "reported_new", "reported_total", "of_death_new", "of_death_total"))

  }

  #run function for all specified dates, and bind rows
  lapply(dates_to_call, call_api) %>%
    dplyr::bind_rows(.)

}
