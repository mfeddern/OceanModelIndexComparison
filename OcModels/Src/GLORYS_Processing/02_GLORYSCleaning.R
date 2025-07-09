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

full_data <- lst%>%
  bind_rows(cst)%>%
  bind_rows(mld)%>%
  mutate(year=year(date), month = month(date))%>%
  select(-date)%>%
  mutate(Model = "GLORYS")

fwrite(full_data, "Data/Yellowtail/MonthlyData.csv")
