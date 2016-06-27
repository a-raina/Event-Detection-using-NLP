package eventdetection.downloader;

import eventdetection.common.Article;
import eventdetection.common.Source;

import java.io.IOException;
import java.io.BufferedInputStream;
import java.io.File;
import java.io.FileNotFoundException;
import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.PreparedStatement;
import java.util.List;
import java.util.ArrayList;
import java.util.Scanner;

/**
 * Created by laura on 2/1/16.
 */
public class TestDownloader extends Downloader {

    private Source testSource;

    public TestDownloader(Connection connection) {
        String statement = "SELECT * FROM sources WHERE source_name = 'TEST_SOURCE'";
        try {
            PreparedStatement stmt = connection.prepareStatement(statement);
            ResultSet rs = stmt.executeQuery();
            rs.next();
            int sourceId = rs.getInt("id");
            double sourceReliability = rs.getDouble("reliability");
            this.testSource = new Source(sourceId, "TEST_SOURCE", sourceReliability);
        } catch (SQLException e) {
            e.printStackTrace();
            System.exit(1);
        }

    }

    @Override
    public List<Article> get() {
        List<Article> articles = new ArrayList<Article>();
        Scanner scanner = new Scanner(new BufferedInputStream(System.in));

        System.out.print("Enter article title: ");
        String title = scanner.nextLine();

        System.out.print("Enter article url: ");
        String url = scanner.nextLine();

        System.out.print("Enter filename: ");
        String fileName = scanner.nextLine();
        String text = readFile(fileName);


        try {
            articles.add(new Article(title, text, url, testSource));
        } catch (IOException e) {
            e.printStackTrace();
        }

        scanner.close();

        return articles;
    }

    private String readFile(String fileName) {
        File file = new File(fileName);
        StringBuilder textBuilder = new StringBuilder();
        try {

            Scanner sc = new Scanner(file);

            while (sc.hasNextLine()) {
                String text = sc.nextLine();
                textBuilder.append(text);
            }
            sc.close();
        }
        catch (FileNotFoundException e) {
            e.printStackTrace();
        }
        return textBuilder.toString();
    }

    @Override
    public void close() throws IOException {

    }
}
