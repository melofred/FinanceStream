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
  jsonStr <- fromJSON(line)

  #trainset <- readFile #Load from GemFire using REST Query
  # http://localhost:8080/gemfire-api/v1/Stocks/ 
  historical <- getURL(paste0('http://localhost:8080/gemfire-api/v1/Stocks?limit=1000'))
  historicalJSon <- fromJSON(historical)

  historicalSet=historicalJSon$Stocks

  trainset <- subset(historicalSet, select = c("Change", "LastTradePriceOnly", "DaysHigh", "DaysLow")) 

  # Apply Lag on the input variables
  lag_trainset <- data.frame (trainset$Change, Lag(trainset$LastTradePriceOnly,1), Lag(trainset$DaysHigh,1), Lag(trainset$DaysLow,1))
  
  # set header
  names(lag_trainset) <- c("Change", "LastTradePriceOnly", "DaysHigh", "DaysLow")
  
  # Remove the first X lines (x=3 here)  to avoid NAs
  lag_trainset <- lag_trainset[-1:-3,]

  # include technical indicators
  ema <- EMA(lag_trainset$LastTradePriceOnly, 5) # 4 first occurences will need to be removed
  rsi <- RSI(lag_trainset$LastTradePriceOnly, 5)
  #smi need HLC
  #sar need HLC

  # use data(ttrc) to generate random data to test
  # ttrc

  ti = data.frame(ema, rsi)
  names(ti) <- c("ema","rsi") 
  

  mynet <-neuralnet(Change ~ LastTradePriceOnly + DaysHigh + DaysLow, lag_trainset, hidden = 4, lifesign = "full", linear.output = FALSE, threshold = 0.01)


  write(names(jsonStr),stdout())
  write(line,stdout())

  #temp_test <- subset(trainset, select = c("LastTradePriceOnly", "DaysHigh", "DaysLow"))
  temp_test <- subset(jsonStr$request, select = c("LastTradePriceOnly", "DaysHigh", "DaysLow"))

  mynet.results <- compute(mynet, temp_test) #temp_test should be an input without response.Change
    
  write(mynet.results$net.result,stdout())

  write('Done',stdout())


  write('\r\n',stdout())
  #write(jsonStr,stderr())
  # process line
}
close(f)
# Remember to close file
