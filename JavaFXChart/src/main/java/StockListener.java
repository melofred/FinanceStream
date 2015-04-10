import com.gemstone.gemfire.cache.Declarable;
import com.gemstone.gemfire.cache.EntryEvent;
import com.gemstone.gemfire.cache.util.CacheListenerAdapter;
import com.gemstone.gemfire.pdx.internal.PdxInstanceImpl;

import java.util.Properties;

/**
 * @author wmarkito
 *         2015
 */
public class StockListener<K,V> extends CacheListenerAdapter<K, V> implements Declarable {

    @Override
    public void afterCreate(EntryEvent<K, V> e) {

        PdxInstanceImpl instance = (PdxInstanceImpl) e.getNewValue();

//        ObjectMapper mapper = new ObjectMapper();
//        mapper.readJSONFormatter.toJSON(instance);

        Double close = (double) instance.readField("LastTradePriceOnly");
        Double prediction = close + 1.5f;

        FinanceUI.instance.stockDataQueue.add((Number) close);
        FinanceUI.instance.predictionDataQueue.add((Number) prediction);
        System.out.println("    Received afterCreate event for entry: " + e.getKey() + ", " + e.getNewValue().getClass());
    }

    @Override
    public void afterUpdate(EntryEvent<K, V> e) {
        System.out.println("    Received afterUpdate event for entry: " + e.getKey() + ", " + e.getNewValue());
    }

    @Override
    public void afterDestroy(EntryEvent<K, V> e) {
        System.out.println("    Received afterDestroy event for entry: " + e.getKey());
    }

    @Override
    public void afterInvalidate(EntryEvent<K, V> e) {
        System.out.println("    Received afterInvalidate event for entry: " + e.getKey());
    }

    @Override
    public void init(Properties props) {
        // do nothing
    }
}