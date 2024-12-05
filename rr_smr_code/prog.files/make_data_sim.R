require(tidyverse); require(broom); require(readxl)
require(sf)
require(INLA)
library(haven)

### TRACKING VERSION ##

make_data_sim <- function(dat.asthma.input,dat.pop.input) {

    dat.asthma.clean.org <- dat.asthma.input %>%
        select(-`...1`) %>%
        mutate(
            year = as.integer(year),
            zip = as.character(zip),
            tcases = as.integer(if_else(tcases == "<12",NA,tcases))
        ) %>%
        filter(sex != "U")

    if(nrow(dat.asthma.clean.org) != nrow(na.omit(dat.asthma.clean.org))) {
                
        print("Impute tcases - Is this what you want?")
        
        dat.asthma.clean <- dat.asthma.clean.org %>%
            group_by(age,sex) %>%
            mutate(
                tcases = if_else(is.na(tcases),round(mean(tcases,na.rm=TRUE)),tcases)
            )
        
        if(nrow(dat.asthma.clean) != nrow(na.omit(dat.asthma.clean)))
          stop("Data error")
    }
    
## EDIT BY VA: MOVED SECOND IF STATEMENT IN LINE 26 INTO THE FIRST IF STATEMENT 
    
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

    
    dat.join.clean.org <- left_join(
      dat.asthma.clean.org,
      dat.pop.clean,
      by=c("zip","age","sex")
    ) %>%
      arrange(zip,age,sex) %>%
      filter(tpop > 0) %>%
      drop_na()
    
    
    if(nrow(dat.asthma.clean.org) != nrow(na.omit(dat.asthma.clean.org))) {
      
      dat.join.clean <- left_join(
        dat.asthma.clean,
        dat.pop.clean,
        by=c("zip","age","sex")
      ) %>%
        arrange(zip,age,sex) %>%
        filter(tpop > 0) %>%
        drop_na()
 
    }
    
# edit by VA: created dat.join.clean.org which combines dat.asthma.clean.org and dat.pop.clean
# previously the code combined dat.asthma.clean with dat.pop.clean and was giving an error because
# dat.asthma.clean only gets created if there are na's in dat.asthma.clean.org (and with the 2015 data there 
# were no missing data)
    

## Crude check (edited to include this for when dat.asthma.clean is not created)
    
    dat.join.v1 <- dat.join.clean.org %>%
      group_by(zip) %>%
      mutate(n=n()) %>%
      ungroup() %>%
      filter(n == n_distinct(dat.join.clean.org$age)*n_distinct(dat.join.clean.org$sex))
    
    n.incomplete.v1 <- nrow(dat.join.clean.org) - nrow(dat.join.v1)
    print(str_c("There are ",n.incomplete.v1," zip codes with missing categories"))
    
    dat.join.v1

    
    
## Crude check (if dat.join.clean is created) (edited to include 'if' so R only creates this when
## there's missing data, and thus dat.asthma.clean is created)
    
if(nrow(dat.asthma.clean.org) != nrow(na.omit(dat.asthma.clean.org))) {
    
    dat.join.v2 <- dat.join.clean %>%
        group_by(zip) %>%
        mutate(n=n()) %>%
        ungroup() %>%
        filter(n == n_distinct(dat.join.clean$age)*n_distinct(dat.join.clean$sex))

    n.incomplete.v2 <- nrow(dat.join.clean) - nrow(dat.join.v2)
    print(str_c("There are ",n.incomplete.v2," zip codes with missing categories"))

    dat.join.v2
  }
   
    return(dat.join.v1)
    
    if(nrow(dat.asthma.clean.org) != nrow(na.omit(dat.asthma.clean.org))) {
    
      return(dat.join.v2)
    }
    
    ## edit by VA: added return statements
}



