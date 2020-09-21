#test error messages come back correctly----------------

#regions
testthat::test_that(
  "region outside list throws error",
  expect_error(
    coviduk::get_hospital_admissions("hello", "2020-05-20", "2020-06-15"),
    "`region` must be on of: East of England;London;Midlands;North East and Yorkshire;North West;South East;South West",
    fixed = T
  )
)

#date formatting
testthat::test_that(
  "incorrectly formatted dates throw an error",
  expect_error(
    coviduk::get_hospital_admissions("London", "2020-05-20", "202-06-15"),
    "Dates must be in 'yyyy-mm-dd' format.",
    fixed = T
  )
)

#end date >= start date
testthat::test_that(
  "setting an end date before the start date gives an error",
  expect_error(
    coviduk::get_hospital_admissions("London", "2020-05-20", "2020-04-15"),
    "end date must be later than, or same as, start date",
    fixed = T
  )
)

#test min start date
testthat::test_that(
  "you can't set dates earlier than 2020-3-19",
  expect_error(
    coviduk::get_hospital_admissions("London", "2020-02-20", "2020-04-15"),
    "Minimum start date is 2020-03-19",
    fixed = T
  )
)

#format--------------------------------

#make sure you end up with a dataframe
testthat::expect_is(coviduk::get_hospital_admissions("London", "2020-03-30", "2020-05-01"), "data.frame")

#dates-------------------------------

#make sure all dates are pulled
dates_to_call <- seq.Date(lubridate::ymd("2020-05-01"), lubridate::ymd("2020-05-31"), by = "days") %>%
  format(., "%Y-%m-%d")

testthat::expect_setequal(
  coviduk::get_hospital_admissions("London", "2020-05-01", "2020-05-31") %>% dplyr::pull(date),
  dates_to_call
)


