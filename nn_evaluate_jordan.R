require("RCurl")
require("quantmod")
require("TTR")
require("jsonlite")
require("RSNNS")



# Read from stdin - need to find a pattern to stop reading?

f <- file("stdin")
open(f)
while(TRUE) {
  line <- readLines(f,n=1)
  write(line, stdout())
  streamRow <- fromJSON(line)
  

  #trainset <- readFile #Load from GemFire using REST Query
  # http://localhost:8080/gemfire-api/v1/Stocks/ 
  #historical <- getURL(paste0('http://localhost:8080/gemfire-api/v1/Stocks?limit=500'))

  historical <- getURL(paste0('http://localhost:8080/gemfire-api/v1/queries/adhoc?q=SELECT%20DISTINCT%20*%20FROM%20/Stocks%20s%20ORDER%20BY%20%22timestamp%22%20desc%20LIMIT%2050'))

  historicalJSon <- fromJSON(historical)

  historicalSet=historicalJSon

  dataset <- subset(historicalSet, select = c("DaysHigh", "DaysLow", "LastTradePriceOnly")) 
  names(dataset) <- c("High","Low","Close")

  #Add new row to the end of historical dataset for computing technical indicators.
  temprow <- matrix(c(rep.int(NA,length(dataset))),nrow=1,ncol=length(dataset))
  newrow <- data.frame(temprow)
  colnames(newrow) <- colnames(dataset)
  dataset <- rbind(dataset,newrow)
  dataset[nrow(dataset),] <- c(as.numeric(streamRow$DaysHigh), as.numeric(streamRow$DaysLow), as.numeric(streamRow$LastTradePriceOnly))
  #dataset[nrow(dataset),] <- c(streamRow$DaysHigh, streamRow$DaysLow, streamRow$LastTradePriceOnly)
  

  # Computing and adding the change column
  #originalSet <- dataset
  #dataset <- originalSet[-1:-50,]
  #dataset$Change <- diff(originalSet$Close, lag=50) # applies lag to the change calculation (here we're trying to predict the change within 50 iterations)

  # Remove the first X lines (x=3 here)  to avoid NAs due to the lag
  #lag_dataset <- lag_dataset[-1:-3,]

  # include technical indicators
  ema <- EMA(dataset$Close) # lag = n-1 (default=9)
  ema_diff <- dataset$Close - ema # lag = above
  rsi <- RSI(dataset$Close) # lag = n (default=14)
  smi <- SMI(HLC(dataset))     # lag = nSlow+nSig (default=34)
  sar <- SAR(HLC(dataset))     # lag = 0

  high_diff = dataset$High-dataset$Close
  low_diff = dataset$Close-dataset$Low

  
  inputs <- data.frame(rsi, ema_diff, high_diff, low_diff, sar)
  names(inputs) <- c("rsi","ema_diff", "high_diff", "low_diff", "sar")

  #remove extra NAs due to technical indicator lags
  inputs <- inputs[-1:-15,]
  dataset <- dataset[-1:-15,]

  # normalize
  inputs$rsi=normalizeData(inputs$rsi)
  inputs$ema_diff=normalizeData(inputs$ema_diff)
  inputs$high_diff=normalizeData(inputs$high_diff)
  inputs$low_diff=normalizeData(inputs$low_diff)
  inputs$sar=normalizeData(inputs$sar)

  #adds peaks and valleys
  inputs$peakvalley=0
  peaks <- findPeaks(dataset$Close, thresh=0.15)
  valleys <- findValleys(dataset$Close, thresh=0.15)
  inputs$peakvalley[peaks-1]=-1  #always lagged by 1
  inputs$peakvalley[valleys-1]=1
  


  to_predict <- inputs[nrow(inputs),] # we'll predict based on the last value 
  to_predict <- subset(to_predict, select = -c(peakvalley)) # change won't be input - it's what we're predicting.

 
  load(file='/Users/fmelo/FinanceStream/mynet_jordan.RData')
  results <- predict(jordannet, to_predict) # should be an input without response column
    
  cat("\nForecasting for input: ",streamRow$LastTradePriceOnly,"\n")
  cat("\nForecasted ",results, "\n")

  write('Done',stdout())


  write('\r\n',stdout())
  #write(jsonStr,stderr())
  # process line
}
close(f)
# Remember to close file
