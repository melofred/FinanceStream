require("RCurl")
require("quantmod")
require("TTR")
require("jsonlite")
require("neuralnet")



  #trainset <- readFile #Load from GemFire using REST Query
  # http://localhost:8080/gemfire-api/v1/Stocks/ 
  #historical <- getURL(paste0('http://localhost:8080/gemfire-api/v1/Stocks?limit=500'))

  historical <- getURL(paste0('http://localhost:8080/gemfire-api/v1/queries/adhoc?q=SELECT%20DISTINCT%20*%20from%20/Stocks%20s%20ORDER%20BY%20s.ID%20desc%20LIMIT%205000'))

  historicalJSon <- fromJSON(historical)

  historicalSet=historicalJSon

  dataset <- subset(historicalSet, select = c("DaysHigh", "DaysLow", "LastTradePriceOnly")) 
  names(dataset) <- c("High","Low","Close")

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

  
  inputs <- data.frame(scale(rsi), scale(ema_diff), scale(high_diff), scale(low_diff), scale(sar))
  names(inputs) <- c("rsi","ema_diff", "high_diff", "low_diff", "sar")

  #remove extra NAs due to technical indicator lags
  inputs <- inputs[-1:-15,]
  dataset <- dataset[-1:-15,]

  #adds peaks and valleys
  inputs$peakvalley=0
  peaks <- findPeaks(dataset$Close, thresh=0.15)
  valleys <- findValleys(dataset$Close, thresh=0.15)
  inputs$peakvalley[peaks-1]=-1  #always lagged by 1
  inputs$peakvalley[valleys-1]=1
  


  trainset <-inputs[-nrow(inputs),] # exclude last line, will use that for prediction only
  
  mynet <-neuralnet(peakvalley ~ high_diff + low_diff + ema_diff + rsi + sar, trainset, hidden = 5, lifesign = "full", threshold = 0.01, stepmax=40000)

  write('Saving network....',stdout());

  save(mynet, file="mynet.RData");

  write('Done \r\n',stdout())


  write('\r\n',stdout())
