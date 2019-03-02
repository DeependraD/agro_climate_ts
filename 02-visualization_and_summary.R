# load additional libraries
library(xts)
library(scales)
library(timetk)
library(tidyquant)
require(tidyverse)
require(lubridate)
require("PerformanceAnalytics")

# we currently have regular _daily_ time stamped object but this can be converted to other classess
b1016_yearmon_acc_rain <- bharatpur1016 %>% 
  mutate(date_rep = as.yearmon(date_rep)) %>% 
  group_by(date_rep) %>% 
  summarise(accumulated_rain = sum(RAIN, na.rm = TRUE))

# for easing further timeseries operations, lets make a _daily_ stamped dataframe for RAIN only 
b1016_daily_rain <- bharatpur1016 %>% 
  select(RAIN, date_rep)

# Now, for time series analysis, we need to make extract index from objects.
# luckily, date formats automatically recognized by tk_index() function.
idx_date <- tk_index(bharatpur1016)
str(idx_date)

idx_yrqtr <- tk_index(b1016_yearmon_acc_rain)
str(idx_yrqtr)

# decomposing index to a signature (unique set of properties of the 
# time series values that describe the time series)
# this signature is extremely detailed
tk_get_timeseries_signature(idx_date)
tk_get_timeseries_signature(idx_yrqtr)

# To keep the index signature with the data values, we can augment the ts signature.
bharatpur1016_sig <- tk_augment_timeseries_signature(bharatpur1016)
b1016_yearmon_acc_rain_sig <- tk_augment_timeseries_signature(b1016_yearmon_acc_rain)

# Example Benefit 1: Making a month plot
bharatpur1016_sig_mon <- bharatpur1016_sig %>%
  group_by(year, month.lbl) %>%
  summarize(Rain = sum(RAIN)) 

bharatpur1016_sig_mon %>%
  ggplot(aes(x = month.lbl, y = Rain, fill = factor(year))) +
  geom_bar(stat = "identity") +
  labs(title = "Monthly rainfall of Bharatpur locality", x ="", fill = "Year"
       # , subtitle = "Analyzing rainfall metrics with time series signature"
       ) +
  theme_tq() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
  scale_fill_tq() +
  scale_y_continuous(labels = scales::comma)

tk_get_timeseries_summary(idx_date)

# simple line graph showing annual variation
ggplot() +
  # geom_line(data = bharatpur1016, aes(as.POSIXct(date_rep, origin = "1970-01-01"), RAIN)) +
  geom_line(data = bharatpur1016, aes(date_rep, RAIN)) +
  geom_rect(data = data.frame(xmin=date("2015-01-01"),
                              xmax=date("2016-06-01"),
                              ymin=-Inf,
                              ymax=Inf), 
            mapping = aes(xmin = xmin, xmax = xmax, ymin = ymin, ymax = ymax),
            fill="grey", alpha=0.4)

# timeseries objects
# tk_ts objects are similar to ts() objects, just a bit more flexible
# ts() or tk_ts() are good for regularly spaced data, monthly
# for example but for irregular series like daily 
# interval (number of days is variable across years), better to use zoo
sample.xts <- tk_ts(b1016_yearmon_acc_rain, start = c(2010, 1), frequency = 12)
sample.xts <- tk_ts(b1016_daily_rain, start = 2010, frequency = 365.25)

# coersion can be done by zoo(), as.xts() or tk_xts(), but latter is the best
b1016_daily_rain_xts <- b1016_daily_rain %>% 
  mutate(date_rep = as_datetime(date_rep, tz = "Asia/Katmandu")) %>% 
  tk_xts()

b1016_tktbl <- timetk::tk_tbl(data = b1016_daily_rain_xts) %>% 
  mutate(he = c(1, rep(1:4, each = nrow(b1016_daily_rain_xts)/4))) %>%
  group_by(he) %>% 
  summarise(start = first(index),
            end = last(index))

ggplot(b1016_daily_rain_xts, aes(x = index(b1016_daily_rain_xts) %>% 
                                   as_datetime(tz = "Asia/Katmandu"), y = `RAIN`)) + 
  geom_line() +
  labs(x = "Date", y = "Rain (mm)") +
  scale_x_datetime(date_minor_breaks = "1 month", labels = date_format("%d-%m-%Y")) +
  theme_minimal() +
  stat_smooth(color = "#FC4E07", se = FALSE,
              method = "loess") + 
  geom_rect(data = b1016_tktbl,
            aes(xmin = start, xmax = end, ymin = -Inf, ymax = +Inf, group = he),
            alpha = .3, inherit.aes = FALSE)

## Summarizing and date operations
# simmple filter operation on timestamped data
bharatpur1016 %>% 
  filter(date_rep >= "2016-06-01", date_rep < as_date("2016-06-01")+months(1))

# Reading other files
rampur1016 <- read.csv("./data/Rampur.csv", na.strings = c("NA", "-"))
geetanagar1016 <- read.csv("./data/Geetanagar.csv", na.strings = c("NA", "-"))

# We can write a function that shows the periodicity of the time series data.
guess_period <- function(x) { 
  average_period <- as.double( mean(diff(index(x))), units="days" )
  difference <- abs(log( average_period / c(
    daily = 1,
    business_days = 7/5,
    weekly = 7,
    monthly = 30,
    quarterly = 365/4,
    annual = 365
  ) ) )
  names( which.min( difference ) )
}

guess_period(b1016_daily_rain_xts)

