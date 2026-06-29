## ----include = FALSE----------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>"
)

## ----setup--------------------------------------------------------------------
library(spCF)
library(sf)
library(CARBayesdata)

## -----------------------------------------------------------------------------
set.seed(123)
data(GGHB.IZ)
data(pollutionhealthdata)
d  <- pollutionhealthdata[pollutionhealthdata$year == 2010, ]
ar <- merge(GGHB.IZ, d, by = "IZ")

## -----------------------------------------------------------------------------
### Disaggregate-level data (271 units)
coords      <- st_coordinates(suppressWarnings(st_centroid(ar)))
x           <- data.frame(pm10 = ar$pm10, jsa = ar$jsa, price = ar$price)
prop_weight <- as.numeric(ar$expected)

## -----------------------------------------------------------------------------
### Aggregate-level ID (30 units)
agg_id      <- as.integer(stats::kmeans(coords, centers = 30)$cluster)

## -----------------------------------------------------------------------------
### Y_type = "sum"  : Y_I = sum(response for each aggregate-level unit)
### Y_type = "mean" : Y_I = mean(response for each aggregate-level unit)
Y_type      <- "sum"
Y           <- as.numeric(stats::aggregate(ar$observed, by = list(agg_id),
                          FUN = if (Y_type == "sum") sum else mean)[, 2])

## -----------------------------------------------------------------------------
mod_hv   <- cf_downscale_hv(Y = Y, Y_type = Y_type, x = x,
                            prop_weight = prop_weight,
                            coords = coords, agg_id = agg_id)

## -----------------------------------------------------------------------------
mod      <- cf_downscale(Y = Y, x = x, prop_weight = prop_weight,
                         coords = coords, agg_id = agg_id, mod_hv = mod_hv)

## -----------------------------------------------------------------------------
mod

## ----fig.height=3.5, fig.width=7.5--------------------------------------------
### Aggregate-level polygons and response
ar$agg_id <- agg_id
agg_poly  <- stats::aggregate(ar["agg_id"], by = list(agg_id = agg_id),
                              FUN = function(z) z[1])
agg_poly$Y<- Y

### Disaggregate-level predictive mean
ar$pred   <- mod$pred$pred

plot(agg_poly["Y"], nbreaks = 20, key.pos = 4, axes = TRUE, lwd=0.2,
     main = "Aggregated data (30 units)")
plot(ar["pred"], nbreaks = 20, key.pos = 4, axes = TRUE, border = NA,
     main = "Downscaling result (271 units)")

## ----fig.height=4, fig.width=4.5----------------------------------------------
ar$pred_sd <- mod$pred$pred_sd
plot(ar["pred_sd"], pal = function(n) hcl.colors(n, "Viridis"), nbreaks = 9, border = NA,
     key.pos = 4, axes = TRUE)

