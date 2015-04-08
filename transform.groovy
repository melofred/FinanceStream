if (!payload.containsKey("timestamp")){
   payload.put("timestamp", System.nanoTime()) 
}
companyName=payload.get("Name")
if (companyName.indexOf(",")!=-1) payload.put ("Name",companyName.replaceAll(",",""))


return payload
