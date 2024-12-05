make_smr_ab617 <- function(dat.org) {

    dat.ab617 <- dat.org %>%
        filter(ab617 == FALSE) %>%
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
        dat.ab617,
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

