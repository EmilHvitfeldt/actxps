% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/plots.R
\name{autoplot_exp}
\alias{autoplot_exp}
\alias{autoplot.exp_df}
\alias{autoplot.trx_df}
\title{Plot experience study results}
\usage{
\method{autoplot}{exp_df}(
  object,
  ...,
  x = NULL,
  y = NULL,
  color = NULL,
  mapping,
  scales = "fixed",
  geoms = c("lines", "bars"),
  y_labels = scales::label_percent(accuracy = 0.1)
)

\method{autoplot}{trx_df}(
  object,
  ...,
  x = NULL,
  y = NULL,
  color = NULL,
  mapping,
  scales = "fixed",
  geoms = c("lines", "bars"),
  y_labels = scales::label_percent(accuracy = 0.1)
)
}
\arguments{
\item{object}{An object of class \code{exp_df} created by the
function \code{\link[=exp_stats]{exp_stats()}} or an object of class \code{trx_df} created by the function
\code{\link[=trx_stats]{trx_stats()}}.}

\item{...}{Faceting variables passed to \code{\link[ggplot2:facet_wrap]{ggplot2::facet_wrap()}}.}

\item{x}{An unquoted column name in \code{object} or expression to use as the \code{x}
variable.}

\item{y}{An unquoted column name in \code{object} or expression to use as the
\code{y} variable. If unspecified, \code{y} will default to the observed termination
rate (\code{q_obs}) for \code{exp_df} objects and the observed utilization rate
(\code{trx_util}) for \code{trx_df} objects.}

\item{color}{An unquoted column name in \code{object} or expression to use as the
\code{color} and \code{fill} variables.}

\item{mapping}{Aesthetic mapping passed to \code{\link[ggplot2:ggplot]{ggplot2::ggplot()}}. NOTE: If
\code{mapping} is supplied, the \code{x}, \code{y}, and \code{color} arguments will be ignored.}

\item{scales}{The \code{scales} argument passed to \code{\link[ggplot2:facet_wrap]{ggplot2::facet_wrap()}}.}

\item{geoms}{Type of geometry. If "points" is passed, the plot will
display lines and points. If "bars", the plot will display bars.}

\item{y_labels}{Label function passed to \code{\link[ggplot2:scale_continuous]{ggplot2::scale_y_continuous()}}.}
}
\value{
a \code{ggplot} object
}
\description{
Plot experience study results
}
\details{
If no aesthetic map is supplied, the plot will use the first
grouping variable in \code{object} on the x axis and \code{q_obs} on the y
axis. In addition, the second grouping variable in \code{object} will be
used for color and fill.

If no faceting variables are supplied, the plot will use grouping
variables 3 and up as facets. These variables are passed into
\code{\link[ggplot2:facet_wrap]{ggplot2::facet_wrap()}}. Specific to \code{trx_df} objects, transaction
type (\code{trx_type}) will also be added as a faceting variable.
}
