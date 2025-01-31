rm(list=ls())

require(tidyverse); require(broom); require(readxl)
require(sf)
require(INLA)
library(haven)

## Files


file.asthma.2015 <- 'path/to/your/file.csv'
## this file is processed slightly differently
## processed in the same way the 2015 file was processed for tracking
## it was generated without loading in 2016 or 2017 at all

#file.asthma.2016 <- "path/to/your/file.csv"

file.pop.2015 <- "../pop.files/ACSST5Y2015.S0101-Data.csv"
#file.pop.2016 <- "../pop.files/ACSST5Y2016.S0101-Data.csv"

## Read in Data
dat.asthma.2015 <- read_csv(file.asthma.2015,show_col_types=FALSE)
#dat.asthma.2016 <- read_csv(file.asthma.2016,show_col_types=FALSE)
dat.pop.2015 <- read_csv(file.pop.2015,skip=1,show_col_types = FALSE)
#dat.pop.2016 <- read_csv(file.pop.2016,skip=1,show_col_types = FALSE)

## Make combined data - works for 2015, 2016

file.hpi <- "../pop.files/hpiscore_2015.csv"
hpi <- as_tibble(read.csv(file.hpi)) %>%
    mutate(
        zip = as.character(geoid),
        hpi.per = percentile
    ) %>%
    select(
        zip,
        hpi.per
    )

source("make_data_sim.R")
dat.asthma.tpop.2015.org <- make_data_sim(dat.asthma.2015,dat.pop.2015)
dat.asthma.tpop.2015 <- left_join(
    dat.asthma.tpop.2015.org,
    hpi,
    by="zip"
) %>%
    select(
        year,
        hpi.per,
        zip,
        age,
        sex,
        tcases,
        outcome,
        tpop,
        n
    )

# dat.asthma.tpop.2016.org <- make_data_sim(dat.asthma.2016,dat.pop.2016)
# dat.asthma.tpop.2016 <- left_join(
#     dat.asthma.tpop.2016.org,
#     hpi,
#     by="zip"
# ) %>%
#     select(
#         year,
#         hpi.per,
#         zip,
#         age,
#         sex,
#         tcases,
#         outcome,
#         tpop,
#         n
#     )

## Make SMR

source("make_smr_hpi.R")
cut.off <- 0.90
dat.smr.2015 <- make_smr_hpi(dat.asthma.tpop.2015,cut.off) %>%
    select(
        zip,
        Y,
        E,
        SMR
    )
        
# dat.smr.2016 <- make_smr_hpi(dat.asthma.tpop.2016,cut.off) %>%
#     select(
#         zip,
#         Y,
#         E,
#         SMR
#     )

file.shp <- "../shp.files/tl_2010_06_zcta510.shp"
zip.shp <- read_sf(file.shp) %>%
    mutate(zip = as.character(ZCTA5CE10))

source("make_rr.R")
rr.2015.hpi <- make_rr(dat.smr.2015,zip.shp)
save(rr.2015.hpi,file="rr.2015_compare_hpi.obj")
rr.2015.hpi.shp <- rr.2015.hpi$my.shp.out
st_write(rr.2015.hpi.shp, 
         "path/to/your/file.shp")
rr.2015.hpi.mod <- rr.2015.hpi$mod.inla.pois
print(summary(rr.2015.hpi.mod))




# rr.2016.hpi <- make_rr(dat.smr.2016,zip.shp)
# save(rr.2016.hpi,file="rr.2016_compare_hpi.obj")
# rr.2016.hpi.shp <- rr.2016.hpi$my.shp.out
# rr.2016.hpi.mod <- rr.2016.hpi$mod.inla.pois
# print(summary(rr.2016.hpi.mod))

