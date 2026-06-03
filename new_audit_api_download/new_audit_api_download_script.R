rm(list = ls())


library(httr)
library(jsonlite)
library(stringr)
library(tidyverse)


testing <- TRUE


## import server credentials 
Domain <- "impact"
if (str_detect(getwd(), "/EdwinGIBB/")) {
  source("C:/Users/EdwinGIBB/OneDrive - ACTED/Credentials/credentials_EG.R")
} else if (str_detect(getwd(), "/eaindray.pyae/")) {
  source("C:/Users/eaindray.pyae/OneDrive - ACTED/Documents/DONOTSHARE/Crediential_Oriana.R")
} else if (str_detect(getwd(), "/kyawhein/")) {
  source("C:/Users/kyawhein/OneDrive - ACTED/Credential_data/credential_kh.R")
} else {
  source("C:/Users/DELL/OneDrive - ACTED/Credentials/credentials_HK.R")
}



# CHANGE FOR PROJECT
form_uid <- "a86Ne93SgPR3YJqafWiTqX"



# set base url
base_url <- paste0(url, "/", form_uid, "/data/")


# dataframe of _ids linked to _uuids 

if (testing <- FALSE){
  audit_ids <- new_submissions |>
  select(sub_id = "_id", sub_uuid = "_uuid")
} else if (testing <- TRUE){
  test_ids <- c("2834951", "2835259",
                "2835260",
                "2835261",
                "2835262",
                "2835263"
  )
  test_uuids <- c("ff33e55a-0600-4619-88ad-0df16d4c6040", 
                  "a8b37b07-62fd-44ce-b47e-f3edebff8590", 
                  "b42a4069-2da7-46aa-873e-d701b1df98ef",
                  "76130da1-568c-4f41-a531-708dc5df1ff2",
                  "b82a4a37-516a-432e-b5a7-16019d4a4927",
                  "6d6b69f4-ff80-4a3c-a46e-5480dad6a7a1"
  )
  
  audit_ids <- data.frame(sub_id = test_ids, sub_uuid = test_uuids)
}



# ---- Download audit files ----

audits_list <- list()  # initiate empty list to store files

for(sub_id in audit_ids$sub_id) {

  sub_url <- paste0(base_url, sub_id, "/")
  res_sub <- GET(sub_url, add_headers(Authorization = paste("Token", kobo_api_key)))
  sub_data <- content(res_sub, as = "text", encoding = "UTF-8") %>% fromJSON(flatten = TRUE)
  
  attachments <- sub_data$`_attachments`
  
  sub_uuid <- audit_ids$sub_uuid[audit_ids$sub_id == sub_id]
  
  # attachments is a data frame; filter for audit.csv
  audit_url <- NULL
  if(nrow(attachments) > 0) {
    audit_row <- attachments[attachments$media_file_basename == "audit.csv", ]
    if(nrow(audit_row) > 0) {
      audit_url <- audit_row$download_url
    }
  }
  
  if(!is.null(audit_url)) {
    # GET the CSV and read into a data frame directly
    csv_res <- GET(audit_url, add_headers(Authorization = paste("Token", kobo_api_key)))
    audit_df <- read.csv(text = content(csv_res, as = "text", encoding = "UTF-8"),
                         stringsAsFactors = FALSE)
    
    # put audit file dataframe into list
    audits_list[[as.character(sub_uuid)]] <- audit_df
  }
}


# convert from list to dataframe  (to align with old tmp_audits code)
audits_df <- tibble("_uuid" = names(audits_list), 
                        "audit_tbls" = audits_list)











