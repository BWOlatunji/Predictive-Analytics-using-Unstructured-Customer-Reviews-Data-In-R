# Load the package required to read JSON files.
library(DBI)
library(dbplyr)
library(duckdb)
library(tidyverse)


# Create a connection to DuckDB
con <- DBI::dbConnect(duckdb::duckdb())

# connect to a named db or create a new database, yelp.duckdb
con <- DBI::dbConnect(duckdb::duckdb(), dbdir = "yelp_db")

# list of database tables
DBI::dbListTables(con)


# get the business with the most reviews
review_b_count <- tbl(con, "review_tbl") |>  
  count(business_id, sort = TRUE) |> collect()

# get name of business
business_info <- tbl(con, "business_tbl") |> 
  filter(business_id == "_ab50qdWOk0DdB6XOrBitw") |> 
  collect()

acme_oyster_house_reviews <- tbl(con, "review_tbl") |> 
  filter(business_id == "_ab50qdWOk0DdB6XOrBitw") |> 
  collect()

write_rds(acme_oyster_house_reviews, "data/acme_oyster_house_reviews.rds")


