library(tidyverse)
library(ggplot2)
library(readr)
library(data.table) 
library(lubridate)
library(corrplot)
library(mgcv)
library(dplyr)
library(tidync)

### Data Cleaning ###
lst<-read.csv("Data/GLORYS_Processing/glorys-monthly-means-lst-2021.csv")%>%
  bind_rows(read.csv("Data/GLORYS_Processing/glorys-monthly-means-lst-2025.csv"))%>%
  mutate(variable = "LST")%>%
  pivot_longer(-c(date, variable))
cst<-read.csv("Data/GLORYS_Processing/glorys-monthly-means-cst-2021.csv")%>%
  bind_rows(read.csv("Data/GLORYS_Processing/glorys-monthly-means-cst-2025.csv"))%>%
  mutate(variable = "CST")%>%
  pivot_longer(-c(date, variable))
mld<-read.csv("Data/GLORYS_Processing/glorys-monthly-means-mld2025.csv")%>%
  mutate(variable = "MLD")%>%
  pivot_longer(-c(date, variable))
temp<-read.csv("Data/GLORYS_Processing/glorys-monthly-means-temp-2021.csv")%>%
  bind_rows(read.csv("Data/GLORYS_Processing/glorys-monthly-means-temp-2025.csv"))%>%
  mutate(variable = "Temp")%>%
  pivot_longer(-c(date, variable))

full_data <- lst%>%
  bind_rows(cst)%>%
  bind_rows(mld)%>%
  bind_rows(temp)%>%
  mutate(year=year(date), month = month(date))%>%
  select(-date)%>%
  mutate(Model = "GLORYS")

newnames = c("YV_90_180","YV_0_180","YV_0_90","YV_30_130","YV_180_550",
             "XV_90_180","XV_0_180","XV_0_90","XV_30_130","XV_180_550",
             "MLD_0_180","MLD_0_90", "MLD_30_130",
             "T_90_180","T_0_180","T_0_90","T_30_130","T_180_550")
data.frame(name=unique(full_data$name), newname=)

fwrite(full_data, "Data/Yellowtail/MonthlyData.csv")
