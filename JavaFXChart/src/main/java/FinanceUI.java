/**
 * @author wmarkito
 *         2015
 */

import com.gemstone.gemfire.cache.Region;
import com.gemstone.gemfire.cache.client.ClientCache;
import com.gemstone.gemfire.cache.client.ClientCacheFactory;
import javafx.animation.AnimationTimer;
import javafx.application.Application;
import javafx.scene.Cursor;
import javafx.scene.Scene;
import javafx.scene.chart.AreaChart;
import javafx.scene.chart.LineChart;
import javafx.scene.chart.NumberAxis;
import javafx.scene.chart.XYChart;
import javafx.stage.Stage;

import java.io.File;
import java.time.LocalDateTime;
import java.util.concurrent.ConcurrentLinkedQueue;


public class FinanceUI extends Application {

    private static final int MAX_DATA_POINTS = 500;
    private int xSeriesData = 0;
    private XYChart.Series stockPriceSeries;
    private XYChart.Series predictionSeries;
    private ConcurrentLinkedQueue<Number> stockDataQueue = new ConcurrentLinkedQueue<Number>();
    private ConcurrentLinkedQueue<Number> timeQueue = new ConcurrentLinkedQueue<Number>();
    private ConcurrentLinkedQueue<Number> predictionDataQueue = new ConcurrentLinkedQueue<Number>();
    private static FinanceUI instance;
    private final static String regionName = "Predictions";
    private static Region stocksRegion;


    public ConcurrentLinkedQueue<Number> getPredictionDataQueue() {
        return predictionDataQueue;
    }

    public ConcurrentLinkedQueue<Number> getStockDataQueue() {
        return stockDataQueue;
    }

    public static FinanceUI getInstance() {
        return instance;
    }

    public static Region getStocksRegion() {
        return stocksRegion;
    }

    private static final String fxTitle = "ApacheCon 2015 - SpringXD + Geode + R Example";

    private static ClientCache cache = new ClientCacheFactory()
            .set("name", "GemFireClient"+ LocalDateTime.now())
            .set("cache-xml-file", "client.xml")
            .create();

    static NumberAxis xAxis;
    static NumberAxis yAxis;

    public static void main(String[] args) {
        stocksRegion = cache.getRegion(regionName);
        stocksRegion.registerInterest("ALL_KEYS");

        launch(args);
    }

    private void init(Stage primaryStage) {
        instance = this;

        xAxis = new NumberAxis();
        xAxis.setForceZeroInRange(false);
        xAxis.setAutoRanging(true);
        xAxis.setLabel("Time");

        xAxis.setTickLabelsVisible(false);
        xAxis.setTickMarkVisible(true);
        xAxis.setMinorTickVisible(false);

        yAxis = new NumberAxis();        
        yAxis.setAutoRanging(false);
        yAxis.setForceZeroInRange(false);
        yAxis.setLowerBound(210);
        yAxis.setUpperBound(225);
        
        yAxis.setLabel("Stock Price ($)");

        //-- Chart
        final LineChart<Number, Number> sc = new LineChart<Number, Number>(xAxis, yAxis) {
            // Override to remove symbols on each data point
            @Override
            protected void dataItemAdded(Series<Number, Number> series, int itemIndex, Data<Number, Number> item) {

            }
        };
        sc.setCursor(Cursor.CROSSHAIR);
        sc.setAnimated(false);
        sc.setId("stockChart");
//        sc.setTitle("Stock Price");


        //-- Chart Series
        stockPriceSeries = new XYChart.Series<Number, Number>();
        stockPriceSeries.setName("Last Close");
        predictionSeries = new XYChart.Series<Number, Number>();
        predictionSeries.setName("Prediction");

        sc.getData().addAll(stockPriceSeries, predictionSeries);
        sc.getStylesheets().add(new File("/Users/wmarkito/Pivotal/samples/JavaFXChart/src/main/resources/style.css").getAbsolutePath());
        sc.applyCss();
        primaryStage.setScene(new Scene(sc));
    }

    @Override
    public void start(Stage stage) {
        stage.setTitle(fxTitle);
        init(stage);
        stage.show();

        //-- Prepare Timeline
        prepareTimeline();
    }

    //-- Timeline gets called in the JavaFX Main thread
    private void prepareTimeline() {
        new AnimationTimer() {
            @Override
            public void handle(long now) {
                addDataToSeries();
            }
        }.start();
    }

    private void addDataToSeries() {
        for (int i = 0; i < 50; i++) {
            if (stockDataQueue.isEmpty()) break;
            stockPriceSeries.getData().add(new AreaChart.Data(xSeriesData++, stockDataQueue.remove()));
            predictionSeries.getData().add(new AreaChart.Data(xSeriesData++, predictionDataQueue.remove()));
//            series3.getData().add(new AreaChart.Data(xSeriesData++, dataQ3.remove()));
        }
        // remove points to keep us at no more than MAX_DATA_POINTS
        
        if (stockPriceSeries.getData().size() > MAX_DATA_POINTS) {
            stockPriceSeries.getData().remove(0, stockPriceSeries.getData().size() - MAX_DATA_POINTS);
        }
        if (predictionSeries.getData().size() > MAX_DATA_POINTS) {
            predictionSeries.getData().remove(0, predictionSeries.getData().size() - MAX_DATA_POINTS);
        }

        xAxis.setLowerBound(xSeriesData - MAX_DATA_POINTS);
        xAxis.setUpperBound(xSeriesData - 1);
           
        
    }
}