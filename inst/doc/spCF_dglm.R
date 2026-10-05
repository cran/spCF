## ----include = FALSE----------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>"
)

## ----setup--------------------------------------------------------------------
library(spCF)
library(sf)

## -----------------------------------------------------------------------------
air <- read.csv(system.file("shiny", "spCFmap", "example_spacetime_air.csv",
                            package = "spCF"))
str(air)

## -----------------------------------------------------------------------------
range(table(air$station))                    # observations per station

## -----------------------------------------------------------------------------
pts    <- st_as_sf(air, coords = c("lon", "lat"), crs = 4326)
coords <- st_coordinates(st_transform(pts, 25832))
colnames(coords) <- c("px", "py")

## -----------------------------------------------------------------------------
y    <- air$pm10                                    # response
time <- air$time                                    # time index
x    <- data.frame(sin12 = sin(2 * pi * air$month / 12),
                   cos12 = cos(2 * pi * air$month / 12))

## ----fig.width=4.5, fig.height=4.5--------------------------------------------
loc          <- air[!duplicated(air$station), c("station", "lon", "lat")]
loc$pm10_ave <- tapply(air$pm10, air$station, mean)[loc$station]
loc_sf       <- st_as_sf(loc, coords = c("lon", "lat"), crs = 4326)
plot(loc_sf[, "pm10_ave"], pch = 20, cex = 1.3, axes = TRUE,
     key.pos = 4, nbreaks = 20)

## -----------------------------------------------------------------------------
mod_hv <- cf_dglm_hv(y = y, x = x, coords = coords, time = time)

## -----------------------------------------------------------------------------
uni   <- unique(as.data.frame(coords))
hull  <- st_convex_hull(st_union(st_as_sf(uni, coords = c("px", "py"))))
gcen  <- st_make_grid(hull, cellsize = 25000, what = "centers")
gcen  <- gcen[st_intersects(gcen, hull, sparse = FALSE)[, 1]]
gxy   <- st_coordinates(gcen)
nrow(gxy)

## -----------------------------------------------------------------------------
tp      <- c(49, 55, 61)                            # Jan-2005, Jul-2005, Jan-2006
month0  <- c(1, 7, 1)
ng      <- nrow(gxy)
coords0 <- do.call(rbind, replicate(length(tp), gxy, simplify = FALSE))
time0   <- rep(tp, each = ng)
x0      <- data.frame(sin12 = sin(2 * pi * rep(month0, each = ng) / 12),
                      cos12 = cos(2 * pi * rep(month0, each = ng) / 12))

## -----------------------------------------------------------------------------
mod <- cf_dglm(y = y, x = x, coords = coords, time = time,
               x0 = x0, coords0 = coords0, time0 = time0, mod_hv = mod_hv)

## -----------------------------------------------------------------------------
mod

## -----------------------------------------------------------------------------
round(mod$bands / 1000, 1)      # bandwidth of each accepted scale, in km

## ----fig.width=7.5, fig.height=4----------------------------------------------
grid_sf         <- st_as_sf(as.data.frame(gxy), coords = c("X", "Y"))
grid_sf$Jan2005 <- mod$pred0$pred[time0 == 49]
grid_sf$Jul2005 <- mod$pred0$pred[time0 == 55]
plot(grid_sf[, c("Jan2005", "Jul2005")], pch = 15, cex = 1.9,
     axes = TRUE, key.pos = 4, nbreaks = 20)

## ----fig.width=4.5, fig.height=4.5--------------------------------------------
grid_sf$Jan2005_sd <- mod$pred0$pred_sd[time0 == 49]
plot(grid_sf[, "Jan2005_sd"], pch = 15, cex = 1.9, axes = TRUE, key.pos = 4,
     pal = function(n) hcl.colors(n, "Viridis"))

## ----fig.width=7.5, fig.height=4----------------------------------------------
grid_sf$Jan2006 <- mod$pred0$pred[time0 == 61]
plot(grid_sf[, c("Jan2005", "Jan2006")], pch = 15, cex = 1.9,
     axes = TRUE, key.pos = 4, nbreaks = 20)

## -----------------------------------------------------------------------------
tapply(mod$pred0$pred_sd, time0, mean)

## ----eval = FALSE-------------------------------------------------------------
# mod_f <- cf_dglm(y = y, x = x, coords = coords, time = time,
#                  mod_hv = mod_hv)                    # no x0, coords0, time0
# p63   <- predict(mod_f, coords0 = gxy, time0 = rep(63, ng),
#                  x0 = data.frame(sin12 = rep(sin(2 * pi * 3 / 12), ng),
#                                  cos12 = rep(cos(2 * pi * 3 / 12), ng)),
#                  probs = c(0.05, 0.95))

## -----------------------------------------------------------------------------
p63 <- predict(mod, coords0 = gxy, time0 = rep(63, ng),
               x0 = data.frame(sin12 = rep(sin(2 * pi * 3 / 12), ng),
                               cos12 = rep(cos(2 * pi * 3 / 12), ng)),
               probs = c(0.05, 0.95))
head(p63)

## -----------------------------------------------------------------------------
head(mod$pred0_q[time0 == 61, c("q0.05", "q0.95")])

## ----eval = FALSE-------------------------------------------------------------
# mod_small <- cf_dglm(y = y, x = x, coords = coords, time = time,
#                      x0 = x0, coords0 = coords0, time0 = time0,
#                      mod_hv = mod_hv, keep_scales = FALSE)

## -----------------------------------------------------------------------------
mod_l <- sp_scalewise(mod, bw_range = c(150000, Inf))   # large scale (>= 150 km)
mod_s <- sp_scalewise(mod, bw_range = c(0, 150000))     # small scale (< 150 km)
head(mod_l$pred, 3)

## ----fig.width=7.5, fig.height=4----------------------------------------------
win <- sp_scalewise(mod, bw_range = c(150000, Inf), time_range = c(49, 51))
smr <- sp_scalewise(mod, bw_range = c(150000, Inf), time_range = c(55, 57))
sea <- st_as_sf(data.frame(win$pred[, c("px", "py")],
                           winter = win$pred$pred,
                           summer = smr$pred$pred),
                coords = c("px", "py"))
plot(sea[, c("winter", "summer")], pch = 20, cex = 1.2,
     axes = TRUE, key.pos = 4, nbreaks = 20)

## ----eval = FALSE-------------------------------------------------------------
# spCFmap()

## ----eval = FALSE-------------------------------------------------------------
# spCFmap(mod, crs = 25832)

