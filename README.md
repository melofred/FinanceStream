# Finance Stream app setup

##  Pre-requisites:
- GemFire 8.+ installed
- Spring XD 1.1+ installed
- R 3.1+ installed with the following packages
. RCurl
. quantmod
. TTR
. jsonlite
. RSNNS +

### Installation 

Install **R**: 

* Linux 
    ```
    su -c 'rpm -Uvh http://download.fedoraproject.org/pub/epel/6/i386/epel-release-6-8.noarch.rpm'
    sudo yum update
    sudo yum install R
    ```

* Mac OSX (homebrew)
```
 brew install R
```

* The **R** packages can be easily installed by typing at the R command line: 

```
> install.packages(c("RCurl","quantmod","TTR","jsonlite","RSNNS"))
```

### GemFire Setup

Execute the `setup.gfsh` script as follows:

```
gfsh run --file=setup.gfsh

1. Executing - start locator --name=locator1 --J=-Dgemfire.http-service-port=7575

.............................
Locator in FinanceStream/locator1 on 192.168.3.5[10334] as locator1 is currently online.
Process ID: 34681
Uptime: 15 seconds
...
Successfully connected to: [host=192.168.3.5, port=1099]

Cluster configuration service is up and running.

2. Executing - start server --name=server1 --J=-Dgemfire.start-dev-rest-api=true --J=-Dgemfire.http-service-port=8080

..........
Server in FinanceStream/server1 on 192.168.3.5[40404] as server1 is currently online.
Process ID: 34683
Uptime: 5 seconds
...

3. Executing - create region --name=/Stocks --type=PARTITION

Member  | Status
------- | -------------------------------------
server1 | Region "/Stocks" created on "server1"

4. Executing - import data --file=../Stocks.gfd --region=/Stocks --member=server1

Data imported from file : FinanceStream/Stocks.gfd on host : 192.168.3.5 to region : /Stocks

4. Executing - describe --region=/Stocks

Name            : Stocks
Data Policy     : partition
Hosting Members : server1

Non-Default Attributes Shared By Hosting Members

 Type  | Name | Value
------ | ---- | -----
Region | size | 2601
```

* Test the server REST endpoint

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

## Spring XD

### Create streams in Spring XD

```
xd:>stream create stream1 --definition "trigger --fixedDelay=10 | http-client --url='''https://query.yahooapis.com/v1/public/yql?q=select * from yahoo.finance.quote where symbol in (\"MSFT\")&format=json&env=store://datatables.org/alltableswithkeys''' --httpMethod=GET | splitter --expression=#jsonPath(payload,'$.query.results.quote') | transform --script='file:/Users/fmelo/FinanceStream/transform.groovy'| gemfire-json-server --useLocator=true --host=localhost --port=10334 --regionName=Stocks --keyExpression=payload.getField('timestamp')" --deploy
Created and deployed new stream 'stream1'

xd:>stream create stream2 --definition "gemfire --regionName=Stocks --useLocator=true --host=localhost --port=10334 | shell --command='Rscript /Users/fmelo/FinanceStream/nn_evaluate_jordan.R' | log " --deploy
Created and deployed new stream 'stream2'
```

* Stream 2 could also be done through a tap:

```
xd:>stream create stream2 --definition "tap:stream:stream1.transform > object-to-json | shell --command='Rscript /Users/fmelo/FinanceStream/nn_evaluate_jordan.R' | log " --deploy
```

* At each a few minutes, it's time to train the network using the script __nn_train_jordan.R__

That can be done through a stream in XD or even as a batch. For simplicity, let's use streams:

```
xd:>stream create trainstream --definition "trigger --fixedDelay=300 | shell --command='Rscript /Users/fmelo/FinanceStream/nn_train_jordan.R' | log " --deploy
```

## UI using D3

Open ui/index.html and check the graphs being updated...