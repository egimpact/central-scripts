
###########################################
# -------- Code to add to DCM1 ------------
###########################################

source("Scripts/Utils/1_1_kobo_functions_v2.R")

# authentication (ensure you have kobo_api_key loaded from your credentials)
headers <- add_headers(Authorization = paste("Token", kobo_api_key))

# url (ensure you have form_uid and kobo_server_url loaded)
export_url <- paste0(kobo_server_url, "api/v2/assets/", form_uid, "/exports/")


# ------- Generate export and get export status information --------

# generate export
export_created <- create_export(url = export_url, headers = headers, body = export_body)

# Get export status URL
export_status_url <- paste0(export_created$url, "?format=json")

# get export info
export_info <- get_export_info(url = export_status_url, headers = headers)

# ------- Get URL and download export --------
  
# Get export url
xlsx_url <- export_info$result

# Download export
download <- download_export(
  download_url = xlsx_url,
  headers = headers
)

# ------- Load downloaded export --------

# read from temporary file
datasetKOBO1__list <- set_names(map(download$sheet_names, 
                                    ~ read_excel(download$temp_file, sheet = .x, guess_max = 100000)),
                                download$sheet_names)


# optional: set names manually
# names(datasetKOBO1__list) <- c("main", "repeat1", "repeat2", "repeat3")






#########################################
## ---------- Code to replace: ----------
#########################################

# source("Scripts/Utils/1_1_kobo_functions.R")


# d_exports <- kobohr_create_export(
#   kobo_server_url = kobo_server_url,
#   asset_uid = form_uid,
#   type = type,
#   lang = lang,
#   fields_from_all_versions = fields_from_all_versions,
#   hierarchy_in_labels = hierarchy_in_labels,
#   group_sep = group_sep,
#   username,
#   pw
# ) %>% as_tibble() 
# Sys.sleep(30)
# 
# ## #use the table to fetch the export link
# print("Downloading export")
# result <- GET(
#   url=paste0(as.character(d_exports$url),"?format=json"),
#   authenticate(username,pw),
#   progress() 
# )
# Sys.sleep(10)
# 
# ## #use the link from the previous output and save the export in a temporary file
# print("Processing export")
# result_file <- GET(
#   url = fromJSON(rawToChar(result$content))$result,
#   authenticate(username,pw),
#   write_disk(tf <- tempfile(fileext = ".xlsx")),
#   progress()
# )
# Sys.sleep(30)
# 
# ## #Get the sheetnames and use it to read all sheets on the downloaded file 
# datasetKOBO1_sheet_names <- excel_sheets(tf)
# datasetKOBO1_sheet_names     
# 
# # #Read all sheets to list
# datasetKOBO1__list <- lapply(datasetKOBO1_sheet_names, function(x) { 
#   as.data.frame(read_excel(tf, sheet = x)) } )
# 
# # #hamonize sheet names to main and indiv across 
# names(datasetKOBO1__list) <- c("main", "indiv_items")










