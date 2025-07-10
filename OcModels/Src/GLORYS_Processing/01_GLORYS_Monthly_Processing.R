library(tidyverse)
library(ggplot2)
library(readr)
library(data.table) 
library(lubridate)
library(corrplot)
library(mgcv)
library(dplyr)
library(tidync)
### Data Prep Function ###

data_prep <- function(data.file, bathy_file=NULL, shore_dist=NULL, mld=NULL, lat_min=NULL, lat_max=NULL){
  dx = data.table(data.file)
  # shorten some names
  dx = dx %>% rename(lat = latitude, lon=longitude)
  if(!is.null(lat_min)){print("subsetting by min depth") ; dx = dx[lat>=lat_min,,]}
  if(!is.null(lat_max)){print("subsetting by min depth") ; dx = dx[lat<=lat_max,,]}
  # time to date
  print("Adding date")
  dx[,date:=as.Date(dx$time),]
  dx[,time:=NULL] # remove time
  # add bathy
  if(!is.null(bathy_file)){
    print("Adding bottom depth")
    # bathy_file[,date:=lubridate::as_date(bathy_file$date/24,origin="1950-01-01 00:00:00"),]
    dx = merge.data.table(dx, bathy_file, by=c("lat","lon"))}
  if(!is.null(shore_dist)){
    print("Adding distance to shore")
    # shore_dist[,date:=lubridate::as_date(shore_dist$date/24,origin="1950-01-01 00:00:00"),]
    dx = merge.data.table(dx, shore_dist, by=c('lat','lon'))}
  if(!is.null(mld)){
    print("Adding MLD")
    # mld[,date:=lubridate::as_date(mld$date/24,origin="1950-01-01 00:00:00"),]
    mld[,bottom_depth:=NULL,] # remove bottome depth from mld file. 
    # if not included in the join. messes up join for some reason
    dx = merge.data.table(dx, mld, by=c('lat','lon', 'date'))
    dx = dx %>% rename(mld = mlotst)}
  # subet just the lat/depth ranges. subset months in next file
  return(dx)
}


# bring in bottom depth to add to other files ##################################
# bathymetry from GLORYS
df <- #tidync::tidync(paste0(data_raw,'glorys-bathymetry.nc')) %>% 
  tidync::tidync('Data/GLORYS_Processing/glorys-bathymetry.nc') %>% #for Megan's set up
  hyper_tibble( force = TRUE) %>%
  drop_na() %>% 
  group_by(longitude,latitude)

# head(df)
dt_bathy <- data.table(df)
dt_bathy = dt_bathy %>% rename(lat = latitude, lon = longitude, bottom_depth = deptho)
head(dt_bathy)
tail(dt_bathy)
fwrite(dt_bathy, "Data/GLORYS_Processing/bathymetry-m.csv")
rm(df)

# distance from shore ##########################################################
#not necessary for yellowtail??

#dist_shore = data.frame(read.csv(
#  "~/GitHub/glorys-download/GLORYS distance to shore 15May2024.csv", header=TRUE))
#head(dist_shore)
#d_shore = dist_shore[,c("longitude","latitude", 'Distance.to.shore..km.', 'Water_land')]
#d_shore = d_shore %>% rename(lat=latitude, lon=longitude, dist_shore_km = Distance.to.shore..km.)
#head(d_shore)
#fwrite(d_shore, paste0(data_dir,'distance-to-shore.csv'))


# MONTHY MIXED-LAYER-DEPTH #####################################################

# dir(data_raw)
# for filtering monthly transport below

df1 <- tidync::tidync("Data/GLORYS_Processing/glorys-monthly-MLD-1993-01-01-2021-06-30-1200m.nc") %>% 
  tidync::hyper_tibble( ) %>%
  drop_na() %>% 
 # mutate_at(vars(longitude, latitude), as.numeric)%>%
 # mutate(time=as.numeric(as.Date(time, format="%Y-%m-%d")))%>%
  group_by(longitude,latitude,time)

df2 <- tidync::tidync(paste0("Data/GLORYS_Processing/glorys-monthly-MLD-2021-07-01-2025-03-01-1200m.nc")) %>% 
  hyper_tibble( force = TRUE) %>%
  drop_na() %>% 
  #mutate_at(vars(longitude, latitude), as.numeric)%>%
 # mutate(time=as.numeric(as.Date(time, format="%Y-%m-%d")))%>%
  group_by(longitude,latitude,time) 

dt = rbindlist( list(df1,df2)) # faster; now a data.table
# clean up for space
#rm(df2)

dt$time
write.csv(dt,"Data/GLORYS_Processing/MLD_combined.csv")

