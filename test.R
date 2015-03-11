require("RCurl")
require("quantmod")
require("TTR")
require("jsonlite")
# Requires a previous "ticker" variable (i.e. 'VALE5.SA') to be set

# Read from stdin - need to find a pattern to stop reading?

f <- file("stdin")
open(f)
while(TRUE) {
  line <- readLines(f,n=1)
  write(line, stdout())
  jsonStr <- fromJSON(line)
  write(names(jsonStr),stdout())
  write(jsonStr$timestamp,stdout())
  write('\r\n',stdout())
  #write(jsonStr,stderr())
  # process line
}

#close(f)
# Remember to close file
