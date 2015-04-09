package io.pivotal.fstream;

import io.pivotal.fstream.StockPrice;

import java.util.logging.Logger;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.CommandLineRunner;
import org.springframework.context.annotation.ComponentScan;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.client.RestTemplate;

@ComponentScan
@Configuration
public class Simulator implements CommandLineRunner {

	@Value("${serverUrl}") 
	private String URL;
	
	@Value("${numberOfMessages}") 
	private int numberOfMessages;

	@Value("${basePrice}") 
	private double basePrice;

	@Value("${scale}") 
	private double scale;

	private RestTemplate restTemplate = new RestTemplate();
	
	Logger logger = Logger.getLogger(Simulator.class.getName());

	@Override
	public void run(String... args) throws Exception {
		

		logger.info("--------------------------------------");
		logger.info(">>> URL: "+URL);
		logger.info(">>> Number of messages: "+numberOfMessages);
		logger.info(">>> Base Price: "+basePrice);
		logger.info(">>> Scale: "+scale);
		logger.info("--------------------------------------");
		
		double low = basePrice - scale;
		double high = basePrice + scale;

		logger.info(">>> Posting "+numberOfMessages+" messages ranging from "+low+" to "+high+" ...");

		
		for( int i=0; i < numberOfMessages; i++ ){
			double value = ( basePrice - Math.sin( Math.toRadians(i) ) * scale );

			StockPrice price = new StockPrice();
			price.setSymbol("MSFT");
			price.setPrice(value);
			price.setLow(low);
			price.setHigh(high);
			
			StockPrice response = restTemplate.postForObject(URL, price, StockPrice.class);
			
		}		
		
		logger.info("done");
		
		
	}

}