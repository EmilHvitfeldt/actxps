#' Summarize transactions and utilization rates
#'
#' @description Create a summary data frame of transaction counts, amounts,
#' and utilization rates.
#'
#' @details Unlike [exp_stats()], this function requires `data` to be an
#' `exposed_df` object.
#'
#' If `.data` is grouped, the resulting data frame will contain
#' one row per transaction type per group.
#'
#' Any number of transaction types can be passed to the `trx_types` argument,
#' however each transaction type **must** appear in the `trx_types` attribute of
#' `.data`. In addition, `trx_stats()` expects to see columns named `trx_n_{*}`
#' (for transaction counts) and `trx_amt_{*}` for (transaction amounts) for each
#' transaction type. To ensure `.data` is in the appropriate format, use the
#' functions [as_exposed_df()] to convert an existing data frame with
#' transactions or [add_transactions()] to attach transactions to an existing
#' `exposed_df` object.
#'
#' # "Percentage of" calculations
#'
#' The `percent_of` argument is optional. If provided, this argument must
#' be a character vector with values corresponding to columns in `.data`
#' containing values to use as denominators in the calculation of utilization
#' rates or actual-to-expected ratios. Example usage:
#'
#' - In a study of partial withdrawal transactions, if `percent_of` refers to
#'  account values, observed withdrawal rates can be determined.
#' - In a study of recurring claims, if `percent_of` refers to a column
#' containing a maximum benefit amount, utilization rates can be determined.
#'
#' # Default removal of partial exposures
#'
#' As a default, partial exposures are removed from `.data` before summarizing
#' results. This is done to avoid complexity associated with a lopsided skew
#' in the timing of transactions. For example, if transactions can occur on a
#' monthly basis or annually at the beginning of each policy year, partial
#' exposures may not be appropriate. If a policy had an exposure of 0.5 years
#' and was taking withdrawals annually at the beginning of the year, an
#' argument could be made that the exposure should instead be 1 complete year.
#' If the same policy was expected to take withdrawals 9 months into the year,
#' it's not clear if the exposure should be 0.5 years or 0.5 / 0.75 years.
#' To override this treatment, set `full_exposures_only` to `FALSE`.
#'
#' # `summary()` Method
#'
#' Applying `summary()` to a `trx_df` object will re-summarize the
#' data while retaining any grouping variables passed to the "dots"
#' (`...`).
#'
#' @param .data a data frame with exposure-level records of type
#' `exposed_df` with transaction data attached. If necessary, use
#' [as_exposed_df()] to convert a data frame to an `exposed_df` object, and use
#' [add_transactions()] to attach transactions to an `exposed_df` object.
#'
#' @param trx_types A character vector of transaction types to include in the
#' output. If none is provided, all available transaction types in `.data`
#' will be used.
#'
#' @param percent_of A optional character vector containing column names in
#' `.data` to use as denominators in the calculation of utilization rates or
#' actual-to-expected ratios.
#'
#' @param combine_trx If `FALSE` (default), the results will contain output rows
#' for each transaction type. If `TRUE`, the results will contains aggregated
#' results across all transaction types.
#'
#' @param col_exposure name of the column in `.data` containing exposures
#'
#' @param full_exposures_only If `TRUE` (default), partially exposed records will
#' be excluded from `data`.
#'
#' @param object an `trx_df` object
#' @param ... groups to retain after `summary()` is called
#'
#' @return A tibble with class `trx_df`, `tbl_df`, `tbl`,
#' and `data.frame`. The results include columns for any grouping
#' variables and transaction types, plus the following:
#'
#' - `trx_n`: the number of unique transactions.
#' - `trx_amt`: total transaction amount
#' - `trx_flag`: the number of observation periods with non-zero transaction amounts.
#' - `exposure`: total exposures
#' - `avg_trx`: mean transaction amount (`trx_amt / trx_flag`)
#' - `avg_all`: mean transaction amount over all records (`trx_amt / exposure`)
#' - `trx_freq`: transaction frequency when a transaction occurs (`trx_n / trx_flag`)
#' - `trx_utilization`: transaction utilization per observation period (`trx_flag / exposure`)
#'
#' If `percent_of` is provided, the results will also include:
#'
#' - The sum of any columns passed to `percent_of` with non-zero transactions.
#' These columns include the suffix `_w_trx`.
#' - The sum of any columns passed to `percent_of`
#' - `pct_of_{*}_w_trx`: total transactions as a percentage of column
#' `{*}_w_trx`
#' - `pct_of_{*}_all`: total transactions as a percentage of column `{*}`
#'
#' @examples
#' expo <- expose_py(census_dat, "2019-12-31", target_status = "Surrender") |>
#'   add_transactions(withdrawals)
#'
#' res <- expo |> group_by(inc_guar) |> trx_stats(percent_of = "premium")
#' res
#'
#' summary(res)
#'
#' expo |> group_by(inc_guar) |>
#'   trx_stats(percent_of = "premium", combine_trx = TRUE)
#'
#' @export
trx_stats <- function(.data,
                      trx_types,
                      percent_of = NULL,
                      combine_trx = FALSE,
                      col_exposure = "exposure",
                      full_exposures_only = TRUE) {

  verify_exposed_df(.data)

  # verify transaction types
  all_trx_types <- verify_get_trx_types(.data)

  if(missing(trx_types)) {
    trx_types <- all_trx_types
  } else {
    unmatched <- setdiff(trx_types, all_trx_types)
    if (length(unmatched) > 0) {
      rlang::abort(c(x = glue::glue("The following transactions do not exist in `.data`: {paste0(unmatched, collapse = ', ')}")))
    }
  }

  start_date <- attr(.data, "start_date")
  end_date <- attr(.data, "end_date")

  .data <- .data |> rename(exposure = {{col_exposure}})

  # remove partial exposures
  if(full_exposures_only) {
    .data <- filter(.data, dplyr::near(exposure, 1))
  }

  .groups <- groups(.data)

  trx_cols <- names(.data)[grepl("trx_(n|amt)_", names(.data))]
  trx_cols <- trx_cols[grepl(paste(trx_types, collapse = "|"), trx_cols)]

  if (combine_trx) {
    trx_n_cols <- trx_cols[grepl("_n_", trx_cols)]
    trx_amt_cols <- trx_cols[grepl("_amt_", trx_cols)]
    .data <- .data |> mutate(
      trx_n_All = !!rlang::parse_expr(paste(trx_n_cols, collapse = "+")),
      trx_amt_All = !!rlang::parse_expr(paste(trx_amt_cols, collapse = "+")))
    trx_cols <- c("trx_n_All", "trx_amt_All")
  }

  pct_nz <- if (!is.null(percent_of)) {
    exp_form("{.col} * trx_flag", "{.col}_w_trx", percent_of)
  }

  .data <- .data |>
    select(pol_num, exposure, !!!.groups,
                  dplyr::all_of(trx_cols), dplyr::all_of(percent_of)) |>
    tidyr::pivot_longer(dplyr::all_of(trx_cols),
                        names_to = c(".value", "trx_type"),
                        names_pattern = "^(trx_(?:amt|n))_(.*)$") |>
    mutate(trx_flag = abs(trx_n) > 0, !!!pct_nz)

  finish_trx_stats(.data, trx_types, percent_of,
                   .groups, start_date, end_date)

}

