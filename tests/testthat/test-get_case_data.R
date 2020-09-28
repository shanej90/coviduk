#test error messages come back correctly----------------

#regions
testthat::test_that(
  "region outside list throws error",
  expect_error(
    coviduk::get_case_data("nation", "hello", "2020-05-20", "2020-06-15"),
    "nation must be one of: England; Northern Ireland; Scotland; Wales",
    fixed = T
    )
  )

#format--------------------------------

#make sure you end up with a dataframe
testthat::expect_is(coviduk::get_case_data("ltla", "Exeter", "2020-06-30", "2020-08-01"), "data.frame")
