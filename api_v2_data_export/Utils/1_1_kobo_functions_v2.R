library(httr)
library(jsonlite)
library(dplyr)
library(purrr)
library(tidyr)
library(tibble)
library(stringr)
library(readxl)



# ---testing only ----
# rm(list = ls())
# 
# Domain <- "impact"
# 
# 
# if (str_detect(getwd(), "/EdwinGIBB/")) {
#   source("C:/Users/EdwinGIBB/OneDrive - ACTED/Credentials/credentials_EG.R")
# } else if (str_detect(getwd(), "/DELL/")) {
#   source("C:/Users/DELL/OneDrive - ACTED/Documents/DONOTSHARE/Crediential_Oriana.R")
# } 
# 
# asset_uid <- "aHffC3VA9diqugBeeyQnTJ"
# end testing only ----





# -------- Config ---------

# Define export settings for the downloaded file
export_body <- list(
  fields_from_all_versions = TRUE,
  group_sep = "/",
  hierarchy_in_labels = FALSE,
  lang = "_xml",
  multiple_select = "both",
  type = "xls",
  xls_types_as_text = FALSE,
  include_media_url = TRUE
)


# ------- Function 1: Generate export --------

create_export <- function(url, headers, body){
  # Get export (this asks KOBO for the xls export URL)
  export_response <- POST(
    url = url,
    headers,
    body = body,
    encode = "json",
    progress()
  )
  
  # Stop if Kobo returned an error
  stop_for_status(export_response)
  
  # Get content converts Kobo’s response into an R
  export_created <- content(
    export_response,
    as = "parsed",
    simplifyVector = TRUE
  )
}


# ------- Function 2: Get export information --------

get_export_info <- function(url, headers, max_attempts = 15, poll_interval = 8) {
  attempt <- 1
  
  repeat {
    
    # sleep first to give export time to process
    Sys.sleep(poll_interval)
    
    # Attempt to get export info
    export_info_response <- tryCatch({
      GET(url, headers
          # progress()
          )
    }, error = function(e) {
      NULL
    })
    
    # If request failed, retry
    if (is.null(export_info_response)) {
      if (attempt >= max_attempts) {
        stop("Failed to get export info after maximum attempts.")
      }
      
      attempt <- attempt + 1
      Sys.sleep(poll_interval)
      next
    }
    
    stop_for_status(export_info_response)
    
    # Parse response
    export_info <- content(
      export_info_response,
      as = "parsed",
      simplifyVector = TRUE
    )
    
    # Check if export is ready 
    if (!is.null(export_info$result) && export_info$status == "complete") {
      message("Attempt ", attempt, " export status: complete")
      return(export_info)
    }
    
    if (!is.null(export_info$result) && export_info$status == "complete") {
    }
    
    # If not ready, check if we've exceeded max attempts
    if (attempt >= max_attempts) {
      stop("Export did not complete within the maximum number of attempts.")
    }
    
    message("Attempt ", attempt, " export status: ",
            if (!is.null(export_info$status)) export_info$status else "processing")
    
    attempt <- attempt + 1
  }
}



# ------- Function 3: Download export --------

download_export <- function(download_url, headers, temp_file_ext = ".xlsx") {
  temp_file <- tempfile(fileext = temp_file_ext)
  
  # Download the file
  response <- GET(
    url = download_url,
    headers,
    write_disk(temp_file, overwrite = TRUE),
    progress()
  )
  
  stop_for_status(response)
  
  # Validate the downloaded file
  sheet_names <- excel_sheets(temp_file)
  
  if (length(sheet_names) == 0) {
    stop("Downloaded file does not contain valid sheets.")
  }
  
  message("Download successful.")
  
  return(
    list(
      temp_file = temp_file,
      sheet_names = sheet_names,
      response = response
    )
  )
}
