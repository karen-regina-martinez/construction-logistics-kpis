# =============================================================================
# Simulated data generation
# -----------------------------------------------------------------------------
# All data in this project is RANDOM and represents a fictitious construction
# company. It does not correspond to any real company.
# A fixed seed is set so anyone can reproduce exactly the same data.
# =============================================================================

set.seed(2026)

# --- 1. Machinery inventory --------------------------------------------------
n_machines <- 103

machine_types <- c("Floor grinder", "Concrete mixer", "Rotary hammer", "Air compressor",
                   "Power generator", "Scaffolding", "Scarifier")
type_weights  <- c(0.20, 0.10, 0.20, 0.12, 0.10, 0.18, 0.10)

machinery <- data.frame(
  machine_id = sprintf("MCH-%03d", 1:n_machines),
  type       = sample(machine_types, n_machines, replace = TRUE, prob = type_weights),
  warehouse  = sample(c("Warehouse 1", "Warehouse 2"), n_machines,
                      replace = TRUE, prob = c(0.65, 0.35)),
  age_years  = sample(0:10, n_machines, replace = TRUE)
)

# Older machines are more likely to be under repair
prob_repair <- plogis(-2.2 + 0.22 * machinery$age_years)
machinery$status <- ifelse(runif(n_machines) < prob_repair,
                           "Under repair", "Available")

# Days under repair (only for machines currently under repair)
machinery$days_under_repair <- ifelse(
  machinery$status == "Under repair",
  round(rgamma(n_machines, shape = 2, rate = 0.12)),
  NA
)

# --- 2. Active staff per week (52 weeks) -------------------------------------
weeks <- 1:52
# Slight trend + seasonality (more work mid-year) + noise
employees <- round(44 + 0.08 * weeks +
                   5 * sin(2 * pi * (weeks - 10) / 52) +
                   rnorm(52, 0, 2.5))

weekly_staff <- data.frame(
  week             = weeks,
  active_employees = employees,
  active_sites     = pmax(2, round(employees / 9 + rnorm(52, 0, 0.8)))
)

# --- 3. Material requisitions ------------------------------------------------
n_req <- 420
sites <- paste("Site", LETTERS[1:8])

requisitions <- data.frame(
  requisition_id = sprintf("REQ-%04d", 1:n_req),
  week      = sort(sample(weeks, n_req, replace = TRUE)),
  site      = sample(sites, n_req, replace = TRUE),
  warehouse = sample(c("Warehouse 1", "Warehouse 2"), n_req,
                     replace = TRUE, prob = c(0.8, 0.2)),
  urgent    = sample(c(TRUE, FALSE), n_req, replace = TRUE, prob = c(0.15, 0.85))
)

# Delivery days: Warehouse 2 (contingency) and urgent orders are faster
base_days <- ifelse(requisitions$warehouse == "Warehouse 2", 1.2, 2.0)
base_days <- ifelse(requisitions$urgent, base_days * 0.5, base_days)
requisitions$delivery_days <- rpois(n_req, base_days)

# --- Save --------------------------------------------------------------------
dir.create("data", showWarnings = FALSE)
write.csv(machinery,    "data/machinery.csv",    row.names = FALSE)
write.csv(weekly_staff, "data/weekly_staff.csv", row.names = FALSE)
write.csv(requisitions, "data/requisitions.csv", row.names = FALSE)

message("Data saved to the data/ folder")
