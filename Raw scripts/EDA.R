# Loading in the data
stepsMonitor <- read.csv(unz("activity.zip", "activity.csv"), header = TRUE)

# Converting date column into the date class
stepsMonitor$date <- as.Date(stepsMonitor$date)
# Adding one more column for wwekdays corresponding to the dates
stepsMonitor$weekdays <- weekdays(stepsMonitor$date)

# Creating 2 tables from the data
# 1. Summarize the total number of steps for each day
# NAs are ignored
library(dplyr)
stepsbyday <- summarize(stepsMonitor,
                        total = sum(steps, na.rm = TRUE),
                        .by = "date")

# 2. Summarize the average number of steps for each 5 min interval
# NAs are ignored
stepsbyinterval <- summarize(stepsMonitor,
                             average = mean(steps, na.rm = TRUE),
                             .by = "interval")
# Adding another column to this which represents the time of day
stepsbyinterval$time <- seq(0,1439,5) * 60 #Creates a vector of seconds since 12am

# Convert it into a POSIXct class to represent time
# the date and timezone are just a place holder for easier plotting
# with scale_x_datetime function later
stepsbyinterval$time <- as.POSIXct(stepsbyinterval$time, tz = "UTC")

# Total number of steps taken each day
stepsbyday

# Histogram of total number of steps taken each day
library(ggplot2)
ggplot(stepsbyday, aes(total)) +
    geom_histogram(binwidth = 3000, fill = "blue", color = "black") +
    scale_x_continuous(breaks = seq(min(stepsbyday$total),max(stepsbyday$total), 3000)) +
    labs(title = "Total steps taken per day", x ="Total steps",
         y = "Counts") +
    theme_bw(base_size = 18)

# Mean and median of total number of steps taken each day
summary(stepsbyday$total)

# Time series plot of average steps taken for each 5 minute interval
library(ggplot2)
ggplot(stepsbyinterval, aes(time, average)) +
    geom_line(color = "#00B0F6", linewidth = 1) +
    scale_x_datetime(date_breaks = "2 hour", date_labels = "%H:%M") +
    labs(title = "Average daily activity pattern", x ="Time of day",
         y = "Average steps") +
    theme_bw(base_size = 18)

# 5 min interval with maximum number of steps on average
maxStepsind <- which.max(stepsbyinterval$average)
cat(paste0("5-min interval identifier : ",stepsbyinterval$interval[maxStepsind],
           "\nTime of day : ",format(stepsbyinterval$time[maxStepsind], "%H:%M")))

# Number of rows with missing values in the data set
sum(!complete.cases(stepsMonitor))
mean(!complete.cases(stepsMonitor))

## Strategy for imputing NA values
# Find out average steps taken for
# each combination of weekday and 5 minute interval
stepsbyWeekdayandInterval <- summarize(stepsMonitor,
                                    average = mean(steps, na.rm = TRUE),
                                    .by = c("weekdays", "interval"))

# Creating the imputed data set
ImputedStepsMonitor <- stepsMonitor

# Imputing the missing values with the mean matching weekday AND 5 min interval
# rounded to the nearest whole number
ImputedStepsMonitor$steps <- round(mapply(
    function(steps, weekday, interval) {
    if(is.na(steps)) {
        steps <- stepsbyWeekdayandInterval$average[
            which(stepsbyWeekdayandInterval$weekdays == weekday &
                      stepsbyWeekdayandInterval$interval == interval)]
    }
        else {steps}
}, ImputedStepsMonitor$steps,
ImputedStepsMonitor$weekdays,
ImputedStepsMonitor$interval))

# summarizes the total number of steps for each day
Imputedstepsbyday <- summarise(ImputedStepsMonitor,
                        total = sum(steps),
                        .by = "date")

# Histogram of total number of steps taken each day
library(ggplot2)
ggplot(Imputedstepsbyday, aes(total)) +
    geom_histogram(binwidth = 3000, fill = "blue", color = "black") +
    theme_bw()

# Mean and median of total number of steps taken each day
summary(Imputedstepsbyday$total)

# Dividing the imputed data set into weekdays and weekends
ImputedStepsMonitor <- ImputedStepsMonitor %>%
    mutate(weekdays = ifelse(weekdays %in% c("Saturday", "Sunday"),
                             "Weekends", "Weekdays")) %>%
    mutate(weekdays = as.factor(weekdays))

# Summarizing the average number of steps for each 5 min interval
# averaged over weekday days or weekend days
Imputedstepsbyinterval <- summarize(ImputedStepsMonitor,
                             average = mean(steps),
                             .by = c("interval", "weekdays"))
# Adding another column to this which represents the time of day
Imputedstepsbyinterval$time <- seq(0,1439,5) * 60 #Creates a vector of seconds since 12am
# Convert it into a POSIXct class to represent time
# the date and timezone are just a place holder for easier plotting
# with scale_x_datetime function later
Imputedstepsbyinterval$time <- as.POSIXct(Imputedstepsbyinterval$time, tz = "UTC")

# Time series plot of average steps taken for each 5 minute interval
library(ggplot2)
ggplot(Imputedstepsbyinterval, aes(time, average, color = weekdays)) +
    geom_line(linewidth = 1) +
    facet_wrap(~weekdays, nrow = 2) +
    scale_x_datetime(date_breaks = "2 hour", date_labels = "%H:%M") +
    theme()
