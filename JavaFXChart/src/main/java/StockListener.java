import com.gemstone.gemfire.cache.Declarable;
import com.gemstone.gemfire.cache.EntryEvent;
import com.gemstone.gemfire.cache.Region;
import com.gemstone.gemfire.cache.util.CacheListenerAdapter;
import com.gemstone.gemfire.pdx.internal.PdxInstanceImpl;

import java.util.Properties;
import java.util.logging.Logger;

/**
 * @author wmarkito
 */
public class StockListener<K,V> extends CacheListenerAdapter<K, V> implements Declarable {
	
    Logger logger = Logger.getAnonymousLogger();
    
    
    @Override
    public void afterCreate(EntryEvent<K, V> e) {
        try {
    
            PdxInstanceImpl instance = (PdxInstanceImpl) e.getNewValue();
            // reading fields from the event
            Double close = (double) instance.readField("close");
            Double prediction = (double)instance.readField("predictedPeak");;

            
            if (FinanceUI.getInstance() != null) {
                FinanceUI.getInstance().getStockDataQueue().add((Number) close);
                FinanceUI.getInstance().getPredictionDataQueue().add((Number) prediction);
            }
        } catch (Exception ex) {
            logger.severe("Problems parsing event for chart update:" + ex.getMessage());
        }

        logger.fine(String.format("Received afterCreate event for entry: %s, %s", e.getKey(), e.getNewValue().getClass()));
    }

    @Override
    public void init(Properties props) {
        // do nothing
    }
}