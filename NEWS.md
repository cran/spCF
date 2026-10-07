# spCF 0.2.2.1

* Tests only: the `predict()` tests compared predictions made in different
  batches for exact identity. With an alternative BLAS (BLIS, OpenBLAS) the
  matrix products of different sizes are evaluated in a different order, so
  the results agree only up to rounding (about 1e-16); they are now compared
  with a tolerance of 1e-10. No change to the package code.

# spCF 0.2.2

## New features

* `negbin()`: negative binomial family with estimated (or fixed) dispersion
  for `cf_glm_hv()`, `cf_glm()`, `cf_dglm_hv()` and `cf_dglm()`; theta is
  re-estimated after the initial GLM and after each accepted scale.
  `poisson(link = "identity")` is also supported.
* `se_type = "prediction"` now returns a moment-matched observation predictive,
  calibrated to 95% holdout coverage, for the Gamma, inverse Gaussian,
  quasipoisson and quasibinomial families.
* `predict()` methods for `cf_lm()`, `cf_glm()` and `cf_dglm()` fits:
  prediction at new sites (and, for `cf_dglm()`, new time points) without the
  training data. The fits keep the local estimates at the
  knots of every selected scale (well under 1 MB in typical fits), so the cost
  of a prediction does not depend on the size of the training data (about 0.25
  s for 22,500 sites, for 3,000 or 100,000 training sites alike). The result
  is identical to fitting with the same sites as `coords0`.
  `predict()` returns the predictive mean, SD and quantiles at any levels
  (`probs`); without new sites it gives these at the sample sites.
* `cf_lm()`, `cf_glm()` and `cf_dglm()` gain `keep_scales` (default `TRUE`).
  With `keep_scales = FALSE` the scale-wise processes `Z`, `Z_sd`, `Z0` and
  `Z0_sd` are not kept, which makes the fitted object several times smaller;
  predictions are unchanged, and only `sp_scalewise()` needs them.

## Changes in cf_dglm() for prediction times

* Time points in `time0` that are not training time points no longer enter the
  AR(1) time grid of the fit. They are predicted from the smoothed per-knot
  states: bridged between the neighbouring training time points (the AR(1) step
  split in proportion to the time differences), or forecast / backcast by the
  time difference over the median spacing of the training time points. The fit,
  `beta_tv` and `sd_summary` therefore no longer depend on `time0` (an interior
  time point used to add a step to the AR(1) grid and so changed the fit), and
  `predict()` reproduces the predictions later. Forecasts one spacing ahead are
  unchanged.

## Smaller fitted objects

* The quantile tables `pred_q`, `pred0_q`, `pred_q_signal` and `pred0_q_signal`
  (15 columns each) are no longer stored. `mod$pred_q` and the other fields
  still return them at the same 15 levels, computed on access and identical to
  the stored tables of earlier versions.
* The prediction tables `pred` and `pred0` had character row names inherited
  from named prediction vectors, which made them about five times larger than
  their numbers; they now carry automatic row names.
* Together, a `cf_dglm()` fit of 2,000 sites x 100 time points shrinks from
  155 MB to 108 MB (41 MB with `keep_scales = FALSE`), of which 24 MB are the
  knot states kept for `predict()`, and a `cf_lm()` fit of 100,000 sites from
  90 MB to 69 MB (11 MB).

## Changes to predictive variances

* `cf_lm()` and `cf_glm()`: the calibrated variance of each spatial scale is
  now bounded by that scale's share of the field variance, so the predictive
  SD grows smoothly with the distance to the data instead of drawing rings
  around isolated sites (see Details in `?cf_lm`). Point predictions and
  coefficients are unchanged.
* `cf_dglm()`: a distance-aware field variance of the mean, an
  information-scaled calibration, and a floor on the field variance (see
  Details in `?cf_dglm`). Coverage of 95% mean intervals at held-out sites is
  close to nominal in simulations (it was 0.58-0.75). Point predictions are
  unchanged.
* The argument `sill_cap` of `cf_dglm()` is removed: the field variance is
  always capped at the marginal variance of the fitted field (as with the
  default `sill_cap = TRUE` before).
* The noise part of the `cf_lm()` coefficient standard errors (`se_method =
  "opt"`) is rescaled to a nearest-neighbour nugget estimate.

## Bug fixes

* `spCFmap()`: irregular sites with coordinates on a fine common resolution
  (e.g. integer metres, as the meuse sample sites) were taken for a lattice and
  drawn as invisible one-metre pixels; they are now filled from the nearest site.

* `spCFmap()`: irregular prediction sites are still drawn as a raster filled
  from the nearest site, but only within a circle of a common radius around
  each site, so nothing far from a prediction site is coloured. The default
  radius is 0.75 times the median distance to the nearest site (at least 1/300
  of the diagonal of the region), and a "Circle size" slider scales it. Regular
  lattices are drawn as before. For a `cf_dglm()` fit with prediction sites,
  the time slider spans the prediction time points (min(time0) to max(time0))
  instead of the whole training period, and steps by their spacing when they
  are equally spaced.

* `cf_dglm()`: `validation_MAE` in `e_summary` was the absolute mean error
  (absolute bias) instead of the mean absolute error.
* `cf_downscale()`: the intercept row of `beta` was labelled `x` or `V1`; it is
  now `Intercept`, and unnamed covariates are labelled `x1`, `x2`, ...
* `cf_lm()`: no longer warns when the holdout predictions are constant;
  `validation_R2` is then `NA`.
* The calibration of the per-scale variance no longer fails when the holdout
  moment equation has no root in its search interval.

# spCF 0.2.1

* Previous release.
