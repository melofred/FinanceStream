//print payload
if (!payload.containsKey("entryTimestamp")){
   if (payload.containsKey("timestamp")){
      payload.put("entryTimestamp", payload.get("timestamp"))
      payload.remove("timestamp")
   }
   else payload.put("entryTimestamp", System.nanoTime()) 
}
companyName=payload.get("Name")
if (companyName!=null && companyName.indexOf(",")!=-1) payload.put ("Name",companyName.replaceAll(",",""))
//payload.put("LastTradePriceOnly", (double) Math.round(payload.get("LastTradePriceOnly") * 100) / 100)
//payload.put("DaysHigh", (double) Math.round(payload.get("DaysHigh") * 100) / 100)
//payload.put("DaysLow", (double) Math.round(payload.get("DaysLow") * 100) / 100)


return payload
