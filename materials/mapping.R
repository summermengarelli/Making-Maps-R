library(tidyverse)
library(sf)
library(tmap)
library(tigris)

# Attribute data ------------------------------------------------
urban.rural <- read.csv("DHC2020-P2.csv")
head(urban.rural)

urban.rural <- read.csv("DHC2020-P2.csv", skip = 1)

# Spatial data ------------------------------------------------
IN.sf <- block_groups(state = "IN", year = 2020)
head(IN.sf)

# Joining attribute and spatial data ------------------------------------------------
urban.rural$GEOID <- substring(urban.rural$GEOID, 10, 21)

class(IN.sf$GEOID)
class(urban.rural$GEOID)

IN.rurb <- left_join(
  IN.sf,
  urban.rural,
  by = c("GEOID" = "GEOID")
)

# Creating urban-rural index ------------------------------------------------
IN.rurb$index <- round(((IN.rurb$Total.Urban - IN.rurb$Total.Rural) / IN.rurb$Total.Pop), 2)


tmap_mode("plot")
tm_shape(IN.rurb) +
  tm_polygons(
    fill = "index",
    fill.scale = tm_scale_intervals(
      n = 4,
      style = "fixed",
      breaks = c(-1, -0.5, 0, 0.5, 1),
      values = "scico.roma" 
    ),
  )

# On the options for the intervals: https://tmap.geocompx.org/scales#sec-intervals-scales 
# documentation on the colorway: https://github.com/thomasp85/scico 
# or try the code below:
cols4all::c4a_palettes()

tmap_mode("view")
m <- tm_shape(IN.rurb) +
  tm_polygons(
    fill = "index",
    fill.scale = tm_scale_intervals(
      n = 4,
      style = "fixed",
      breaks = c(-1, -0.5, 0, 0.5, 1),
      values = "scico.roma" 
    ),
    popup = tm_popup(
      vars = c(
        "Census Block Group" = "Geographic.Area.Name",
        "Total Population" = "Total.Pop",
        "Total Urban Population" = "Total.Urban",
        "Total Rural Population" = "Total.Rural"
      )
    )
  )

tmap_save(m, "indiana.html")


sjc <- st_read("./county-commissioner/County_Commissioner_2022.shp")
tmap_mode("plot")
tm_shape(sjc) +
  tm_polygons()

sjc <- st_union(sjc)
tm_shape(sjc) +
  tm_polygons()

st_crs(sjc)
st_crs(IN.rurb)


IN.rurb <- st_transform(
  IN.rurb,
  st_crs(sjc)
)

st_crs(IN.rurb)

sjc.rurb <- st_intersection(
  IN.rurb,
  sjc
)

tmap_mode("view")
tm_shape(sjc.rurb) +
  tm_polygons(
    fill = "index",
    fill.scale = tm_scale_intervals(
      n = 4,
      style = "fixed",
      breaks = c(-1, -0.5, 0, 0.5, 1),
      values = "scico.roma" 
    ),
    popup = tm_popup(
      vars = c(
        "Census Block Group" = "Geographic.Area.Name",
        "Total Population" = "Total.Pop",
        "Total Urban Population" = "Total.Urban",
        "Total Rural Population" = "Total.Rural"
      )
    )
  )
