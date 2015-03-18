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
  newRow <- fromJSON(line)
  

  #trainset <- readFile #Load from GemFire using REST Query
  # http://localhost:8080/gemfire-api/v1/Stocks/ 
  historical <- getURL(paste0('http://localhost:8080/gemfire-api/v1/Stocks?limit=500'))
  historicalJSon <- fromJSON(historical)

  historicalSet=historicalJSon$Stocks

  dataset <- subset(historicalSet, select = c("High", "Low", "Close")) 

  #Add new row to the end of dataset for computing technical indicators.
  rbind (dataset, c(newRow$High, newRow$Low, newRow$Close))

  # Computing and adding the change column
  originalSet <- dataset
  dataset <- originalSet[-1,]
  dataset$Change <- diff(originalSet$Close)


  # Apply Lag on the input variables
  lag_dataset <- data.frame (Lag(dataset$Change,1), dataset$Close, dataset$High, dataset$Low)
  
  # set header
  names(lag_dataset) <- c("Change", "Close", "High", "Low")
  
  # Remove the first X lines (x=3 here)  to avoid NAs due to the lag
  lag_dataset <- lag_dataset[-1:-3,]

  # include technical indicators
  ema <- EMA(lag_dataset$Close, 5) # lag = n-1 (default=9)
  ema_diff <- lag_dataset$Close - ema # lag = above
  rsi <- RSI(lag_dataset$Close, 5) # lag = n (default=14)
  smi <- SMI(HLC(lag_dataset))     # lag = nSlow+nSig (default=34)
  sar <- SAR(HLC(lag_dataset))     # lag = 0

  high_diff = lag_dataset$High-lag_dataset$Close
  low_diff = lag_dataset$Close-lag_dataset$Low

  #ti = data.frame(ema, rsi)
  #names(ti) <- c("ema","rsi" ) 
  
  inputs <- data.frame(rsi, ema_diff, lag_dataset$Close, high_diff, low_diff, lag_dataset$Change)
  names(inputs) <- c("rsi","ema_diff", "close", "high_diff", "low_diff", "change")
  
  #remove extra NAs due to technical indicator lags
  inputs <- inputs[-1:-5,]

  trainset <-inputs[-nrow(inputs),] # exclude last line, will use that for prediction only
  
  to_predict <- inputs[nrow(inputs),] # we'll predict based on the last value 
  to_predict <- subset(to_predict, select = -c(change)) # change won't be input - it's what we're predicting.

  mynet <-neuralnet(change ~ close + high_diff + low_diff + ema_diff + rsi, trainset, hidden = 6, lifesign = "full", linear.output = FALSE, threshold = 0.01)


  mynet.results <- compute(mynet, to_predict) # should be an input without response column
    

  cat("\nForecasted ",mynet.results$net.result, " and should have been ", inputs[nrow(inputs),]$change, "\n")

  write('Done',stdout())


  write('\r\n',stdout())
  #write(jsonStr,stderr())
  # process line
}
close(f)
# Remember to close file
