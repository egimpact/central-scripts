
library(sf)
# start_q <- "enum"
# start_node <- "/a86Ne93SgPR3YJqafWiTqX/enum"   # paste0(form_uid, start_q)
# end_node <- "/a86Ne93SgPR3YJqafWiTqX/consented/enumerator_note"

gps_shapefile_path <- "C:/Users/EdwinGIBB/ACTED/IMPACT MMR - Documents/General/05. REACH/_Data Unit/Shiny apps/gps_map_from_audit_summary/data/tester_shapefile.geojson"
gps_summary_backup <- read.xlsx(gps_summary_path)


gps_dps <- 4  # 4 decimal places is roughly 11.1 meter precision

# summarise all audit files
gps_points <- audits_list %>% 
  purrr::map(
    .f = ~ .x %>%
      mutate(latitude = round(latitude, gps_dps),
             longitude = round(longitude, gps_dps),
             location_id = paste(latitude, longitude, sep = "@"), 
             q_time_secs = (end - start)/1000) %>% 
      filter(!is.na(latitude)) %>% 
      group_by(location_id) %>% 
      summarise(latitude = mean(latitude, na.rm = T),
                longitude = mean(longitude, na.rm = T),
                accuracy = mean(accuracy, na.rm = T),
                n_questions = n(),
                n_distinct_qs = n_distinct(node),
                time_spent_secs = sum(q_time_secs, na.rm = T), 
                time_spent_mins = round(time_spent_secs/60, 2), 
                .groups = "drop")
  ) 


# combine in one dataset
gps_points_df <- bind_rows(gps_points, .id = "uuid")


gps_points_df <- gps_points_df %>% 
  left_join(dataset_new_submissions_main %>% 
              select(uuid = `_uuid`, Partner = org, Enumerator = enum_id, reported_admin3 = admin3, reported_admin4 = admin4))


# combine with existing summary table


gps_summary_backup_export <- bind_rows(
  gps_summary_backup, 
  gps_points_df
) %>% 
  distinct()



# add requisite info from data
data <- df_export %>% 
  select(uuid = `_uuid`, org, enum_id,
         reported_admin3 = `consented/module_a_location/admin3`, reported_admin4 = `consented/module_a_location/admin4`,
         reported_admin3_label = `consented/module_a_location/admin3_township_label`, reported_admin4_label = `consented/module_a_location/admin4_town_vt_label`)






# Expoort


write.xlsx(gps_summary_backup_export, gps_summary_path)



shapefile <- st_as_sf(
  gps_points_df %>% left_join(data),
  coords = c("longitude","latitude"),
  crs = 4326,
  remove = F
)

st_write(shapefile, gps_shapefile_path, delete_dsn  = TRUE)





