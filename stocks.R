require("RCurl")
require("quantmod")
require("TTR")
require("jsonlite")
require("neuralnet")



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

  historical <- getURL(paste0('http://localhost:8080/gemfire-api/v1/queries/adhoc?q=SELECT%20DISTINCT%20*%20from%20/Stocks%20s%20ORDER%20BY%20s.ID%20desc'))

  historicalJSon <- fromJSON(historical)

  historicalSet=historicalJSon

  dataset <- subset(historicalSet, select = c("DaysHigh", "DaysLow", "LastTradePriceOnly")) 
  names(dataset) <- c("High","Low","Close")

  #Add new row to the end of historical dataset for computing technical indicators.
  temprow <- matrix(c(rep.int(NA,length(dataset))),nrow=1,ncol=length(dataset))
  newrow <- data.frame(temprow)
  colnames(newrow) <- colnames(dataset)
  dataset <- rbind(dataset,newrow)
  dataset[nrow(dataset),] <- c(streamRow$DaysHigh, streamRow$DaysLow, streamRow$LastTradePriceOnly)
  

  # Computing and adding the change column
  originalSet <- dataset
  dataset <- originalSet[-1:-50,]
  dataset$Change <- diff(originalSet$Close, lag=50) # applies lag to the change calculation (here we're trying to predict the change within 50 iterations)

  # Remove the first X lines (x=3 here)  to avoid NAs due to the lag
  #lag_dataset <- lag_dataset[-1:-3,]

  # include technical indicators
  ema <- EMA(dataset$Close, 5) # lag = n-1 (default=9)
  ema_diff <- dataset$Close - ema # lag = above
  rsi <- RSI(dataset$Close, 5) # lag = n (default=14)
  smi <- SMI(HLC(dataset))     # lag = nSlow+nSig (default=34)
  sar <- SAR(HLC(dataset))     # lag = 0

  high_diff = dataset$High-dataset$Close
  low_diff = dataset$Close-dataset$Low

  
  inputs <- data.frame(scale(rsi), scale(ema_diff), scale(dataset$Close), scale(high_diff), scale(low_diff), dataset$Change)
  names(inputs) <- c("rsi","ema_diff", "close", "high_diff", "low_diff", "change")
  
  #remove extra NAs due to technical indicator lags
  inputs <- inputs[-1:-5]

  trainset <-inputs[-nrow(inputs),] # exclude last line, will use that for prediction only
  
  to_predict <- inputs[nrow(inputs),] # we'll predict based on the last value 
  to_predict <- subset(to_predict, select = -c(change)) # change won't be input - it's what we're predicting.

  mynet <-neuralnet(change ~ close + high_diff + low_diff + ema_diff + rsi, trainset, hidden = 9, lifesign = "full", linear.output = FALSE, threshold = 0.01)


  mynet.results <- compute(mynet, to_predict) # should be an input without response column
    
  cat("\nForecasting for input: ",streamRow$LastTradePriceOnly,"\n")
  cat("\nForecasted ",mynet.results$net.result, " and should have been ", inputs[nrow(inputs),]$change, "\n")

  write('Done',stdout())


  write('\r\n',stdout())
  #write(jsonStr,stderr())
  # process line
}
close(f)
# Remember to close file
