require(tidyverse); require(broom); require(readxl)
require(sf)
require(INLA)
library(haven)

make_data <- function(dat.asthma.input,dat.pop.input) {

    dat.asthma.clean <- dat.asthma.input %>%
        select(-`...1`) %>%
        mutate(
            year = as.integer(year),
            zip = as.character(zip),
            tcases = as.integer(if_else(tcases == "<12",NA,tcases))
        ) %>%
        filter(sex != "U")

    ## print("Fix this!!!")
    ## dat.asthma.clean <- dat.asthma.clean %>%
    ##     drop_na(-tcases) %>%
    ##     filter(sex != "U") %>%
    ##     group_by(age,sex) %>%
    ##     mutate(
    ##         tcases = if_else(is.na(tcases),round(mean(tcases,na.rm=TRUE)),tcases)
    ##     )

    if(nrow(dat.asthma.clean) != nrow(na.omit(dat.asthma.clean)))
        stop("Data error - can't use suppressed data")
    
    dat.pop.clean <- dat.pop.input %>%
        select(-`...435`) %>%
        mutate(
            across(everything(),as.character), ## make all character
            across(everything(),~na_if(.x,"-")) ## make "-" NA
        ) %>%
        separate_wider_delim( ## get just zip code bit 
            `Geographic Area Name`,
            delim = " ",
            names=c(NA,"zip")
        ) %>%
        mutate( ## label totals for male and female
            male_total = as.numeric(`Male!!Estimate!!Total population`),
            female_total = as.numeric(`Female!!Estimate!!Total population`)
        ) %>%
        select( ## Just get what we need
        (contains("Male!!Estimate!!AGE") | contains("Female!!Estimate!!AGE")) &
        !contains("Annotation") & !contains("Margin"),
        zip,
        male_total,
        female_total
        ) %>%
        arrange(zip) %>%
        pivot_longer( ## make long format
            cols = !c(zip,male_total,female_total),
            names_to = "age_org",
            values_to = "perc"
        ) %>%
        mutate( ## relabel
            perc = as.double(perc),
            age = case_when(
                str_detect(age_org,"Under|5 to 9|10 to 14|15 to 19") ~ "00_19",
                str_detect(age_org,"20 to 24|25 to 29|30 to 34|35 to 39|40 to 44") ~ "20_44",
                str_detect(age_org,"45 to 49|50 to 54|55 to 59|60 to 64") ~ "45_64",
                str_detect(age_org,"65 to 69|70 to 74|75 to 79|80 to 84|85 years and over") ~ "65+",
                .default = as.character(NA)
            ),
            sex = case_when( ## define sex
                str_detect(age_org,"Male") ~ "M",
                str_detect(age_org,"Female") ~ "F",
                .default = as.character(NA)
            ),
            tpop = case_when(
                sex == "M" ~ male_total * perc / 100.0,
                sex == "F" ~ female_total * perc / 100.0,
                .default = as.numeric(NA)
            )
        ) %>%
        group_by(zip,age,sex) %>%
        reframe(
            tpop = sum(tpop)
        ) %>%
        select(zip,age,sex,tpop) %>%
        arrange(zip,age,sex)

    dat.join <- left_join(
        dat.asthma.clean,
        dat.pop.clean,
        by=c("zip","age","sex")
    ) %>%
        arrange(zip,age,sex) %>%
        filter(!is.na(tpop),tpop > 0) %>%
        drop_na()

    ## Crude check
    dat.join <- dat.join %>%
        group_by(zip) %>%
        mutate(n=n()) %>%
        ungroup() %>%
        filter(n == n_distinct(dat.join$age)*n_distinct(dat.join$sex))
}



