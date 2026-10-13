# -------------------------------------------------------------
#
# An R script for the "Making Maps in R" workshop.
#
# Authors:
#   (1) Summer Mengarelli, smengare@nd.edu
#   (2) [your info here]
#
# Dates:
#   Created: 2026-10-04
#   Last modified: 2026-10-13
#
# Notes:
#
# -------------------------------------------------------------

# Libraries -----------------------------
library(tidyverse)
library(sf)
library(tmap)
library(tigris)

# Attribute data -----------------------------
urban.rural <- read.csv("DHC2020-P2.csv")
head(urban.rural)

urban.rural <- read.csv("DHC2020-P2.csv", skip = 1) ## skipping the extra header row!

# Spatial data -----------------------------
IN.sf <- block_groups(state = "IN", year = 2020) ## using the tigris package to get Indiana census block group polygons
head(IN.sf)
urban.rural$GEOID <- substring(urban.rural$GEOID, 10, 21) ## Why are we doing this?

# Attribute and spatial data join -----------------------------
class(IN.sf$GEOID)
class(urban.rural$GEOID) ## checking that both dataframes have GEOIDs of the same data type (char)

IN.rurb <- left_join(
  IN.sf,
  urban.rural,
  by = c("GEOID" = "GEOID")
)

# Urban-rural index -----------------------------
IN.rurb$index <- round(((IN.rurb$Total.Urban - IN.rurb$Total.Rural) / IN.rurb$Total.Pop), 2)
## In this line, we make a column "index" which will range -1 to 1, where values closer to -1 are more rural, 
##    and values closer to 1 are more urban.

# Static map using tmap -----------------------------
tmap_mode("plot") ## specifying a static map

tm_shape(IN.rurb) +
  tm_polygons(
    fill = "index", ## polygons will be colored according to the index column
    fill.scale = tm_scale_intervals( 
      style = "fixed", ## we're setting a manual scale for how the colors will be assigned
      n = 4, ## ... we want 4 different shades...
      breaks = c(-1, -0.5, 0, 0.5, 1), ## ... with values chunked every 0.5...
      values = "scico.roma" # ... and using the "Roma" color palette from the scico package
    ),
  )

# On the options for the intervals: https://tmap.geocompx.org/scales#sec-intervals-scales 
# Documentation on the colorway: https://github.com/thomasp85/scico 
# or try the code below:
cols4all::c4a_palettes()

# Interactive map using tmap -----------------------------
tmap_mode("view") ## specifying an interactive map

tm_shape(IN.rurb) +
  tm_polygons(
    fill = "index",
    fill.scale = tm_scale_intervals(
      n = 4,
      style = "fixed",
      breaks = c(-1, -0.5, 0, 0.5, 1),
      values = "scico.roma" 
    ),
    popup = tm_popup( ## everything here is specifying what data we want to pop up when users hover over the map
      vars = c(
        "Census Block Group" = "Geographic.Area.Name", ## right of the = is the variable name, left is how we want it displayed
        "Total Population" = "Total.Pop",
        "Total Urban Population" = "Total.Urban",
        "Total Rural Population" = "Total.Rural"
      )
    )
  )

## we can also save the map...
m <- tm_shape(IN.rurb) +
  tm_polygons(
    fill = "index",
    fill.scale = tm_scale_intervals(
      n = 4,
      style = "fixed",
      breaks = c(-1, -0.5, 0, 0.5, 1),
      values = "scico.roma" 
    ),
    popup = tm_popup( ## everything here is specifying what data we want to pop up when users hover over the map
      vars = c(
        "Census Block Group" = "Geographic.Area.Name", ## right of the = is the variable name, left is how we want it displayed
        "Total Population" = "Total.Pop",
        "Total Urban Population" = "Total.Urban",
        "Total Rural Population" = "Total.Rural"
      )
    )
  )

tmap_save(m, "indiana.html") ## saving the interactive map as an HTML file

# St. Joseph County polygons -----------------------------
sjc <- st_read("./county-commissioner/County_Commissioner_2022.shp") ## loading in St. Joe county commissioner boundaries
tmap_mode("plot") ## making a static map to quickly see the data
tm_shape(sjc) +
  tm_polygons()

sjc <- st_union(sjc) ## here we're joining all polygons together and dissolving inner borders...
tm_shape(sjc) + ## ... to make one polygon that is the county border
  tm_polygons()

# Coordinate Reference Systems -----------------------------
st_crs(sjc) ## checking the CRS of each spatial dataset; if they don't match, we need to fix this
st_crs(IN.rurb)


IN.rurb <- st_transform( ## transforming the IN.rurb sf object to match the CRS of the St. Joe county polygon
  IN.rurb,
  st_crs(sjc)
)

st_crs(IN.rurb) ## reconfirming the CRS match

# Clipping -----------------------------
sjc.rurb <- st_intersection(
  IN.rurb,
  sjc
)

# Final interactive map: St. Joseph County census block groups -----------------------------
tmap_mode("view")

tm_shape(sjc.rurb) +
  tm_polygons(
    fill = "index",
    fill.scale = tm_scale_intervals(
      n = 4,
      style = "fixed",
      breaks = c(-1, -0.5, 0, 0.5, 1),
      values = "scico.roma",
      labels = c(
        "Rural",
        "More rural than urban",
        "More urban than rural",
        "Urban"
      )
    ),
    fill.legend = tm_legend(title = "Urban/Rural Index"),
    popup = tm_popup(
      vars = c(
        "Census Block Group" = "Geographic.Area.Name",
        "Total Population" = "Total.Pop",
        "Total Urban Population" = "Total.Urban",
        "Total Rural Population" = "Total.Rural"
      )
    )
  ) +
  tm_title("Urban/Rural Index in St. Joseph County, Indiana")
