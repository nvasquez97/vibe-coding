public with sharing class NewsAPICallout {

    public interface IHttpCallout {
        HttpResponse send(HttpRequest req);
    }

    public class DefaultHttpCallout implements IHttpCallout {
        public HttpResponse send(HttpRequest req) {
            return new Http().send(req);
        }
    }

    public class NewsArticle {
        public String title;
        public String description;
        public String publishedAt;
        public String sourceName;
    }

    private static final String ENDPOINT = 'https://newsapi.org/v2/everything';
    private static final Integer TIMEOUT_MS = 10000;

    private IHttpCallout httpClient;
    private String apiKey;

    public NewsAPICallout() {
        this.httpClient = new DefaultHttpCallout();
        NewsAPI_Config__mdt config = NewsAPI_Config__mdt.getInstance('Default');
        this.apiKey = config != null ? config.API_Key__c : '';
    }

    public NewsAPICallout(IHttpCallout mockClient) {
        this.httpClient = mockClient;
        NewsAPI_Config__mdt config = NewsAPI_Config__mdt.getInstance('Default');
        this.apiKey = config != null ? config.API_Key__c : 'test-key';
    }

    public List<NewsArticle> fetchArticles(String accountName) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(buildEndpoint(accountName));
        req.setMethod('GET');
        req.setTimeout(TIMEOUT_MS);

        HttpResponse res = httpClient.send(req);

        if (res.getStatusCode() == 200) {
            return parseResponse(res.getBody());
        }
        return new List<NewsArticle>();
    }

    private String buildEndpoint(String accountName) {
        return ENDPOINT
            + '?q=' + EncodingUtil.urlEncode(accountName, 'UTF-8')
            + '&sortBy=publishedAt'
            + '&pageSize=5'
            + '&apiKey=' + this.apiKey;
    }

    private List<NewsArticle> parseResponse(String body) {
        List<NewsArticle> articles = new List<NewsArticle>();
        try {
            Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(body);
            List<Object> articleList = (List<Object>) response.get('articles');
            if (articleList != null) {
                for (Object articleObj : articleList) {
                    Map<String, Object> articleMap = (Map<String, Object>) articleObj;
                    NewsArticle article = new NewsArticle();
                    article.title = (String) articleMap.get('title');
                    article.description = (String) articleMap.get('description');
                    article.publishedAt = (String) articleMap.get('publishedAt');
                    Map<String, Object> source = (Map<String, Object>) articleMap.get('source');
                    if (source != null) {
                        article.sourceName = (String) source.get('name');
                    }
                    articles.add(article);
                }
            }
        } catch (Exception e) {
            System.debug('NewsAPICallout.parseResponse error: ' + e.getMessage());
        }
        return articles;
    }
}
