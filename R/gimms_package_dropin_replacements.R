serverPath <- function(server = c("ecocast", "nasanex"), version = 1L) {
    if (server[1] == "ecocast") {
        paste0("https://ecocast.arc.nasa.gov/data/pub/gimms/3g.",
               ifelse(as.integer(version) == 1, "v1", "v0"))
    } else {
        "https://nasanex.s3.amazonaws.com"
    }
}

updateNasanex <- function() {
    con <- serverPath("nasanex")
    
    cnt <- try(RCurl::getURL(con, dirlistonly = TRUE), silent = TRUE)
    
    if (class(cnt) != "try-error") {
        cnt <- sapply(strsplit(strsplit(cnt, "<Key>")[[1]], "</Key>"), "[[", 1)
        
        id <- sapply(cnt, function(i) {
            length(grep("^AVHRR/GIMMS/3G.*VI3g$", i)) == 1
        })
        cnt <- cnt[id]
    }
    return(paste0(con, "/", cnt))
}

updateEcocast <- function(version = 1L)
{
    version <- as.integer(version)
    con <- curl::curl(paste0(serverPath(version = version), "/00FILE-LIST.txt"))
    
    suppressWarnings(
        try({
            cnt <- readLines(con);
            close(con)
        }
        , silent = TRUE)
    )
    return(cnt)
}

updateInventory <- function(server = c("ecocast", "nasanex"), version = 1L,
                            quiet = FALSE) {
    
    ## available files (online)
    is_ecocast <- server[1] == "ecocast"
    fls <- if (is_ecocast) updateEcocast(version) else updateNasanex()
    
    ## if first-choice server is not available, try alternative server
    if (class(fls) == "try-error" & length(server) == 2) {
        if (!quiet)
            cat("Priority server ('", server[1],
                "') is not available. Contacting alternative server ('", server[2],
                "').\n", sep = "")
        fls <- if (is_ecocast) updateNasanex() else updateEcocast(version)
    }
    
    ## available files (offline)
    if (class(fls) == "try-error") {
        if (!quiet)
            cat("Failed to retrieve online information. Using local file inventory...\n")
        
        fls <- if (server[1] == "nasanex") {
            readRDS(system.file("extdata", "inventory_nnv0.rds", package = "gimms"))
        } else {
            readRDS(system.file("extdata", paste0("inventory_ec",
                                                  ifelse(version == 1, "v1", "v0"),
                                                  ".rds"), package = "gimms"))
        }
    }
    
    ## remove duplicates and sort according to date
    fls <- fls[!duplicated(basename(fls))]
    
    ## return files
    return(fls)
}
