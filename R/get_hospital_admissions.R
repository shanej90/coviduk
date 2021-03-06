#' Create a dataframe of hospital admissions data, according to the specifications you set.
#'
#' Makes API call to UK Government coronavirus dashboard and collects data on admissions according to the parameters you set. Data will be by NHS region or nation. Note only 1,000 results max returned and that throttling can be implemented if you make too many requests.
#'
#'
#' @param area_name Specify the region/nation (by name, not code) for which you want to get the data.
#' @param start_date Specify the first date for which you wish to collect the data. ymd format.
#' @param end_date Specify the last date for which you wish to collect the data. ymd format.
#' @return A dataframe containing hospital admissions data by NHS region or nation: new admissions and cumulative admissions. Only a maximum of 1,000 results will be returned.
#' @export

get_hospital_admissions <- function(area_name, start_date, end_date) {

  #error checking/validation-----------------------------------------

  #valid regions
  valid_regions <- c("East of England", "London", "Midlands", "North East and Yorkshire", "North West", "South East", "South West", "Scotland", "Wales", "Northern Ireland", "England")

  #make sure valid NHS region is chosen
  if(!area_name %in% valid_regions) stop(glue::glue("`area` must be on of: {paste(valid_regions, collapse = ';')}"))

  #make sure dates are in right format
  if(
    stringr::str_detect(start_date, "[0-9][0-9][0-9][0-9]-[0-1][0-9]-[0-3][0-9]") == F |
    stringr::str_detect(end_date, "[0-9][0-9][0-9][0-9]-[0-1][0-9]-[0-3][0-9]") == F
  ) stop("Dates must be in 'yyyy-mm-dd' format.")

  #make sure end date greater than or equal to start date
  if(lubridate::ymd(end_date) < lubridate::ymd(start_date)) stop("end date must be later than, or same as, start date")

  #make sure start date no earlier than 2020-03-19
  if(lubridate::ymd(start_date) < lubridate::ymd("2020-03-19")) stop("Minimum start date is 2020-03-19")

  #sequence of dates to call-----------------------------------------
  dates_to_call <- seq.Date(lubridate::ymd(start_date), lubridate::ymd(end_date), by = "days") %>%
    format(., "%Y-%m-%d")

  #create query parameters-------------------------------------------------

  #base url
  endpoint <- "https://api.coronavirus.data.gov.uk/v1/data"

  #area type
  area_type <- ifelse(area_name %in% c("England", "Wales", "Northern Ireland", "Scotland"), "nation", "nhsRegion")

  #function to run the query for each registered date--------------------------
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
      area = list(name = "areaName", code = "areaCode"),
      hospital_admissions = list(new = "newAdmissions", total = "cumAdmissions")
      )

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
        area_name = area$name,
        area_code = area$code,
        new = hospital_admissions$new,
        total = hospital_admissions$total
        ) %>%
      #remove unnecessary columns
      dplyr::select(-area, -hospital_admissions) %>%
      #set sensible names
      stats::setNames(c("date", "area_name", "area_code", "new_admissions", "total_admissions"))

      }

  #run function for all specified dates, and bind rows
  lapply(dates_to_call, call_api) %>%
    dplyr::bind_rows(.)

}