mld_monthly <- data_prep(data.file=dt, bathy_file = dt_bathy)

rm(dt)
head(mld_monthly)
dim(mld_monthly)

mld_monthly = mld_monthly[lat>40,,]

# use mld_monthly to combine with other files because it contains lat long info

# mld_monthly_processed for time series if included
mld_0_180 = mld_monthly[bottom_depth >= 0 & bottom_depth <=180,.(mld_0_180 = mean(mlotst)), by='date']
mld_0_90  = mld_monthly[bottom_depth >= 0 & bottom_depth <=90, .(mld_0_90 = mean(mlotst)), by='date']
mld_30_130  = mld_monthly[bottom_depth >= 30 & bottom_depth <=130 , .(mld_30_130 = mean(mlotst)), by='date']

# no loop here so don't need the if statement

mld_month_out = left_join(mld_0_180, mld_0_90)
mld_month_out = left_join(mld_month_out, mld_30_130)

fwrite(mld_month_out, "Data/GLORYS_Processing/glorys-monthly-means-mld2025.csv") 

rm(mld_month_out, mld_0_180, mld_0_90, mld_30_130)

# continue here ####

# MONTHLY CROSS SHELF TRANSPORT ################################################

x<-"Data/GLORYS_Processing/glorys-monthly-crossshelf-eastward-2021-07-01-2025-03-01-1200m.nc"

for(i in 1:length(x)){ 
  print(x[i])
  (t1 = Sys.time())
  dfx <- tidync::tidync(paste0(x[i])) %>% 
    hyper_tibble( force = TRUE) %>%
    drop_na() %>% 
    group_by(longitude,latitude,time)
  
  dt_cst = data_prep(data.file=dfx, bathy_file = dt_bathy)
  rm(dfx) # clean up memory for space
  # as in temporary not temperature
  
  # calculations for depth x lat zones = mean daily value
  # subset and average by date later
  
  cst_90_180 = dt_cst[bottom_depth >= 90 & bottom_depth <=180 , .(cst_90_180 = mean(uo)), by='date']
  cst_0_180 = dt_cst[bottom_depth >= 0 & bottom_depth <=180 , .(cst_0_180 = mean(uo)), by='date']
  cst_0_90 = dt_cst[bottom_depth >= 0 & bottom_depth <=90 , .(cst_0_90 = mean(uo)), by='date']
  cst_30_130 = dt_cst[bottom_depth >= 30 & bottom_depth <=130 , .(cst_30_130 = mean(uo)), by='date']
  cst_180_549 = dt_cst[bottom_depth >= 180 & bottom_depth <=549 , .(cst_180_549 = mean(uo)), by='date']
  
  rm(dt_cst)
  
  if(i==1){
    CST_90_180 = cst_90_180
    CST_0_180 = cst_0_180
    CST_0_90 = cst_0_90
    CST_30_130 = cst_30_130
    CST_180_549 = cst_180_549
  }else{
    CST_90_180 = rbindlist( list(CST_90_180,cst_90_180))
    CST_0_180 = rbindlist( list(CST_0_180,cst_0_180))
    CST_0_90 = rbindlist( list(CST_0_90,cst_0_90))
    CST_30_130 = rbindlist( list(CST_30_130,cst_30_130))
    CST_180_549 = rbindlist( list(CST_180_549,cst_180_549))
  } # end if
} # end i loop

cst_monthly = left_join(CST_90_180,CST_0_180)
cst_monthly = left_join(cst_monthly,CST_0_90)
cst_monthly = left_join(cst_monthly,CST_30_130)
cst_monthly = left_join(cst_monthly,CST_180_549)


# cst_monthly_late <- cst_monthly
# clean up to save memory
fwrite(cst_monthly, "Data/GLORYS_Processing/glorys-monthly-means-cst-2021.csv") 
rm(cst_monthly)

# MONTHLY LONGSHORE TRANSPORT ##################################################

# need to go through this and sea surface height

x<-"Data/GLORYS_Processing/glorys-monthly-longshore-northward-2021-07-01-2025-03-01-1200m.nc"
  
