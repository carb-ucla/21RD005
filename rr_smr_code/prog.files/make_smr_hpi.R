make_smr_hpi <- function(dat.org,cut.off) {

    dat.hpi <- dat.org %>%
        filter(hpi.per > cut.off) %>%
        group_by(age,sex) %>%
        mutate(
            rate = sum(tcases) / sum(tpop)
        ) %>%
        ungroup() %>%
    distinct(
        age,
        sex,
        rate
    )

    dat <- left_join(
        dat.org,
        dat.hpi,
        by=c("age","sex")
    ) %>%
        mutate(
            e = tpop * rate
        ) %>%
        group_by(zip) %>%
        reframe(
            Y = sum(tcases),
            E = sum(e),
            SMR = sum(tcases) / sum(e)
        )
}

