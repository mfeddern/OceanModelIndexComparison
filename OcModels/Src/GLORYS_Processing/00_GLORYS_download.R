# download glorys data #########################################################

# Need to have Python and Miniforge installed ####
# Prelim stuff in Minoforge ####

# (1) open up Miniforge Promt
# (2) activate copernicus marine environment: mamba activate copernicusmarine
# (3) copernicusmarine login ### note automatic at present
# (4) type "R" to launch R
# NOTE = currently downloads in large chunks of time, 
# but might work better as individual years for later data handling


# to install python stuff...run from miniforge:

# mamba create --name copernicusmarine conda-forge::copernicusmarine --yes
# mamba activate copernicusmarine
# copernicusmarine describe --overwrite-metadata-cache > catalog.json

# update from Minforge

# mamba update --name copernicusmarine copernicusmarine --yes

# add libraries ################################################################
library(lubridate)
library(tidync)
library(tidyverse)
library(data.table)
library(CopernicusMarine)


# Copernicus exe path ##########################################################

path_copernicusmarine =  "/Users/megan.feddern/miniforge3/envs/copernicusmarine/bin/copernicusmarine"
out_dir<-"Data/GLORYS_Processing/"
# SET LAT-LON, DEPTH & DATES #########################################################

lon = list(-130, -116)  # lon_min, lon_max
lat = list(31,48) # lat_min, lat_max

depth = list(0.49, 1200)

# 2023 runs
# reanalysis: 1993-01-01 to 2020-10-31
# interim data: 2020-11-01 to 2023-06-01

# 2025 runs 
# re-download of smaller files
# update for larger files based on reanalysis start

# reanalysis: 2021-11-01 - 2021-06-30
# interim data: 2021-07-01 - 2025-02-01

reanalysis_start_date = 20200101 # for daily btemp
# may need to delete some partial year file
reanalysis_end_date = 20210630

interim_start_date = 20210701
interim_end_date = 20250301

last_date_range = data.frame(date_dype = c('reanalysis_start_date_1',
                                           'reanalysis_start_date_2',
                                           'reanalysis_end_date',
                                           'interim_start_date',
                                           'interim_end_date'),
                             date = c(19930101,
                                      reanalysis_start_date,
                                      reanalysis_end_date,
                                      interim_start_date,
                                      interim_end_date)
)
# output last date range for posterity
write.csv( last_date_range, paste0('Data/GLORYS_Processing/last-date-range-', Sys.Date(),".csv"), row.names = FALSE )

################################################################################
# STATIC PARAMETERS ############################################################
################################################################################

# bathymetry ###################################################################

dataset_id = 'cmems_mod_glo_phy_my_0.083deg_static'

variable <- c(" --variable deptho")
filename = paste0("glorys-bathymetry.nc")

# download command 

command <- paste (path_copernicusmarine, " subset -i", dataset_id,                    
                  "-x", lon[1], "-X", lon[2],                  
                  "-y", lat[1], "-Y", lat[2],
                  # "-t", date_min, "-T", date_max,
                  # "-z", depth[1], "-Z", depth[2],                    
                  " --variable deptho", "-o", out_dir, "-f", filename, 
                  sep = " ")
system(command, intern = TRUE)


# cell dimensions ##############################################################

dataset_id = 'cmems_mod_glo_phy_my_0.083deg_static'

variable <- c(" --variable e1t --variable e2t --variable e3t")
filename = paste0("glorys-cell-dimensions-meters.nc")

# download command 

command <- paste (path_copernicusmarine, " subset -i", dataset_id,  
                  "--dataset-part coords",
                  "-x", lon[1], "-X", lon[2],                  
                  "-y", lat[1], "-Y", lat[2],
                  # "-t", date_min, "-T", date_max,
                  # "-z", depth[1], "-Z", depth[2],                    
                  " --variable e1t --variable e2t --variable e3t", "-o", 
                  out_dir, "-f", filename, 
                  sep = " ")
