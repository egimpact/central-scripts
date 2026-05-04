rm(list = ls())


library(httr)
library(jsonlite)

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
form_uid <- "aHffC3VA9diqugBeeyQnTJ"

# CHANGE FOR SERVER
base_url <- paste0(url, "/", form_uid, "/data/")





# dataframe of _ids linked to _uuids 

if (testing <- FALSE){
  audit_ids <- new_submissions |>
  select(sub_id = "_id", sub_uuid = "_uuid")
} else if (testing <- TRUE){
  test_ids <- c("3137013")
  test_uuids <- c("41359158-ec82-494b-afbf-5e56292a9624")
  
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



audits_df <- tibble("_uuid" = names(audits_list), 
                        "audit_tbls" = audits_list)

