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
  #write(historical,stdout())
  historicalJSon <- fromJSON(historical)


  #f <- file("sample", open="r")
  #lines <- readLines(f)
  #jsonSet <- fromJSON(lines) 

  #json_file <- stream_in(file("sample"))
  #data <- fromJSON(json_file)
  #write(names(json_file),stdout())

  #trainset <- jsonSet

  trainset=historicalJSon$Stocks


  mynet <-neuralnet(Change ~ LastTradePriceOnly + DaysHigh + DaysLow, trainset, hidden = 6, lifesign = "minimal", linear.output = FALSE, threshold = 0.1)

  # {"symbol":"MSFT","AverageDailyVolume":37528500,"Change":0.18,"DaysLow":41.28,"DaysHigh":41.64,"YearLow":37.79,"YearHigh":50.05,"MarketCapitalization":"340.95B","LastTradePriceOnly":41.56,"DaysRange":"41.28 - 41.64","Name":"Microsoft Corporation","Symbol":"MSFT","Volume":35267048,"StockExchange":"NMS","timestamp":1426543581490}  



  jsonStr$Change <- NULL
  jsonStr$id <- NULL
  jsonStr$timestamp <- NULL
  jsonStr$symbol <- NULL
  jsonStr$AverageDailyVolume <- NULL
  jsonStr$YearLow <- NULL
  jsonStr$YearHigh <- NULL
  jsonStr$MarketCapitalization <- NULL
  jsonStr$DaysRange <- NULL
  jsonStr$Name <- NULL
  jsonStr$Symbol <- NULL
  jsonStr$Volume <- NULL
  jsonStr$StockExchange <- NULL



  write(names(jsonStr),stdout())
  write(line,stdout())
  mynet.results <- compute(mynet, jsonStr) #temp_test should be an input without response.Change
    

  write('\r\n',stdout())
  #write(jsonStr,stderr())
  # process line
}
close(f)
# Remember to close file
