expo <- expose_py(census_dat, "2019-12-31", target_status = "Surrender") |>
  add_transactions(withdrawals) |>
  mutate(q_exp = ifelse(inc_guar, 0.015, 0.03))

exp_stats2 <- function(dat) exp_stats(dat, wt = "premium", credibility = TRUE,
                                      expected = "q_exp")
trx_stats2 <- function(dat) trx_stats(dat, percent_of = 'premium')

# ungrouped summaries
exp_res <- exp_stats2(expo)
trx_res <- trx_stats2(expo)

# 1 grouping variables
expo <- expo |> group_by(pol_yr)
exp_res2 <- exp_stats2(expo)
trx_res2 <- trx_stats2(expo)

# 2 grouping variables
expo <- expo |> group_by(inc_guar, .add = TRUE)
exp_res3 <- exp_stats2(expo)
trx_res3 <- trx_stats2(expo)

# 3 grouping variables
expo <- expo |> group_by(product, .add = TRUE)
exp_res4 <- exp_stats2(expo)
trx_res4 <- trx_stats2(expo)


toy_res <- toy_census |>
  expose_py(end_date = "2022-12-31", target_status = "Surrender") |>
  dplyr::group_by(pol_yr) |>
  exp_stats()

test_that("Autoplot works", {
  expect_s3_class(autoplot(exp_res), c("gg", "ggplot"))
  expect_s3_class(autoplot(exp_res2), c("gg", "ggplot"))
  expect_s3_class(autoplot(exp_res3), c("gg", "ggplot"))
  expect_s3_class(autoplot(exp_res4), c("gg", "ggplot"))
  expect_s3_class(autoplot(trx_res), c("gg", "ggplot"))
  expect_s3_class(autoplot(trx_res2), c("gg", "ggplot"))
  expect_s3_class(autoplot(trx_res3), c("gg", "ggplot"))
  expect_s3_class(autoplot(trx_res4), c("gg", "ggplot"))
})

test_that("Autoplot works with mapping overrides", {

  expect_s3_class(autoplot(exp_res4, inc_guar, x = pol_yr,
                           y = ae_q_exp,
                           color = product,
                           scales = "free_y",
                           geoms = "bars",
                           y_labels = scales::label_number()),
                  c("gg", "ggplot"))
  expect_s3_class(autoplot(trx_res4, trx_type, inc_guar, x = pol_yr,
                           y = pct_of_premium_w_trx,
                           color = product,
                           scales = "free_y",
                           geoms = "bars",
                           y_labels = scales::label_number()),
                  c("gg", "ggplot"))

  expect_s3_class(autoplot(exp_res4, inc_guar,
                           mapping = ggplot2::aes(x = pol_yr,
                                                 y = ae_q_exp,
                                                 fill = product),
                           scales = "free_y",
                           geoms = "bars",
                           y_labels = scales::label_number()),
                  c("gg", "ggplot"))
  expect_s3_class(autoplot(trx_res4, trx_type, inc_guar,
                           mapping = ggplot2::aes(x = pol_yr,
                                                 y = pct_of_premium_w_trx,
                                                 fill = product),
                           scales = "free_y",
                           geoms = "bars",
                           y_labels = scales::label_number()),
                  c("gg", "ggplot"))

})
