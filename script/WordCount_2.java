import java.util.Arrays;
import org.apache.spark.SparkConf;
import org.apache.spark.api.java.JavaPairRDD;
import org.apache.spark.api.java.JavaRDD;
import org.apache.spark.api.java.JavaSparkContext;
import scala.Tuple2;

public class WordCoun_2 {
    public static void main(String[] args) {
        // 1. Setup
        String inputFile = args[0];
        // We won't save to file to keep it simple, we will just print time
        SparkConf conf = new SparkConf().setAppName("WordCountBatch");
        JavaSparkContext sc = new JavaSparkContext(conf);

        long t1 = System.currentTimeMillis();

        // 2. Logic
        JavaRDD<String> data = sc.textFile(inputFile);
        long count = data.flatMap(s -> Arrays.asList(s.split(" ")).iterator())
                         .count(); // Just count total words to force execution

        long t2 = System.currentTimeMillis();

        // 3. Results
        System.out.println("======================");
        System.out.println("TOTAL WORDS: " + count);
        System.out.println("TIME TAKEN: " + (t2 - t1) + " ms");
        System.out.println("======================");
        
        sc.stop();
    }
}