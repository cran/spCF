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
data(pollutionhealthdata)
dat      <- pollutionhealthdata[pollutionhealthdata$year==2011,]

## -----------------------------------------------------------------------------
y        <- dat[,"observed"]             # count data
x        <- dat[,c("pm10","jsa","price")]# covariates
offset   <- log(dat[,"expected"])        # offset variable

## -----------------------------------------------------------------------------
data(GGHB.IZ)                            # polygons of the 271 zones
coords   <- st_coordinates(st_centroid(GGHB.IZ))# coordinates

## ----fig.width=4.5, fig.height=4----------------------------------------------
GGHB.IZ$y <- y
plot(GGHB.IZ[,"y"],lwd=0.01,axes=TRUE, key.pos=4,nbreaks=50)

## -----------------------------------------------------------------------------
mod_hv   <- cf_glm_hv(y = y, x = x, offset=offset, 
                      coords = coords, family=poisson())

## -----------------------------------------------------------------------------
mod      <- cf_glm(y = y, x = x, offset=offset, 
                   coords = coords, mod_hv = mod_hv)

## -----------------------------------------------------------------------------
mod

## ----fig.height=4, fig.width=4.5----------------------------------------------
# Predictive mean
GGHB.IZ$pred   <- mod$pred$pred
plot(GGHB.IZ[,c("pred")],lwd=0.01,axes=TRUE, key.pos=4,nbreaks=50)

# Predictive SD
GGHB.IZ$pred_sd<- mod$pred$pred_sd
plot(GGHB.IZ[,c("pred_sd")],pal = function(n) hcl.colors(n, "Viridis"), lwd=0.01, 
     axes=TRUE, key.pos=4)

## -----------------------------------------------------------------------------
mod_s1      <- sp_scalewise(mod,bw_range=c(4000,Inf)) # Large scale (4000 <= bandwidth)
mod_s2      <- sp_scalewise(mod,bw_range=c(0,4000))   # Small scale (bandwidth <= 4000)

## ----fig.height=3.5, fig.width=7.5--------------------------------------------
GGHB.IZ$z1  <- mod_s1$pred$pred
GGHB.IZ$z2  <- mod_s2$pred$pred
plot(GGHB.IZ[,c("z1","z2")],lwd=0.01,axes=TRUE,key.pos=4, nbreaks=50)

## -----------------------------------------------------------------------------
library(spCF)
library(sp)
library(sf)

## -----------------------------------------------------------------------------
### Data at samples sites
data(meuse)
flood    <- ifelse(meuse$ffreq==1, 1, 0 )# Binary response variable
coords   <- meuse[,c("x","y")]           # Coordinates
x        <- meuse[,"dist"]               # Covariate

### Data at prediction sites
data(meuse.grid)
coords0  <- meuse.grid[,c("x","y")]      # Coordinates
x0       <- meuse.grid[,"dist"]          # Covariate

## ----fig.width=4.5, fig.height=4----------------------------------------------
obs_s    <- st_as_sf( data.frame(coords, flood), coords= c("x","y"), crs=28992)
plot(obs_s[,"flood"], pch = 20, key.pos=4, axes=TRUE)

## -----------------------------------------------------------------------------
set.seed(1234) # For this vignette, training samples are fixed
mod_hv   <- cf_glm_hv(y = flood, x = x, coords = coords, family=binomial())

## -----------------------------------------------------------------------------
mod      <- cf_glm(y = flood, x=x, coords = coords, 
                   x0=x0, coords0 = coords0, mod_hv = mod_hv)

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
plot(meuse.grid_sf[,"pred_sd"], pal = function(n) hcl.colors(n, "Viridis"),
     border = NA,key.pos=4,axes=TRUE)

## -----------------------------------------------------------------------------
mod_s1<- sp_scalewise(mod,bw_range=c(1000,Inf)) # Large scale (1000 <= bandwidth)
mod_s2<- sp_scalewise(mod,bw_range=c(0,1000))   # Small scale (0 <= bandwidth <= 1000)

## ----fig.height=3.5, fig.width=7.5--------------------------------------------
meuse.grid_sf$z1    <- mod_s1$pred0$pred
meuse.grid_sf$z2    <- mod_s2$pred0$pred
plot(meuse.grid_sf[,c("z1","z2")], border=NA, nbreaks=20, key.pos=4, axes=TRUE)

