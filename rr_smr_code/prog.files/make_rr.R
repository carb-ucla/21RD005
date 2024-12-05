library(INLA)
make_rr <- function(my.dat.org,my.shp.org) {
    
    source("make.adj.R")
    spat.stuff <- make.adj(my.shp.org,my.dat.org,"zip","my.adj.txt")
    my.dat <- spat.stuff$datafile
    my.shp <- spat.stuff$shapefile
    H <- inla.read.graph("my.adj.txt")

    if(nrow(my.dat.org) != nrow(my.dat))
        stop("spatial data error")
    
    f.pois <- Y ~ 1 +
        f(zip.num,
          model="bym2",
          graph=H)

    mod.inla.pois <- inla(
        f.pois,
        family="poisson",
        data=my.dat,
        E=E,
        control.predictor=list(compute=TRUE),
        control.compute=list(return.marginals.predictor=TRUE)
    )

    marg.fitted <- mod.inla.pois$marginals.fitted.values
    my.dat.out <- my.dat %>%
        mutate(
            RR = mod.inla.pois$summary.fitted.values[,"mean"],
            PCER = 100 * (RR - 1),
            exc = sapply(
                marg.fitted,
                FUN = function(x) {
                    1 - inla.pmarginal(1,marginal=x)
                })
        )
    
    my.shp.out <- left_join(
        my.shp,
        my.dat.out,
        by="zip"
    ) %>%
        select(
            Y,
            E,
            SMR,
            RR,
            PCER,
            exc
        )

    ans <- list(
        mod.inla.pois = mod.inla.pois,
        my.shp.out = my.shp.out
    )
    
    ans
}
