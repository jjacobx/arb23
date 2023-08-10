load_quietly <- function(...) {
    suppressMessages(suppressWarnings(library(...)))
}

load_quietly(dplyr)
load_quietly(glue)
load_quietly(readr)
load_quietly(rlang)
load_quietly(stringr)

cmd_args = commandArgs(trailingOnly = TRUE)
if (is_empty(cmd_args)) {
    abort("Please provide the name of the experiment. ")
}
if (length(cmd_args) == 1) {
    cmd_args[[2]] <- "0"
}

exp_name <- cmd_args[[1]]
freq_scaling <- cmd_args[[2]] %>% as.integer() %>% as.logical()

tb <- read_csv(glue("raw/quest-energy-{exp_name}-raw.csv"), show_col_types = FALSE)
tb <- filter(tb, !HAS_ERRORS) %>% select(-HAS_ERRORS)

# prog <- pull(tb, PROG) %>% unique()
# if (length(prog) > 1) {
#     abort("Data contains information about multiple programs! ")
# }

extract_verbose <- function(s) {
    t <- str_detect(s, "^Verbose is ON")
    if (sum(t) && !prod(t)) {
        abort("Mixed verbose and non-verbose outputs! ")
    }

    v <- as.logical(prod(t))
    return(v)
}

extract_runtime <- function(s, verbose = FALSE) {
    if (!verbose) {
        t <- str_extract(s, "^[0-9.e+]+")
    } else {
        t <- str_extract(s, "Time taken: [0-9.e+]+")
        t <- str_extract(t, "[0-9.e+]+$")
    }
    as.numeric(t) / 1000
}

extract_energy <- function(s) {
    e <- str_extract(s, "[0-9.]+[A-Z]$")

    # Multipliers for parsing integers with K/M/G suffixes
    suf <- str_extract(e, "[A-Z]$")
    mul <- integer(length(suf))
    mul[suf == "K"] <- 1E3
    mul[suf == "M"] <- 1E6
    mul[suf == "G"] <- 1E9

    e <- str_remove(e, "[A-Z]$")
    as.numeric(e) * mul
}

is_verbose <- extract_verbose(tb$OUTPUT)
tb <- mutate(tb, RUNTIME = extract_runtime(OUTPUT, is_verbose))
tb <- mutate(tb, ENERGY = extract_energy(OUTPUT))

tb <- select(tb, -OUTPUT)

if (freq_scaling) {
    tb <- group_by(tb, PROG, SLURM_NTASKS, QREG_SIZE)
    freq_order <- c("Low", "Medium", "Highm1", "High")
    tb <- arrange(tb, factor(SLURM_CPU_FREQ_REQ, freq_order), .by_group = TRUE)

    tb <- mutate(tb, SLOWDOWN = (RUNTIME - RUNTIME[[4]]) / RUNTIME[[4]])
    tb <- mutate(tb, SAVINGS = (ENERGY - ENERGY[[4]]) / ENERGY[[4]])
}


write_csv(tb, glue("proc/quest-energy-{exp_name}-proc.csv"))
