
detect_outliers <- function(x) {
  
  if (missing(x)) stop("The argument x needs a vector.")
  
  if (!is.numeric(x)) stop("The argument x must be numeric.")
  
  data_tbl <- tibble(data = x)
  
  limits_tbl <- data_tbl %>%
    summarise(
      quantile_lo = quantile(data, probs = 0.25, na.rm = TRUE),
      quantile_hi = quantile(data, probs = 0.75, na.rm = TRUE),
      iqr         = IQR(data, na.rm = TRUE),
      limit_lo    = quantile_lo - 1.5 * iqr,
      limit_hi    = quantile_hi + 1.5 * iqr
    )
  
  output_tbl <- data_tbl %>%
    mutate(outlier = case_when(
      data < limits_tbl$limit_lo ~ TRUE,
      data > limits_tbl$limit_hi ~ TRUE,
      TRUE ~ FALSE
    ))
  
  return(output_tbl$outlier)
  
}