# Reach from stdin - need to find a pattern to stop reading.

#f <- file("stdin")
#open(f)
#while(length(line <- readLines(f,n=1)) > 0) {
#  write(line, stderr())
#  # process line
#}

# Remember to close file






require("RCurl")
require("quantmod")
require("TTR")
# Requires a previous "ticker" variable (i.e. 'VALE5.SA') to be set

if (!exists("ticker") || is.null(ticker)) {
    stop('Invalid argument: ticker is NULL')
}

#tmp<- getURL(paste0('http://chartapi.finance.yahoo.com/instrument/1.0/',ticker,'/chartdata;type=quote;range=10d/csv'))
tmp<- getURL(paste0('http://chartapi.finance.yahoo.com/instrument/1.0/',ticker,'/chartdata;type=quote;range=30d/csv'))
tmp <- strsplit(tmp,'\n')
tmp <- tmp[[1]]
tmp <- tmp[-c(1:32)]
tmp <- strsplit(tmp, ',')
tmp <- do.call('rbind',tmp)
mode(tmp) <- 'numeric'
colnames(tmp) <- c("Timestamp","Close", "High", "Low", "Open", "Volume")
tmpxts <- xts(tmp[,-1], order.by=as.POSIXct(tmp[,1], origin="1970-01-01"), dateFormat = "POSIXct", format="%Y-%m-%d %H:%M:%S:%OS", header=TRUE)
quartz()
chartSeries(tmpxts, major.ticks='hours', TA="addRSI(15);addBBands(n=20)")
tmpxts
