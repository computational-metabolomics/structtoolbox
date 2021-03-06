% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/mv_feature_filter_class.R
\name{mv_feature_filter}
\alias{mv_feature_filter}
\title{Filter by fraction missing values}
\usage{
mv_feature_filter(
  threshold = 20,
  qc_label = "QC",
  method = "QC",
  factor_name,
  ...
)
}
\arguments{
\item{threshold}{(numeric) The threshold for excluding features. The default is \code{20}.}

\item{qc_label}{(character) The label used to identify QC samples. The default is \code{"QC"}.}

\item{method}{(character) Filtering method. Allowed values are limited to the following: \itemize{\item{\code{"within_all"}: The filter is applied within classes.}\item{\code{"within_one"}: The filter is applied within any one class.}\item{\code{"QC"}: The filter is applied within QC samples.}\item{\code{"across"}: The filter is applied across all samples.}} The default is \code{"QC"}.}

\item{factor_name}{(character) The name of a sample-meta column to use.}

\item{...}{Additional slots and values passed to \code{struct_class}.}
}
\value{
A  \code{mv_feature_filter} object with the following \code{output} slots:
\tabular{ll}{
\code{filtered} \tab          (DatasetExperiment) A DatasetExperiment object containing the filtered data. \cr
\code{flags} \tab          (data.frame) % missing values and a flag indicating whether the sample was rejected. \cr
}
}
\description{
Filters features where the percent number of missing values exceeds a predefined threshold.
}
\details{
This object makes use of functionality from the following packages:\itemize{\item{\code{pmp}}}
}
\examples{
D = iris_DatasetExperiment()
M = mv_feature_filter(factor_name='Species',qc_label='versicolor')
M = model_apply(M,D)
}
\references{
Jankevics A, Lloyd GR, Weber RJM (2021).
\emph{pmp: Peak Matrix Processing and signal batch correction for
metabolomics datasets}.
R package version 1.4.0.
}
