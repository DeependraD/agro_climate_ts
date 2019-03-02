# load libraries
require(tidyverse)
require(lubridate)
require(nasapower)

# # Filter agroclimatological parameters from the list of all parameters
# agmet_community_pars <- map(nasapower::parameters, c("community")) %>% 
#   map(~str_detect(.x, "AG")) %>% 
#   map_lgl(any) %>% 
#   which() %>% 
#   names()
# 
# # Filter daily record parameters from the list of all parameters 
# agmet_temporal_pars <- map(nasapower::parameters, c("include")) %>% 
#   map(~str_detect(.x, "DAILY")) %>% 
#   map_lgl(any) %>% 
#   which() %>% 
#   names()
# 
# # unfortunately providing this parameter list still gives error
# base::intersect(agmet_community_pars, agmet_temporal_pars)

# # direct download using nasapower package
# # since, no defaults are available all argumnets must be completed
# # Also, "SR" is not a valid par for "DAILY" temporal average! so don't bother for that.
# bharatpur2018 <- nasapower::get_power(community = "AG",
#                      temporal_average = "DAILY",
#                      pars = c("RH2M", "T2M", "WS10M", "WD10M",
#                               "T2MDEW", "T2MWET", "T2M_MAX",
#                               "T2M_MIN", "TS", "PRECTOT"),
#                      lonlat = c(84.46, 27.71), # bharatpur
#                      dates = c("2018-01-01", "2018-12-31"))

# saving data in formats other than native format of R (.RData) will
# lead to loss of metadata, so to importing/exporting from other
# file formats, ensure that metadata information is saved alongside.
bharatpur1016 <- read_csv("./data/Bharatpur.csv", comment = "#", na = "-")
bharatpur1016 <- bharatpur1016 %>% 
  mutate(date_rep = date(strptime(paste(YEAR, DOY, sep = " "), format = "%Y %j"))) %>% 
  select(-YEAR, -DOY)

# # if object were datetime setting tz would be meaningful.
# tz(bharatpur1016$date_rep) <- "Asia/Katmandu" # not meaningful for this

# # conversion to datetime object
# bharatpur1016$date_rep <- as_datetime(bharatpur1016$date_rep)
# tz(bharatpur1016$date_rep) <- "Asia/Katmandu" # this is meaningful

# note: if input data were in a different format in dataframe, make_date() function could be used