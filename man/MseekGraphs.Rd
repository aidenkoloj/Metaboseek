% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/methods_buildMseekFT.R
\docType{methods}
\name{MseekGraphs}
\alias{MseekGraphs}
\alias{buildMseekGraph}
\alias{saveMseekGraph,MseekGraph-method}
\alias{saveMseekGraph}
\title{MseekGraphs}
\usage{
\S4method{buildMseekGraph}{MseekFT}(object, cosineThreshold = 0.6)

\S4method{saveMseekGraph}{MseekGraph}(object, file, writeGraphML = FALSE,
  writeRDS = TRUE)
}
\arguments{
\item{file}{file path to write to}

\item{writeGraphML}{write object to a .graphML file (will drop metadata and some columns)}

\item{writeRDS}{write object to an .mskg (RDS) file; saves the entire object}
}
\value{
the \code{MseekFT} object, with saving event added to processHistory
}
\description{
\code{MseekGraph} objects are \code{\link[igraph]{igraph}} objects
which have layout information and slots that are the same as MseekFT objects,
except that the bulk of data is kept in an \code{igraph} object instead of 
a \code{data.frame}. These objects are read and displayed by the 
\code{\link{NetworkModule}}.

\code{saveMseekGraph}: save a \code{MseekGraph} object to a
 file, registering the save event in the processHistory if the format allows
}
