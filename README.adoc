=== Finance Stream app setup

==== Pre-requisites:
- GemFire 7.1+ installed
- Spring XD 1.1+ installed
- R 3.1+ installed with the following packages
. RCurl
. quantmod
. TTR
. jsonlite
. RSNNS +

The R packages can be easily installed by typing at the R command line: 
----
> install.packages(c("RCurl","quantmod","TTR","jsonlite","RSNNS"))
----

==== Setup the environment for running the sample


* Start a GemFire locator, deploying pulse on port 7575

----
gfsh> start locator --name=locator1 --J=-Dgemfire.http-service-port=7575
----

* Start a GemFire server, deploying Rest interface at port 8080

----
gfsh>start server --name=server1 --J=-Dgemfire.start-dev-rest-api=true --J=-Dgemfire.http-service-port=8080
----

* Test the server Rest endpoint

In a web browser, access http://localhost:8080/gemfire-api/v1

----
{
  "regions" : [ {
    "name" : "Stocks",
    "type" : "REPLICATE",
    "key-constraint" : null,
    "value-constraint" : null
  } ]
}
----

* If the region __Stocks__ doesn't exist yet, create that

In GFSH, type:

----
gfsh> create region --name=/Stocks --type=REPLICATE
----

* Import existing test data

----
gfsh>import data --file=/Users/fmelo/FinanceStream/Stocks.gfd --region=/Stocks --member=server1
Data imported from file : /Users/fmelo/FinanceStream/Stocks.gfd on host : frederimelosmbp to region : /Stocks
----

You should see 2000+ objects

----
gfsh>describe region --name=/Stocks

Name            : Stocks
Data Policy     : replicate
Hosting Members : server1

Non-Default Attributes Shared By Hosting Members

 Type  | Name | Value
------ | ---- | -----
Region | size | 2601
----


* Create streams in Spring XD

----
xd:>stream create stream1 --definition "trigger --fixedDelay=10 | http-client --url='''https://query.yahooapis.com/v1/public/yql?q=select * from yahoo.finance.quote where symbol in (\"MSFT\")&format=json&env=store://datatables.org/alltableswithkeys''' --httpMethod=GET | splitter --expression=#jsonPath(payload,'$.query.results.quote') | transform --script='file:/Users/fmelo/FinanceStream/transform.groovy'| gemfire-json-server --useLocator=true --host=localhost --port=10334 --regionName=Stocks --keyExpression=payload.getField('timestamp')" --deploy
Created and deployed new stream 'stream1'

xd:>stream create stream2 --definition "gemfire --regionName=Stocks --useLocator=true --host=localhost --port=10334 | shell --command='Rscript /Users/fmelo/FinanceStream/nn_evaluate_jordan.R' | log " --deploy
Created and deployed new stream 'stream2'
----

Stream 2 could also be done through a tap:

----
xd:>stream create stream2 --definition "tap:stream:stream1.transform > object-to-json | shell --command='Rscript /Users/fmelo/FinanceStream/nn_evaluate_jordan.R' | log " --deploy
----

* At each a few minutes, it's time to train the network using the script __nn_train_jordan.R__

That can be done through a stream in XD or even as a batch. For simplicity, let's use streams:

----
xd:>stream create trainstream --definition "trigger --fixedDelay=300 | shell --command='Rscript /Users/fmelo/FinanceStream/nn_train_jordan.R' | log " --deploy
----
