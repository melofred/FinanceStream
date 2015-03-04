# FinanceStream

http://www.quantshare.com/sa-426-6-ways-to-download-free-intraday-and-tick-data-for-the-us-stock-market

The stream in Spring XD will be continuously taking quotes from Yahoo's YQL like  

https://query.yahooapis.com/v1/public/yql?q=select%20*%20from%20yahoo.finance.quote%20where%20symbol%20in%20(%22EMC%22)&env=store%3A%2F%2Fdatatables.org%2Falltableswithkeys&format=json  => substitute EMC with the symbol desired

and storing in GemFire, partitioned by Key. [Stream 1]


stream create stream1 --definition "trigger --fixedDelay=10 | http-client --url='''https://query.yahooapis.com/v1/public/yql?q=select * from yahoo.finance.quote where symbol in (\"MSFT\")&format=json&env=store://datatables.org/alltableswithkeys''' --httpMethod=GET | splitter --expression=#jsonPath(payload,'$.query.results.quote') | gemfire-json-server --regionName=Stocks --keyExpression=payload.getField('symbol')" --deploy



Next, from time to time a R script will calculate some TA indicators using queries and functions in GemFire, accessed from R through the Gem rest API. Results can be stored in Gem too.  [Stream 2]

From a desktop, CQ and/or client subscriptions will be showing alerts at the web app.


