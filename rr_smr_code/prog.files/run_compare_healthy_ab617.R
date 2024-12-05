rm(list=ls())

require(tidyverse); require(broom); require(readxl)
require(sf)
require(INLA)
library(haven)

## Files

file.asthma.2015 <- 'C:/Users/VArputhasamy/Documents/HCAI_ED/Unsuppressed_Output/With_Zeros/ED2015_Asthma_AgeSex_US_fortracking.csv'
## this file is processed slightly differently
## processed in the same way the 2015 file was processed for tracking
## it was generated without loading in 2016 or 2017 at all

file.pop.2015 <- "../pop.files/ACSST5Y2015.S0101-Data.csv"
# file.pop.2016 <- "../pop.files/ACSST5Y2016.S0101-Data.csv"

## Read in Data
dat.asthma.2015 <- read_csv(file.asthma.2015,show_col_types=FALSE)
# dat.asthma.2016 <- read_csv(file.asthma.2016,show_col_types=FALSE)
dat.pop.2015 <- read_csv(file.pop.2015,skip=1,show_col_types = FALSE)
# dat.pop.2016 <- read_csv(file.pop.2016,skip=1,show_col_types = FALSE)

## Make combined data - works for 2015, 2016

## Shapefiles

file.ab617.shp <- "../shp.files/pop_weighted_zips.shp"
ab617.shp <- as_tibble(read_sf(file.ab617.shp)) %>%
    mutate(
        zip = as.character(STD_ZIP5),
        ab617 = TRUE
    ) %>%
    select(
        zip,
        ab617
    )

source("make_data_sim.R")
dat.asthma.tpop.2015.org <- make_data_sim(dat.asthma.2015,dat.pop.2015)
dat.asthma.tpop.2015 <- left_join(
    dat.asthma.tpop.2015.org,
    ab617.shp,
    by="zip"
) %>%
    mutate(
        ab617 = if_else(is.na(ab617),FALSE,ab617)
    ) %>%
    select(
        year,
        ab617,
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
#     ab617.shp,
#     by="zip"
# ) %>%
#     mutate(
#         ab617 = if_else(is.na(ab617),FALSE,ab617)
#     ) %>%
#     select(
#         year,
#         ab617,
#         zip,
#         age,
#         sex,
#         tcases,
#         outcome,
#         tpop,
#         n
#     )

## Make SMR

source("make_smr_ab617.R")
dat.smr.2015 <- make_smr_ab617(dat.asthma.tpop.2015) %>%
        select(
        zip,
        Y,
        E,
        SMR
    )

# dat.smr.2016 <- make_smr_ab617(dat.asthma.tpop.2016) %>%
#         select(
#         zip,
#         Y,
#         E,
#         SMR
#     )

file.shp <- "../shp.files/tl_2010_06_zcta510.shp"
zip.shp <- read_sf(file.shp) %>%
    mutate(zip = as.character(ZCTA5CE10))

source("make_rr.R")
rr.2015.ab617 <- make_rr(dat.smr.2015,zip.shp)
save(rr.2015.ab617,file="rr.2015_compare_ab617.obj")
rr.2015.ab617.shp <- rr.2015.ab617$my.shp.out
st_write(rr.2015.ab617.shp, 
         "C:/Users/VArputhasamy/Documents/RR_SMR_V2_0411/RR_SMR/outfiles/2015_ab617_shapefiles/rr.2015.ab617.shp")
rr.2015.ab617.mod <- rr.2015.ab617$mod.inla.pois
print(summary(rr.2015.ab617.mod))

rr.2016.ab617 <- make_rr(dat.smr.2016,zip.shp)
save(rr.2016.ab617,file="rr.2016_compare_ab617.obj")
rr.2016.ab617.shp <- rr.2016.ab617$my.shp.out
rr.2016.ab617.mod <- rr.2016.ab617$mod.inla.pois
print(summary(rr.2016.ab617.mod))

