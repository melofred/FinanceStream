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

  trainset <- subset(historicalSet, select = c("Change", "LastTradePriceOnly", "DaysHigh", "DaysLowyy")) 

  mynet <-neuralnet(Change ~ LastTradePriceOnly + DaysHigh + DaysLow, trainset, hidden = 4, lifesign = "full", linear.output = FALSE, threshold = 0.1)


  write(names(jsonStr),stdout())
  write(line,stdout())

  temp_test <- subset(trainset, select = c("LastTradePriceOnly", "DaysHigh", "DaysLowyy"))

  mynet.results <- compute(mynet, temp_test) #temp_test should be an input without response.Change
    
  write(mynet.results$net.result,stdout())

  write('Done',stdout())


  write('\r\n',stdout())
  #write(jsonStr,stderr())
  # process line
}
close(f)
# Remember to close file
