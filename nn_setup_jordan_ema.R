require("RCurl")
require("quantmod")
require("TTR")
require("jsonlite")
require("RSNNS")



  historical <- getURL(paste0('http://localhost:8080/gemfire-api/v1/queries/adhoc?q=SELECT%20DISTINCT%20*%20FROM%20/Stocks%20s%20ORDER%20BY%20%22timestamp%22%20desc%20LIMIT%20100000'))

  historicalSet <- fromJSON(historical)
  historicalSet <-historicalSet[order(historicalSet$timestamp),]

  dataset <- subset(historicalSet, select = c("DaysHigh", "DaysLow", "LastTradePriceOnly")) 
  names(dataset) <- c("High","Low","Close")

  # include technical indicators
  ema <- EMA(dataset$Close) # lag = n-1 (default=9)
  ema_diff <- dataset$Close - ema # lag = above
  rsi <- RSI(dataset$Close) # lag = n (default=14)
  smi <- SMI(HLC(dataset))     # lag = nSlow+nSig (default=34)
  sar <- SAR(HLC(dataset))     # lag = 0

  high_diff = dataset$High-dataset$Close
  low_diff = dataset$Close-dataset$Low

  change <- diff(dataset$Close, lag=3) # applies lag to the change calculation 

  ema_lag <- lag.xts (ema, k=-1)
  
  inputs <- data.frame(dataset$Close, ema, ema_diff, rsi, sar, high_diff, low_diff)
  names(inputs) <- c("close", "ema", "ema_diff", "rsi", "sar", "high_diff", "low_diff")


  #remove extra NAs due to technical indicator lags
  inputs <- inputs[36:(NROW(inputs)-3),]
  dataset <- dataset[36:(NROW(dataset)-3),]
  ema_lag <- ema_lag[36:(NROW(ema_lag)-3)]
  change <- change[36:NROW(change)]
  

  # normalize
  inputs$closeNorm=normalizeData(inputs$close, type="0_1")
  inputs$emaNorm=normalizeData(inputs$ema, type="0_1")
  inputs$ema_diff=normalizeData(inputs$ema_diff, type="0_1")
  inputs$rsi=normalizeData(inputs$rsi, type="0_1")
  inputs$sar=normalizeData(inputs$sar, type="0_1")
#  inputs$smi=normalizeData(inputs$smi, type="0_1") 
  inputs$high_diff=normalizeData(inputs$high_diff, type="0_1")
  inputs$low_diff=normalizeData(inputs$low_diff, type="0_1")

  #adds peaks and valleys
  inputs$peakvalley=0
  peaks <- findPeaks(dataset$Close, thresh=0.00015)
  valleys <- findValleys(dataset$Close, thresh=0.00015)
  inputs$peakvalley[peaks-1]=-1  #always lagged by 1
  inputs$peakvalley[valleys-1]=1
  


  data_in <- normalizeData(subset(inputs, select = c(ema,close)))
  data_out <- normalizeData(ema_lag)

  patterns <- splitForTrainingAndTest(data_in, data_out, ratio = 0.15)
  

   jordannet <- jordan(patterns$inputsTrain, patterns$targetsTrain, size = c(10), learnFuncParams = c(0.2), maxit = 100000, inputsTest = patterns$inputsTest, targetsTest = patterns$targetsTest, linOut = FALSE)


  write('Saving network....',stdout());

  f <- file('/Users/fmelo/FinanceStream/mynet_jordan.RData')
  save(jordannet, file=f);
  flush(f)
  close(f)

  write('Done \r\n',stdout())


  write('\r\n',stdout())
