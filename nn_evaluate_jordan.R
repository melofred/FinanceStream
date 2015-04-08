require("RCurl")
require("quantmod")
require("TTR")
require("jsonlite")
require("RSNNS")



# Read from stdin - need to find a pattern to stop reading?

f <- file("stdin")
#f <- file("stocks_in_2")
open(f)
while(TRUE) {
  line <- readLines(f,n=1)
  #write(line, stdout())
  streamRow <- fromJSON(line)
  

  historical <- getURL(paste0('http://localhost:8080/gemfire-api/v1/queries/adhoc?q=SELECT%20DISTINCT%20*%20FROM%20/Stocks%20s%20ORDER%20BY%20%22timestamp%22%20LIMIT%20100'))

  historicalSet <- fromJSON(historical)

  dataset <- subset(historicalSet, select = c("DaysHigh", "DaysLow", "LastTradePriceOnly")) 
  names(dataset) <- c("High","Low","Close")

  #Add new row to the end of historical dataset for computing technical indicators.
  temprow <- matrix(c(rep.int(NA,length(dataset))),nrow=1,ncol=length(dataset))
  newrow <- data.frame(temprow)
  colnames(newrow) <- colnames(dataset)
  dataset <- rbind(dataset,newrow)
  dataset[nrow(dataset),] <- c(as.numeric(streamRow$DaysHigh), as.numeric(streamRow$DaysLow), as.numeric(streamRow$LastTradePriceOnly))
  

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

  inputs <- data.frame(dataset$Close, ema, ema_diff, rsi, smi, sar, high_diff, low_diff)
  names(inputs) <- c("close", "ema", "ema_diff", "rsi", "smi","sar", "high_diff", "low_diff")
 
  #remove extra NAs due to technical indicator lags
  inputs <- inputs[-1:-35,]
  dataset <- dataset[-1:-35,]

  # normalize
  inputs$closeNorm=normalizeData(inputs$close)
  inputs$emaNorm=normalizeData(inputs$ema)
  inputs$ema_diff=normalizeData(inputs$ema_diff)
  inputs$rsi=normalizeData(inputs$rsi)
  inputs$sar=normalizeData(inputs$sar)
  inputs$smi=normalizeData(inputs$smi)
  inputs$high_diff=normalizeData(inputs$high_diff)
  inputs$low_diff=normalizeData(inputs$low_diff)



  to_predict <- inputs[nrow(inputs),] # we'll predict based on the last value 
  to_predict <- subset(to_predict, select = c(close, ema))

 
  load(file='/Users/fmelo/FinanceStream/mynet_jordan.RData')
  results <- predict(jordannet, to_predict) # should be an input without response column
    
  streamRow$predictedPeak <- results[1,1]

  #cat("\nForecasting for timestamp: ",streamRow$timestamp,"  value  ", streamRow$predictedPeak, "\n")
 
#  inputWithPrediction=streamRow[1,]

  predicted_line <- data.frame(streamRow$timestamp, streamRow$predictedPeak);
  names(predicted_line) <- c("timestamp","predictedPeak")
  predicted_line <- toJSON(predicted_line);

  cat (predicted_line)

#  cat("\nForecasting for input: ",streamRow$LastTradePriceOnly,"\n")
  #cat("\nForecasted ",results, "\n")
  #write('Done',stdout())


  write('\r\n',stdout())
  #write(jsonStr,stderr())
  # process line
}
close(f)
# Remember to close file
