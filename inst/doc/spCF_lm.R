## ----include = FALSE----------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>"
)

## ----setup--------------------------------------------------------------------
library(spCF)
library(sp)
library(sf)

## -----------------------------------------------------------------------------
### Data at samples sites
data(meuse)
y        <- log(meuse[,"zinc"])     # Response variable
coords   <- meuse[,c("x","y")]      # Coordinates
x        <- data.frame(dist   = meuse[,"dist"],
                       ffreq2 = as.integer(meuse$ffreq == 2),
                       ffreq3 = as.integer(meuse$ffreq == 3)) # Covariates

### Data at prediction sites
data(meuse.grid)
coords0  <- meuse.grid[,c("x","y")] # Coordinates
x0       <- data.frame(dist   = meuse.grid[,"dist"],
                       ffreq2 = as.integer(meuse.grid$ffreq == 2),
                       ffreq3 = as.integer(meuse.grid$ffreq == 3)) # Covariates

## ----fig.width=4.5, fig.height=4----------------------------------------------
obs_s    <- st_as_sf( data.frame(coords, zinc=y), coords= c("x","y"), crs=28992)
plot(obs_s[,"zinc"], cex=0.6,pch = 20, nbreaks = 20, key.pos=4, axes=TRUE)

## -----------------------------------------------------------------------------
mod_hv   <- cf_lm_hv(y = y, x = x, coords = coords)

## -----------------------------------------------------------------------------
mod      <- cf_lm(y = y, x = x, x0 = x0, coords = coords, coords0 = coords0, mod_hv = mod_hv)

## -----------------------------------------------------------------------------
mod

## ----fig.height=4, fig.width=4.5----------------------------------------------
### Convert gridded points to gridded polygons (for clear visualization)
meuse.grid_sp             <- meuse.grid
coordinates(meuse.grid_sp)<- c("x", "y")
gridded(meuse.grid_sp)    <- TRUE
meuse.grid_sf             <- st_as_sf(as(meuse.grid_sp, "SpatialPolygons"))
st_crs(meuse.grid_sf)     <- 28992

### Mapping predictive mean and standard deviations
meuse.grid_sf$pred        <- mod$pred0$pred   # Predictive mean
meuse.grid_sf$pred_sd     <- mod$pred0$pred_sd# Predictive standard deviations
plot(meuse.grid_sf[,"pred"], border = NA, nbreaks = 20, key.pos=4,axes=TRUE)
plot(meuse.grid_sf[,"pred_sd"], pal = function(n) hcl.colors(n, "Viridis"), border = NA, 
     nbreaks = 9, key.pos = 4,axes = TRUE)

## -----------------------------------------------------------------------------
mod_s1<- sp_scalewise(mod,bw_range=c(1000,Inf)) # Large scale (1000 <= bandwidth)
mod_s2<- sp_scalewise(mod,bw_range=c(500,1000)) # Moderate scale (500 <= bandwidth < 1000)
mod_s3<- sp_scalewise(mod,bw_range=c(0,500))    # Small scale (bandwidth < 500)

## ----fig.height=3.5, fig.width=7.5--------------------------------------------
meuse.grid_sf$z1    <- mod_s1$pred0$pred   # Large-scale process
meuse.grid_sf$z2    <- mod_s2$pred0$pred   # Moderate-scale process
meuse.grid_sf$z3    <- mod_s3$pred0$pred   # Small-scale process
plot(meuse.grid_sf[,c("z1","z2","z3")],border = NA,key.pos=4,nbreaks=40,axes=TRUE)

## ----fig.height=3.5, fig.width=7.5--------------------------------------------
meuse.grid_sf$z1_sd <- mod_s1$pred0$pred_sd   # Large-scale process
meuse.grid_sf$z2_sd <- mod_s2$pred0$pred_sd   # Moderate-scale process
meuse.grid_sf$z3_sd <- mod_s3$pred0$pred_sd   # Small-scale process
plot(meuse.grid_sf[,c("z1_sd","z2_sd","z3_sd")],
     pal = function(n) hcl.colors(n, "Viridis"),
     border = NA,key.pos=4,axes=TRUE)

