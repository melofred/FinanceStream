# FinanceStream

http://www.quantshare.com/sa-426-6-ways-to-download-free-intraday-and-tick-data-for-the-us-stock-market

The stream in Spring XD will be continuously taking quotes from Yahoo's YQL like  

https://query.yahooapis.com/v1/public/yql?q=select%20*%20from%20yahoo.finance.quote%20where%20symbol%20in%20(%22EMC%22)&env=store%3A%2F%2Fdatatables.org%2Falltableswithkeys&format=json  => substitute EMC with the symbol desired

and storing in GemFire, partitioned by Key. [Stream 1]


stream create stream1 --definition "trigger --fixedDelay=10 | http-client --url='''https://query.yahooapis.com/v1/public/yql?q=select * from yahoo.finance.quote where symbol in (\"MSFT\")&format=json&env=store://datatables.org/alltableswithkeys''' --httpMethod=GET | splitter --expression=#jsonPath(payload,'$.query.results.quote') | gemfire-json-server --regionName=Stocks --keyExpression=payload.getField('symbol')" --deploy



{"query":{"count":1,"created":"2015-03-06T08:21:34Z","lang":"en-US","results":{"quote":{"symbol":"MSFT","AverageDailyVolume":"36273300","Change":"+0.055","DaysLow":"42.82","DaysHigh":"43.24","YearLow":"37.51","YearHigh":"50.05","MarketCapitalization":"353.7B","LastTradePriceOnly":"43.11","DaysRange":"42.82 - 43.24","Name":"Microsoft Corpora","Symbol":"MSFT","Volume":"23193540","StockExchange":"NasdaqNM"}}}}


Next, from time to time a R script will calculate some TA indicators using queries and functions in GemFire, accessed from R through the Gem rest API. Results can be stored in Gem too.  [Stream 2]

From a desktop, CQ and/or client subscriptions will be showing alerts at the web app.

Reading from GemFire through CQ

stream create stream2 --definition "gemfire-cq --query='select * from /Stocks' | log " --deploy

Adding datetime to payload through Groovy script transformation

stream create stream1 --definition "trigger --fixedDelay=3 | http-client --url='''https://query.yahooapis.com/v1/public/yql?q=select * from yahoo.finance.quote where symbol in (\"MSFT\")&format=json&env=store://datatables.org/alltableswithkeys''' --httpMethod=GET | splitter --expression=#jsonPath(payload,'$.query.results.quote') | transform  --script='file:/Users/wmarkito/Pivotal/samples/FinanceStream/transform.groovy'|log" --deploy



Where transform.groovy is:

payload.put("timestamp", headers.get('timestamp'))

return payload


stream create stream1 --definition "trigger --fixedDelay=3 | http-client --url='''https://query.yahooapis.com/v1/public/yql?q=select * from yahoo.finance.quote where symbol in (\"MSFT\")&format=json&env=store://datatables.org/alltableswithkeys''' --httpMethod=GET | splitter --expression=#jsonPath(payload,'$.query.results.quote') | transform --script='file:/Users/fmelo/FinanceStream/transform.groovy'| gemfire-json-server --regionName=Stocks --keyExpression=payload.getField('timestamp')" --deploy



stream create stream1 --definition "trigger --fixedDelay=3 | http-client --url='''https://query.yahooapis.com/v1/public/yql?q=select * from yahoo.finance.quote where symbol in (\"MSFT\")&format=json&env=store://datatables.org/alltableswithkeys''' --httpMethod=GET | splitter --expression=#jsonPath(payload,'$.query.results.quote') | transform --script='file:/Users/fmelo/FinanceStream/transform.groovy'| gemfire-json-server --useLocator=true --host=localhost --port=10334 --regionName=Stocks --keyExpression=payload.getField('timestamp')" --deploy

