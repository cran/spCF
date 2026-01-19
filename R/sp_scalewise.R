#' Extract scale-wise spatial processes
#'
#' Evaluate mean and variance of the spatial process with bandwidth values
#' within a pre-specified range
#'
#' @param mod Output object from the \code{cf_lm} function.
#' @param bw_range Range of bandwidth values of the simulated spatial processes.
#'   For example, if bw_range = c(10, 20), spatial processes with bandwidths
#'   between 10 and 20 are synthesized and simulated. The default is c(0, Inf),
#'   which synthesizes all scales.
#'
#' @return A list with the following elements:
#' \describe{
#'   \item{pred}{Means and standard deviations of the spatial process (sample sites).}
#'   \item{pred0}{Means and standard deviations of the spatial process (prediction sites).}
#' }
#'
#' @seealso \code{\link{cf_lm}}
#' @author Daisuke Murakami
#'
#' @export
sp_scalewise      <- function(mod, bw_range=c(0,Inf)){

  cols            <- which( mod$bands >= min(bw_range) & mod$bands <= max(bw_range) )
  if( length(cols) >0){
    z_ms          <- data.frame(pred=rowSums(mod$Z[,cols]),
                                pred_sd=sqrt(rowSums(mod$Z_sd[,cols]^2)))
  } else {
    stop("no spatial process detected within the bandwidth rangge (bw_range)")
  }

  z0_ms           <- NULL
  if( !is.na(mod$other$n0) ){
    z0_ms         <- data.frame(pred=rowSums(mod$Z0[,cols]),
                                pred_sd=sqrt(rowSums(mod$Z0_sd[,cols]^2)))
  }

  return(list(pred=z_ms,pred0=z0_ms))
}