system(command, intern = TRUE)


################################################################################
# MONTHLY TIME SERIES DOWNLOADS FOR TRANSPORT ##################################
################################################################################

# Reanalysis ###################################################################
# reanalysis_start_date = 19930101
# reanalysis_end_date_monthly = 20230601

date_range = data.frame(matrix(data=c(
  19930101, reanalysis_end_date, "cmems_mod_glo_phy_my_0.083deg_P1M-m",
  interim_start_date, interim_end_date, "cmems_mod_glo_phy_myint_0.083deg_P1M-m"
), nrow=2, ncol=3, byrow=T))
date_range
colnames(date_range) = c('date_min', 'date_max', 'dataset')


for(i in 1:2){
  date_min = ymd(date_range[i,'date_min'])
  date_max = ymd(date_range[i,'date_max'])
  dataset_id = date_range[i,"dataset"]
  
  # mld ####
  
  filename = paste0("glorys-monthly-MLD-",date_min,"-",date_max,"-",depth[2],"m.nc")
  filename
  command <- paste (path_copernicusmarine, " subset -i", dataset_id,                    
                    "-x", lon[1], "-X", lon[2],                  
                    "-y", lat[1], "-Y", lat[2],
                    "-t", date_min, "-T", date_max,
                    # "-z", depth[1], "-Z", depth[2],                    
                    " --variable mlotst", "-o", out_dir, "-f", filename, 
                    "--force-download", sep = " ")
  system(command, intern = TRUE)
  
  
  # cross shelf ####
  filename = paste0("glorys-monthly-crossshelf-eastward-",date_min,"-",date_max,"-",depth[2],"m.nc")
  filename
  command <- paste (path_copernicusmarine, " subset -i", dataset_id,                    
                    "-x", lon[1], "-X", lon[2],                  
                    "-y", lat[1], "-Y", lat[2],
                    "-t", date_min, "-T", date_max,
                    "-z", depth[1], "-Z", depth[2],                    
                    " --variable uo", "-o", out_dir, "-f", filename, 
                    "--force-download", sep = " ")
  system(command, intern = TRUE)
  
  # longshore ####
  filename = paste0("glorys-monthly-longshore-northward-",date_min,"-",date_max,"-",depth[2],"m.nc")
  filename
  # download command 
  
  command <- paste (path_copernicusmarine, " subset -i", dataset_id,                    
                    "-x", lon[1], "-X", lon[2],                  
                    "-y", lat[1], "-Y", lat[2],
                    "-t", date_min, "-T", date_max,
                    # "-z", depth[1], "-Z", depth[2],                    
                    " --variable vo", "-o", out_dir, "-f", filename, 
                    "--force-download", sep = " ")
  system(command, intern = TRUE)
  
  ## monthly temp 
  filename = paste0("glorys-monthly-thetao-",date_min,"-",date_max,"-",depth[2],"m.nc")
  filename
  # download command 
  
  command <- paste (path_copernicusmarine, " subset -i", dataset_id,                    
                    "-x", lon[1], "-X", lon[2],                  
                    "-y", lat[1], "-Y", lat[2],
                    "-t", date_min, "-T", date_max,
                    # "-z", depth[1], "-Z", depth[2],                    
                    " --variable thetao", "-o", out_dir, "-f", filename, 
                    "--force-download", sep = " ")
  system(command, intern = TRUE)
}





# quick look at output files ###################################################
x = dir(out_dir)
x
z = x[36] 
z

df <- tidync::tidync(paste0(out_dir,z)) %>% 
  hyper_tibble( force = TRUE) %>%
  drop_na() %>% 
  # group_by(longitude,latitude) 
  group_by(longitude,latitude,time, depth) 
dtx = data.table(df)
head(dtx)

# time is hours since 1950-01-01

dtx[,date:=lubridate::as_date(dtx$time/24,origin="1950-01-01 00:00:00"),]
head(dtx)
tail(dtx)