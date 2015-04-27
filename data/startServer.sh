gfsh start server --name=server1 --J=-Dgemfire.start-dev-rest-api=true --J=-Dgemfire.http-service-port=8080 --locators=geode-locator[10334]
while true ; do
   sleep 2
done
