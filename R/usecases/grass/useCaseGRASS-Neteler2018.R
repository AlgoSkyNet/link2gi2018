#' Adapting parts of the tutorial
#' https://neteler.gitlab.io/grass-gis-analysis/02_grass-gis_ecad_analysis/
#' of Marcus Neteler and Veronica Andreo
#' 
#' This usecase is just giving you an idea how quick and dirty you may 
#' integrate GRASS shell commandline code to a R script
#' Most of the comments and command lines are just copy and paste
#' from Markus Netelers tutorial script 
#' 
#' I just tried to "streamline" the code and dropped 
#' out unix specific stuff like calling displays


cat("setting arguments loading libs and data\n")
require(link2GI)
require(raster)
require(rgrass7)

### define arguments


# define root folder
if (Sys.info()["sysname"] == "Windows"){
  projRootDir<-"C:/Users/User/Documents/link2gi2018-master/grassreload"
} else {
  projRootDir<-"~/link2gi2018-master/grassreload"
}



##--link2GI-- create project folder structure, NOTE the tailing slash is obligate
link2GI::initProj(projRootDir = projRootDir, 
                  projFolders =  c("run/","src/","grassdata/","geodata/","grassdata/user1/"),
                  global = TRUE,
                  path_prefix ="path_gr_" )

## download the tutorial data set 
download <- curl::curl_download("https://www.naturalearthdata.com/http//www.naturalearthdata.com/download/10m/cultural/ne_10m_admin_0_countries.zip",
                                paste0(path_gr_run,"ne_10m_admin_0_countries.zip"))
utils::unzip(zipfile = download, exdir = path_gr_geodata)

### 
##--link2GI-- linking GRASS project structure using the information from the DEM raster
link2GI::linkGRASS7(gisdbase = path_gr_grassdata,
                    location = "ecad17_ll",
                    gisdbase_exist = TRUE) 

#-- create mapset user1 ecad17
system("g.mapset -c  mapset=user1")


# Add the mapset "ecad17" and "user1" to the search path
## please note the difference between mapset and mapsets
system("g.mapsets  mapset=user1 operation=add")
system("g.mapsets  mapset=ecad17 operation=add")
system("g.list type=rast")

# import and check/fix topology
system(paste0("v.import --overwrite input=",
              paste0(path_gr_geodata,"ne_10m_admin_0_countries.shp"),
              " output=country_boundaries"))

# add some metadata
system('v.support country_boundaries comment="Source: http://www.naturalearthdata.com/downloads/110m-cultural-vectors/"')
system('v.support country_boundaries map_name="Admin0 boundaries from NaturalEarthData.com"')

# show attibute table colums
system("v.info -c country_boundaries")

##--rgrass7-- import DEM to GRASS
rgrass7::execGRASS('r.in.gdal',
                   flags=c('o',"overwrite","quiet"),
                   input=path.expand(paste0(path_gr_geodata,"ecad_v17/elev_v17.tif")), 
                   output='elev_v17',
                   band=1
)
# color it (works even if you are not looking at it)
system("r.colors map=elev_v17 color=elevation")



### finish with the basic execise

### start the anaysis

##--rgrass7-- Set the computational region to the full raster map (bbox and spatial resolution)  
# resulting in the same using a system call system("g.region raster=precip.1951_1980.01.sum@ecad17")
rgrass7::execGRASS(cmd = "g.region", raster="precip.1951_1980.01.sum")

# Now use the r.series command to create annual precip map for the period 1951 to 1980
system('r.series --overwrite input=`g.list rast pattern="precip.1981_2010.*.sum" sep="comma"` output=precip.1981_2010.annual.sum method=sum
')
# Aggregate the temperature maps average annual temperature
system('r.series --overwrite input=`g.list rast pattern="tmean.1981_2010.*.avg" sep="comma"` output=tmean.1981_2010.annual.avg method=average
')
# read results to R
a_p_sum_1981_2010<-raster::raster(rgrass7::readRAST("precip.1981_2010.annual.sum"))
a_t_mean_1981_2010<-raster::raster(rgrass7::readRAST("tmean.1981_2010.annual.avg"))

# use mapview for visualisation
mapview::mapview(a_p_sum_1981_2010) + a_t_mean_1981_2010

# Compute extended univariate statistics
stat<-system2(command = "r.univar", args = 'tmean.1981_2010.annual.avg -e -g',stdout = TRUE,stderr = TRUE)




### lets do some timeseries


########################################################################
# Commands for the TGRASS lecture at GEOSTAT Summer School in Prague
# Author: Veronica Andreo
# Date: July - August, 2018
########################################################################


########### Before the workshop (done for you in advance) ##############

# Install i.modis add-on (requires pymodis library - www.pymodis.org)
system("g.extension extension=i.modis")

############## For the workshop (what you have to do) ##################

## Download the ready to use mapset 'modis_lst' from:
## https://gitlab.com/veroandreo/grass-gis-geostat-2018
## and unzip it into North Carolina full LOCATION 'nc_spm_08_grass7'
link2GI::linkGRASS7(gisdbase = path_gr_grassdata,
                    location = "nc_spm_08_grass7",
                    gisdbase_exist = TRUE) 

system("g.mapsets  mapset=modis_lst operation=add")
# Get list of raster maps in the 'modis_lst' mapset
system("g.mapsets  -p")
system("g.mapset  mapset=modis_lst")
# Get info from one of the raster maps
system('r.info map=MOD11B3.A2015060.h11v05.single_LST_Day_6km')


## Region settings and MASK

# Set region to NC state with LST maps' resolution
system("g.region -p vector=nc_state align=MOD11B3.A2015060.h11v05.single_LST_Day_6km")

# Set a MASK to nc_state boundary
system("r.mask --overwrite vector=nc_state")

# you should see this statement in the terminal from now on
#~ [Raster MASK present]


## Time series

# Create the STRDS

system('t.create --overwrite type=strds temporaltype=absolute output=LST_Day_monthly@modis_lst title="Monthly LST Day 5.6 km" description="Monthly LST Day 5.6 km MOD11B3.006, 2015-2017"')

# Check if the STRDS is created
system("t.list type=strds")

# Get info about the STRDS
system("t.info input=LST_Day_monthly")


## Add time stamps to maps (i.e., register maps)

# in Unix systems
system('t.register -i input=LST_Day_monthly maps=`g.list type=raster pattern="MOD11B3*LST_Day*" separator=comma` start="2015-01-01" increment="1 months"')


# Check info again
system('t.info input=LST_Day_monthly')


# Check min and max per map
system('t.rast.list input=LST_Day_monthly columns=name,min,max')


## Let's see a graphical representation of our STRDS
system('g.gui.timeline inputs=LST_Day_monthly')


## Temporal calculations: K*50 to Celsius 

# Re-scale data to degrees Celsius
# https://www.mail-archive.com/grass-user@lists.osgeo.org/msg35180.html
## Apparently the data got zstd compressed in 7.5.svn which isn't supported in
## 7.4.x. You need to switch the compression in 7.5 with r.compress.
system('t.rast.algebra --overwrite basename=LST_Day_monthly_celsius expression="LST_Day_monthly_celsius = LST_Day_monthly * 0.02 - 273.15"')

# Check info
system('t.info LST_Day_monthly_celsius')

