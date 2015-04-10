/**
 * @author wmarkito
 *         2015
 */

import com.gemstone.gemfire.cache.Region;
import com.gemstone.gemfire.cache.client.ClientCache;
import com.gemstone.gemfire.cache.client.ClientCacheFactory;
import javafx.animation.AnimationTimer;
import javafx.application.Application;
import javafx.scene.Scene;
import javafx.scene.chart.AreaChart;
import javafx.scene.chart.LineChart;
import javafx.scene.chart.NumberAxis;
import javafx.scene.chart.XYChart;
import javafx.stage.Stage;

import java.time.LocalDateTime;
import java.util.concurrent.ConcurrentLinkedQueue;


public class FinanceUI extends Application {

    private static final int MAX_DATA_POINTS = 50;
    private int xSeriesData = 0;
    private XYChart.Series stockPriceSeries;
    private XYChart.Series predictionSeries;

    public ConcurrentLinkedQueue<Number> stockDataQueue = new ConcurrentLinkedQueue<Number>();
    public  ConcurrentLinkedQueue<Number> predictionDataQueue = new ConcurrentLinkedQueue<Number>();

    public static FinanceUI instance;
    private final static String regionName = "Stocks";
    private static Region stocksRegion;
    private static final String fxTitle = "ApacheCon 2015 - SpringXD + Geode + R Example";

    private static ClientCache cache = new ClientCacheFactory()
            .set("name", "GemFireClient"+ LocalDateTime.now())
            .set("cache-xml-file", "client.xml")
            .create();

    private NumberAxis xAxis;

    public static void main(String[] args) {
        Region stocksRegion = cache.getRegion(regionName);
        stocksRegion.registerInterest("ALL_KEYS");

        launch(args);
    }

    private void init(Stage primaryStage) {
        instance = this;

        xAxis = new NumberAxis();
        xAxis.setForceZeroInRange(false);
        xAxis.setAutoRanging(true);

        xAxis.setTickLabelsVisible(false);
        xAxis.setTickMarkVisible(true);
        xAxis.setMinorTickVisible(false);

        NumberAxis yAxis = new NumberAxis();
        yAxis.setAutoRanging(true);

        //-- Chart
        final LineChart<Number, Number> sc = new LineChart<Number, Number>(xAxis, yAxis) {
            // Override to remove symbols on each data point
            @Override
            protected void dataItemAdded(Series<Number, Number> series, int itemIndex, Data<Number, Number> item) {
            }
        };
        sc.setAnimated(false);
        sc.setId("stockChart");
        sc.setTitle("Stock Price");

        //-- Chart Series
        stockPriceSeries = new XYChart.Series<Number, Number>();
        predictionSeries = new XYChart.Series<Number, Number>();

        sc.getData().addAll(stockPriceSeries, predictionSeries);

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
        for (int i = 0; i < 20; i++) { //-- add 20 numbers to the plot+
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

        // update
        xAxis.setLowerBound(xSeriesData - MAX_DATA_POINTS);
        xAxis.setUpperBound(xSeriesData - 1);
    }

}