require("RCurl")
require("TTR")
require("jsonlite")

# stream create stream1 --definition "http --port=9020 | splitter --expression=#jsonPath(payload,'$') | transform --script='file:/Users/fmelo/FinanceStream/transform.groovy' |log" --deploy

#stream create stream1 --definition "http --port=9020 | splitter --expression=#jsonPath(payload,'$') | transform --script='file:/Users/fmelo/FinanceStream/transform.groovy' | gemfire-json-server --useLocator=true --host=localhost --port=10334 --regionName=Stocks --keyExpression=payload.getField('timestamp')" --deploy
# The splitter converts JSON to object. Necessary for the transformer to work.

data(ttrc)

#dataset <- subset(ttrc[1:100,], select = c("High", "Low", "Close"))
dataset <- subset(ttrc, select = c("High", "Low", "Close"))
for(i in 1:nrow(dataset)) {
    row <- dataset[i,]
    # do stuff with row

   dataSetJson <- toJSON(row)

   curlPerform(url='http://localhost:9020', postfields=dataSetJson)
}

#dataSetJson <- toJSON(dataset)

#curlPerform(url='http://localhost:9020', postfields=dataSetJson)
