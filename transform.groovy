if (!payload.containsKey("timestamp")){
   payload.put("timestamp", System.nanoTime()) 
}
return payload
