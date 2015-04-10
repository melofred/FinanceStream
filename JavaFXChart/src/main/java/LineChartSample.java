/**
 * @author wmarkito
 *         2015
 */

import com.fasterxml.jackson.databind.ObjectMapper;
import javafx.application.Application;
import javafx.collections.FXCollections;
import javafx.collections.ObservableList;
import javafx.scene.Scene;
import javafx.scene.chart.CategoryAxis;
import javafx.scene.chart.LineChart;
import javafx.scene.chart.NumberAxis;
import javafx.scene.chart.XYChart;
import javafx.stage.Stage;
import org.springframework.http.ResponseEntity;
import org.springframework.web.client.RestTemplate;

import java.io.IOException;
import java.util.ArrayList;
import java.util.Collection;
import java.util.LinkedHashMap;

public class LineChartSample extends Application {
    final ObservableList<XYChart.Data<String, Number>> dataset = FXCollections.observableArrayList();

    public ObservableList<XYChart.Data<String, Number>> plot(Collection<LinkedHashMap> map) {
        for (LinkedHashMap entry: (Collection<LinkedHashMap>) map) {
            final XYChart.Data data = new XYChart.Data<>(String.valueOf(entry.get("timestamp")), entry.get("LastTradePriceOnly"));
            dataset.add(data);
        }

        return dataset;
    }

    @Override public void start(Stage stage) throws IOException, InterruptedException {

        stage.setTitle("ApacheCon 2015 - SpringXD + GemFire + R Example");
        final CategoryAxis xAxis = new CategoryAxis();
        final NumberAxis yAxis = new NumberAxis();
        xAxis.setLabel("Timestamp");
        xAxis.setAnimated(true);
        xAxis.setAutoRanging(true);
        final LineChart<String,Number> lineChart =
                new LineChart<String,Number>(xAxis,yAxis);

        lineChart.setAnimated(true);
        lineChart.setTitle("GemFire REST Stock Monitoring");

        RestTemplate restTemplate = new RestTemplate();

        ResponseEntity<String> result = restTemplate.getForEntity("http://localhost:9090/gemfire/queries/adhoc?q=SELECT DISTINCT * FROM /Stocks order by \"timestamp\" LIMIT 500", String.class);

        ObjectMapper mapper  = new ObjectMapper();

        ArrayList<LinkedHashMap> map = mapper.readValue(result.getBody(), ArrayList.class);

        XYChart.Series series1 = null;

        boolean setup = false;
        for(LinkedHashMap entry : map){

            System.out.println(entry);

//            for (LinkedHashMap entry: (Collection<LinkedHashMap>) s) {
                //Stocks stock = mapper.convertValue(entry, Stocks.class)
                //System.out.println(entry.get("AverageDailyVolume"));

                if (!setup) {
                    series1 = new XYChart.Series();
                    series1.setName((String) entry.get("symbol"));
                    setup = true;
                }

//              series1.getData().add(new XYChart.Data(String.valueOf(entry.get("timestamp")), ));

        }
        series1.setData(plot(map));


//        private int averageDailyVolume;
//        private double change, daysLow, daysHigh, yearLow, yearHigh;
//        private String marketCapitaliation;
//        private double lastTradePriceOnly;
//        private String daysRange, name;
//        private int volume;
//        private String stockExchange;
//        private long timestamp;

//        XYChart.Series series1 = new XYChart.Series();
//        series1.setName("Portfolio 1");
//
//        series1.getData().add(new XYChart.Data("Jan", 23));
//        series1.getData().add(new XYChart.Data("Feb", 14));
//        series1.getData().add(new XYChart.Data("Mar", 15));
//        series1.getData().add(new XYChart.Data("Apr", 24));
//        series1.getData().add(new XYChart.Data("May", 34));
//        series1.getData().add(new XYChart.Data("Jun", 36));
//        series1.getData().add(new XYChart.Data("Jul", 22));
//        series1.getData().add(new XYChart.Data("Aug", 45));
//        series1.getData().add(new XYChart.Data("Sep", 43));
//        series1.getData().add(new XYChart.Data("Oct", 17));
//        series1.getData().add(new XYChart.Data("Nov", 29));
//        series1.getData().add(new XYChart.Data("Dec", 25));

//        XYChart.Series series2 = new XYChart.Series();
//        series2.setName("Portfolio 2");
//        series2.getData().add(new XYChart.Data("Jan", 33));
//        series2.getData().add(new XYChart.Data("Feb", 34));
//        series2.getData().add(new XYChart.Data("Mar", 25));
//        series2.getData().add(new XYChart.Data("Apr", 44));
//        series2.getData().add(new XYChart.Data("May", 39));
//        series2.getData().add(new XYChart.Data("Jun", 16));
//        series2.getData().add(new XYChart.Data("Jul", 55));
//        series2.getData().add(new XYChart.Data("Aug", 54));
//        series2.getData().add(new XYChart.Data("Sep", 48));
//        series2.getData().add(new XYChart.Data("Oct", 27));
//        series2.getData().add(new XYChart.Data("Nov", 37));
//        series2.getData().add(new XYChart.Data("Dec", 29));
//
//        XYChart.Series series3 = new XYChart.Series();
//        series3.setName("Portfolio 3");
//        series3.getData().add(new XYChart.Data("Jan", 44));
//        series3.getData().add(new XYChart.Data("Feb", 35));
//        series3.getData().add(new XYChart.Data("Mar", 36));
//        series3.getData().add(new XYChart.Data("Apr", 33));
//        series3.getData().add(new XYChart.Data("May", 31));
//        series3.getData().add(new XYChart.Data("Jun", 26));
//        series3.getData().add(new XYChart.Data("Jul", 22));
//        series3.getData().add(new XYChart.Data("Aug", 25));
//        series3.getData().add(new XYChart.Data("Sep", 43));
//        series3.getData().add(new XYChart.Data("Oct", 44));
//        series3.getData().add(new XYChart.Data("Nov", 45));
//        series3.getData().add(new XYChart.Data("Dec", 44));

        Scene scene  = new Scene(lineChart,800,600);
        lineChart.getData().addAll(series1);
//        lineChart.getData().addAll(series1, series2, series3);

        stage.setScene(scene);
        stage.show();

    }


    public static void main(String[] args) {
        launch(args);
    }
}