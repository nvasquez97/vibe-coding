@IsTest
private class NewsAPICalloutTest {

    private class MockHttpCallout implements NewsAPICallout.IHttpCallout {
        private Integer statusCode;
        private String body;

        public MockHttpCallout(Integer statusCode, String body) {
            this.statusCode = statusCode;
            this.body = body;
        }

        public HttpResponse send(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(statusCode);
            res.setBody(body);
            return res;
        }
    }

    private static String buildMockResponse(List<Map<String, String>> articles) {
        List<String> articleJsonList = new List<String>();
        for (Map<String, String> a : articles) {
            articleJsonList.add('{"source":{"name":"' + a.get('source') + '"},"title":"' + a.get('title') + '","description":"' + a.get('desc') + '","publishedAt":"2026-04-17T10:00:00Z"}');
        }
        return '{"status":"ok","totalResults":' + articles.size() + ',"articles":[' + String.join(articleJsonList, ',') + ']}';
    }

    @IsTest
    static void testFetchArticlesSuccess() {
        List<Map<String, String>> articles = new List<Map<String, String>>{
            new Map<String, String>{'source'=>'Reuters','title'=>'Acme Corp partners with TechCo','desc'=>'Expansion into new markets.'},
            new Map<String, String>{'source'=>'Bloomberg','title'=>'Acme Corp Q1 results beat expectations','desc'=>'Revenue up 20%.'}
        };
        String mockBody = buildMockResponse(articles);

        MockHttpCallout mockClient = new MockHttpCallout(200, mockBody);
        NewsAPICallout callout = new NewsAPICallout(mockClient);

        Test.startTest();
        List<NewsAPICallout.NewsArticle> result = callout.fetchArticles('Acme Corp');
        Test.stopTest();

        Assert.areEqual(2, result.size(), 'Should return 2 articles');
        Assert.areEqual('Acme Corp partners with TechCo', result[0].title);
        Assert.areEqual('Reuters', result[0].sourceName);
    }

    @IsTest
    static void testFetchArticlesNon200Response() {
        MockHttpCallout mockClient = new MockHttpCallout(401, '{"status":"error","message":"Unauthorized"}');
        NewsAPICallout callout = new NewsAPICallout(mockClient);

        Test.startTest();
        List<NewsAPICallout.NewsArticle> result = callout.fetchArticles('Test Account');
        Test.stopTest();

        Assert.isTrue(result.isEmpty(), 'Should return empty list on non-200 response');
    }

    @IsTest
    static void testFetchArticlesEmptyArticles() {
        MockHttpCallout mockClient = new MockHttpCallout(200, '{"status":"ok","totalResults":0,"articles":[]}');
        NewsAPICallout callout = new NewsAPICallout(mockClient);

        Test.startTest();
        List<NewsAPICallout.NewsArticle> result = callout.fetchArticles('Unknown Co');
        Test.stopTest();

        Assert.isTrue(result.isEmpty(), 'Should return empty list when no articles');
    }

    @IsTest
    static void testFetchArticlesMalformedResponse() {
        MockHttpCallout mockClient = new MockHttpCallout(200, 'not valid json {{');
        NewsAPICallout callout = new NewsAPICallout(mockClient);

        Test.startTest();
        List<NewsAPICallout.NewsArticle> result = callout.fetchArticles('Test');
        Test.stopTest();

        Assert.isTrue(result.isEmpty(), 'Should return empty list on parse error');
    }

    @IsTest
    static void testFetchArticlesNegativeKeywords() {
        List<Map<String, String>> articles = new List<Map<String, String>>{
            new Map<String, String>{'source'=>'FT','title'=>'GlobalDyn files for bankruptcy protection','desc'=>'The company faces massive losses.'},
            new Map<String, String>{'source'=>'WSJ','title'=>'GlobalDyn CEO faces fraud investigation','desc'=>'Regulators impose fine.'}
        };
        String mockBody = buildMockResponse(articles);

        MockHttpCallout mockClient = new MockHttpCallout(200, mockBody);
        NewsAPICallout callout = new NewsAPICallout(mockClient);

        Test.startTest();
        List<NewsAPICallout.NewsArticle> result = callout.fetchArticles('GlobalDyn');
        Test.stopTest();

        Assert.areEqual(2, result.size());
        RiskScoringService.ScoringResult score = RiskScoringService.score(result);
        Assert.isTrue(score.negativeSignals > 0, 'Should detect negative signals');
    }
}
