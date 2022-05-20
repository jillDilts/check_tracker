################################################################################
# utils.R 
#
# utilities file for checklist tracking report
################################################################################

# libraries
library(tidyverse)
library(googlesheets4)
library(here)

# unique identifier of google sheet for leave 
# presently links to a demo sheet at https://docs.google.com/spreadsheets/d/19SZX7pVKGdJYYp7tXgQvZcywm4EOeDCTCbBKVs8rTMI/edit#gid=0
checklist_ss <- "19SZX7pVKGdJYYp7tXgQvZcywm4EOeDCTCbBKVs8rTMI"

# actual time zone where you are - google pretends it's all entered in UTC 
#TODO: replace with your timezone's name
actual_tz = "America/Toronto"

#-------------------------------------------------------------------------------
# constants

live_path =  here( paste0("data/live/") )

# tab names in google sheet
checklist_sheets <- c(
  "checks",
  "tasks"
) 

# set a value for "tiny" so that we can do calculations where 0/0 = 1 (lolololololol)
epsilon <- 0.0001

#----------------- colour palette -------------
# name the colours that we will add to the palette 
care_purple <- 	"#BE29EC"

# for scales::muted() colours to indicate gradual passage of time
# when implemented, I did not understand how scales::muted() worked
old_luminance <- 95
old_chroma <- 15

#------ set theme ------
# base theme
theme_set(
  new = theme_minimal()
)

# adjustments for this report
theme_update(
  legend.position = "none"
  )

# Add colours to palette
wellbeing_palette <- c(
  "z_checks" = care_purple
  ,"checks" = care_purple
  # muffled versions of shades for gradient aesthetics
  ,"old_checks" = scales::muted( care_purple, l = old_luminance, c = old_chroma ) 
)

#-------------------------------------------------------------------------------

################################################################################
# function map_update
#
# read one google sheet and write it to file
# helper function to be passed to map() in refresh_data()
#
# arguments:
# sheet: tab name of sheet to download and write
# ss: identifier passed to googlesheets4:read_sheet()
# 
################################################################################
map_update <- function(
    sheet,
    ss
) {
  # print(paste0("sheet ", sheet) ) # debug
  
  # add sheet name to pull_date column name 
  pull_date_name <- paste0( "pull_date.", sheet )
  
  # read sheet from web into tibble
  read_sheet(
    ss = ss,
    sheet = sheet
  ) %>%
    # add timestamp column to mark pull time
    mutate(
      !! pull_date_name := now()
      # "pull.date_{{sheet}}" := now()
    ) %>%
    # save tibble to file 
    saveRDS(
      file = paste0(live_path, "/", sheet, ".rds")
    )
  
}

################################################################################
# function refresh_data
#
# read a set of google sheets and write them to eponymous files in /data/live
#
# arguments:
# ss: sheet identifier passed to googlesheets4:read_sheet()
# sheets: tab names of sheets to download and write
# 
################################################################################
refresh_data <- function(
    ss = checklist_ss,
    sheets = checklist_sheets
) {
  map(
    .x = sheets,
    .f = map_update,
    ss = ss
  )
  
}

################################################################################
# function read_data
#
# read files from /data/live into .GlobalEnv
#
# arguments:
# sheets: tab names of .rds files to read into the global environment
# 
################################################################################
read_data <- function(
    sheets = checklist_sheets
) {
  catch_output <- # catch values that we don't need because we already added them to .GlobalEnv
    map(
      .x = sheets,
      .f = function( sheet ) {
        assign(
          x = paste0("raw_", sheet),
          value = readRDS(
            here( paste0(live_path, "/", sheet, ".rds") )
          ),
          envir = .GlobalEnv
        )
      }
    )
}
