require("RCurl")
require("quantmod")
require("TTR")
require("jsonlite")
require("RSNNS")



  historical <- getURL(paste0('http://localhost:8080/gemfire-api/v1/queries/adhoc?q=SELECT%20DISTINCT%20*%20FROM%20/Stocks%20s%20ORDER%20BY%20%22timestamp%22%20LIMIT%20100000'))

  historicalSet <- fromJSON(historical)

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

  
  inputs <- data.frame(dataset$Close, ema, ema_diff, rsi, smi, sar, high_diff, low_diff)
  names(inputs) <- c("close", "ema", "ema_diff", "rsi", "smi","sar", "high_diff", "low_diff")


  #remove extra NAs due to technical indicator lags
  inputs <- inputs[-1:-35,]
  dataset <- dataset[-1:-35,]

  # normalize
  inputs$closeNorm=normalizeData(inputs$close)
  inputs$ema=normalizeData(inputs$ema)
  inputs$ema_diff=normalizeData(inputs$ema_diff)
  inputs$rsi=normalizeData(inputs$rsi)
  inputs$sar=normalizeData(inputs$sar)
  inputs$smi=normalizeData(inputs$smi) 
  inputs$high_diff=normalizeData(inputs$high_diff)
  inputs$low_diff=normalizeData(inputs$low_diff)

  #adds peaks and valleys
  inputs$peakvalley=0
  peaks <- findPeaks(dataset$Close, thresh=0.0015)
  valleys <- findValleys(dataset$Close, thresh=0.0015)
  inputs$peakvalley[peaks-1]=-1  #always lagged by 1
  inputs$peakvalley[valleys-1]=1
  


  #trainset <-inputs[-nrow(inputs),] # exclude last line, will use that for prediction only

  trainset <- subset(inputs, select = -c(ema, rsi, sar, smi, high_diff, low_diff, peakvalley))

  jordannet <- jordan(x=trainset,y=inputs$peakvalley, size=c(15), learnFuncParams=c(0.3), linOut=FALSE, maxit=10000)

  write('Saving network....',stdout());

  f <- file('/Users/fmelo/FinanceStream/mynet_jordan.RData')
  save(jordannet, file=f);
  flush(f)
  close(f)

  write('Done \r\n',stdout())


  write('\r\n',stdout())
