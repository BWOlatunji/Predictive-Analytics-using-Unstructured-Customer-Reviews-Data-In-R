# Load the package required to read JSON files.
library(DBI)
library(dbplyr)
library(duckdb)
library(tidyverse)

## Note: Download Yelp dataset from the web: https://www.yelp.com/dataset
# Extract the JSON files from the zipped dowload file to complete the steps below
# Create a connection to DuckDB
con <- DBI::dbConnect(duckdb::duckdb())

# connect to a named db or create a new database, yelp.duckdb
con <- DBI::dbConnect(duckdb::duckdb(), dbdir = "yelp_db")

# Warning message:
# Database is garbage-collected, use dbDisconnect(con, shutdown=TRUE) or duckdb::duckdb_shutdown(drv) to avoid this.

# Execute this code to install and load json on duckdb
DBI::dbExecute(con, "INSTALL json; LOAD json;")
#> [1] 0

DBI::dbExecute(con, "CREATE TABLE business_tbl AS SELECT * 
          FROM read_json_auto('data/yelp_dataset/yelp_academic_dataset_business.json');")
#> [1] 150346

DBI::dbExecute(con, "CREATE TABLE checkin_tbl AS SELECT * 
          FROM read_json_auto('data/yelp_dataset/yelp_academic_dataset_checkin.json');")
#>[1] 131930

DBI::dbExecute(con, "CREATE TABLE review_tbl AS SELECT * FROM read_json_auto('data/yelp_dataset/yelp_academic_dataset_review.json');")
#> [1] 6990280

DBI::dbExecute(con, "CREATE TABLE tip_tbl AS SELECT * FROM read_json_auto('data/yelp_dataset/yelp_academic_dataset_tip.json');")
#> [1] 908915

DBI::dbExecute(con, "CREATE TABLE user_tbl AS SELECT * FROM read_json_auto('data/yelp_dataset/yelp_academic_dataset_user.json');")
#> [1] 1987897

# list / describe / select first records
DBI::dbListTables(con)