for(i in 1:length(x)){ 
  print(x[i])
  (t1 = Sys.time())
  dfx <- tidync::tidync(paste0(x[i])) %>% 
    hyper_tibble( force = TRUE) %>%
    drop_na() %>% 
    group_by(longitude,latitude,time)
  
  dt_lst = data_prep(data.file=dfx, bathy_file = dt_bathy)
  rm(dfx)# clean up memory for space
    # as in temporary not temperature
    
    # calculations for depth x lat zones = mean daily value
    # subset and average by date later
    
    lst_90_180 = dt_lst[bottom_depth >= 90 & bottom_depth <=180 , .(lst_90_180 = mean(vo)), by='date']
    lst_0_180 = dt_lst[bottom_depth >= 0 & bottom_depth <=180 , .(lst_0_180 = mean(vo)), by='date']
    lst_0_90 = dt_lst[bottom_depth >= 0 & bottom_depth <=90 , .(lst_0_90 = mean(vo)), by='date']
    lst_30_130 = dt_lst[bottom_depth >= 30 & bottom_depth <=130 , .(lst_30_130 = mean(vo)), by='date']
    lst_180_549 = dt_lst[bottom_depth >= 180 & bottom_depth <=549 , .(lst_180_549 = mean(vo)), by='date']
    
    rm(dt_lst)
    
    if(i==1){
      LST_90_180 = lst_90_180
      LST_0_180 = lst_0_180
      LST_0_90 = lst_0_90
      LST_30_130 = lst_30_130
      LST_180_549 = lst_180_549
    }else{
      LST_90_180 = rbindlist( list(LST_90_180,lst_90_180))
      LST_0_180 = rbindlist( list(LST_0_180,lst_0_180))
      LST_0_90 = rbindlist( list(LST_0_90,lst_0_90))
      LST_30_130 = rbindlist( list(LST_30_130,lst_30_130))
      LST_180_549 = rbindlist( list(LST_180_549,lst_180_549))
    } # end if
  } # end i loop



lst_monthly = left_join(LST_90_180,LST_0_180)
lst_monthly = left_join(lst_monthly,LST_0_90)
lst_monthly = left_join(lst_monthly,LST_30_130)
lst_monthly = left_join(lst_monthly,LST_180_549)

# clean up to save memory
fwrite(lst_monthly, "Data/GLORYS_Processing/glorys-monthly-means-lst-2025.csv") 
rm(lst_monthly)


# MONTHLY TEMP ##################################################

# need to go through this and sea surface height

x<-"Data/GLORYS_Processing/glorys-monthly-thetao-1993-01-01-2021-06-30-1200m.nc"

for(i in 1:length(x)){ 
  print(x[i])
  (t1 = Sys.time())
  dfx <- tidync::tidync(paste0(x[i])) %>% 
    hyper_tibble( force = TRUE) %>%
    drop_na() %>% 
    group_by(longitude,latitude,time)
  
  dt_temp = data_prep(data.file=dfx, bathy_file = dt_bathy)
  rm(dfx)# clean up memory for space
  # as in temporary not temperature
  
  # calculations for depth x lat zones = mean daily value
  # subset and average by date later
  
  temp_90_180 = dt_temp[bottom_depth >= 90 & bottom_depth <=180 , .(temp_90_180 = mean(thetao)), by='date']
  temp_0_180 = dt_temp[bottom_depth >= 0 & bottom_depth <=180 , .(temp_0_180 = mean(thetao)), by='date']
  temp_0_90 = dt_temp[bottom_depth >= 0 & bottom_depth <=90 , .(temp_0_90 = mean(thetao)), by='date']
  temp_30_130 = dt_temp[bottom_depth >= 30 & bottom_depth <=130 , .(temp_30_130 = mean(thetao)), by='date']
  temp_180_549 = dt_temp[bottom_depth >= 180 & bottom_depth <=549 , .(temp_180_549 = mean(thetao)), by='date']
  
  rm(dt_temp)
  
  if(i==1){
    temp_90_180 = temp_90_180
    temp_0_180 = temp_0_180
    temp_0_90 = temp_0_90
    temp_30_130 = temp_30_130
    temp_180_549 = temp_180_549
  }else{
    temp_90_180 = rbindlist( list(temp_90_180,temp_90_180))
    temp_0_180 = rbindlist( list(temp_0_180,temp_0_180))
    temp_0_90 = rbindlist( list(temp_0_90,temp_0_90))
    temp_30_130 = rbindlist( list(temp_30_130,temp_30_130))
    temp_180_549 = rbindlist( list(temp_180_549,temp_180_549))
  } # end if
} # end i loop



temp_monthly = left_join(temp_90_180,temp_0_180)
temp_monthly = left_join(temp_monthly,temp_0_90)
temp_monthly = left_join(temp_monthly,temp_30_130)
temp_monthly = left_join(temp_monthly,temp_180_549)

# clean up to save memory
fwrite(temp_monthly, "Data/GLORYS_Processing/glorys-monthly-means-temp-2025.csv") 
rm(temp_monthly)