#' @export
print.trx_df <- function(x, ...) {

  cat("Transaction study results\n\n",
      "Groups:", paste(groups(x), collapse = ", "), "\n",
      "Study range:", as.character(attr(x, "start_date")), "to",
      as.character(attr(x, "end_date")), "\n",
      "Transaction types:", paste(attr(x, "trx_types"), collapse = ", "), "\n")
  if (!is.null(attr(x, "percent_of"))) {
    cat(" Transactions as % of:", paste(attr(x, "percent_of"), collapse = ", "), "\n")
  }
  if (is.null(attr(x, "wt"))) {
    cat("\n")
  } else {
    cat(" Weighted by:", attr(x, "wt"), "\n\n")
  }

  NextMethod()
}


#' @export
groups.trx_df <- function(x) {
  attr(x, "groups")
}

#' @export
#' @rdname trx_stats
summary.trx_df <- function(object, ...) {

  res <- group_by(object, !!!rlang::enquos(...))

  .groups <- groups(res)
  trx_types <- attr(object, "trx_types")
  start_date <- attr(object, "start_date")
  end_date <- attr(object, "end_date")
  percent_of <- attr(object, "percent_of")

  finish_trx_stats(res, trx_types, percent_of,
                   .groups, start_date, end_date)

}


# support functions -------------------------------------------------------


finish_trx_stats <- function(.data, trx_types, percent_of,
                             .groups, start_date, end_date) {

  if (!is.null(percent_of)) {
    percent_of_nz <- paste0(percent_of, "_w_trx")
    pct_vals <- exp_form("sum({.col})", "{.col}", percent_of)
    pct_vals_trx <- exp_form("sum({.col})", "{.col}", percent_of_nz)
    pct_form_all <- exp_form("trx_amt / {.col}", "pct_of_{.col}_all",
                             percent_of)
    pct_form_trx <- exp_form("trx_amt / {.col}", "pct_of_{.col}",
                             percent_of_nz)
  } else {
    pct_vals <- pct_vals_trx <- pct_form_all <- pct_form_trx <- percent_of <- NULL
  }

  res <- .data |>
    group_by(trx_type, .add = TRUE) |>
    dplyr::summarize(trx_n = sum(trx_n),
                     trx_flag = sum(trx_flag),
                     trx_amt = sum(trx_amt),
                     exposure = sum(exposure),
                     avg_trx = trx_amt / trx_flag,
                     avg_all = trx_amt / exposure,
                     trx_freq = trx_n / trx_flag,
                     trx_util = trx_flag / exposure,
                     !!!pct_vals_trx,
                     !!!pct_vals,
                     !!!pct_form_trx,
                     !!!pct_form_all,
                     .groups = "drop")

  tibble::new_tibble(res,
                     class = "trx_df",
                     groups = .groups, trx_types = trx_types,
                     start_date = start_date,
                     percent_of = percent_of,
                     end_date = end_date)
}
