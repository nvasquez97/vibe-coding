@IsTest
private class RiskScoringServiceTest {

    private static NewsAPICallout.NewsArticle makeArticle(String title, String description) {
        NewsAPICallout.NewsArticle a = new NewsAPICallout.NewsArticle();
        a.title = title;
        a.description = description;
        a.publishedAt = '2026-04-17T10:00:00Z';
        a.sourceName = 'TestSource';
        return a;
    }

    @IsTest
    static void testLowRiskScore() {
        List<NewsAPICallout.NewsArticle> articles = new List<NewsAPICallout.NewsArticle>{
            makeArticle('Company launches new product', 'Innovation in tech sector.'),
            makeArticle('CEO presents at conference', 'Strong outlook for next quarter.')
        };

        Test.startTest();
        RiskScoringService.ScoringResult result = RiskScoringService.score(articles);
        Test.stopTest();

        Assert.areEqual('Low', result.level, 'Should be Low risk');
        Assert.isTrue(result.score < 25, 'Score should be below 25');
        Assert.areEqual(0, result.negativeSignals, 'No negative signals expected');
    }

    @IsTest
    static void testMediumRiskScore() {
        List<NewsAPICallout.NewsArticle> articles = new List<NewsAPICallout.NewsArticle>{
            makeArticle('Company faces lawsuit over patent', 'Legal dispute ongoing.'),
            makeArticle('Quarterly loss reported', 'Financial challenges cited.')
        };

        Test.startTest();
        RiskScoringService.ScoringResult result = RiskScoringService.score(articles);
        Test.stopTest();

        Assert.isTrue(result.score >= 25 && result.score < 50, 'Score should be in Medium range (25-49), got: ' + result.score);
        Assert.areEqual('Medium', result.level, 'Should be Medium risk');
    }

    @IsTest
    static void testHighRiskScore() {
        List<NewsAPICallout.NewsArticle> articles = new List<NewsAPICallout.NewsArticle>{
            makeArticle('Fraud investigation launched', 'Regulatory fine imposed.'),
            makeArticle('Bankruptcy filing expected', 'Massive loss reported.'),
            makeArticle('Product recall announced', 'Safety penalty issued.')
        };

        Test.startTest();
        RiskScoringService.ScoringResult result = RiskScoringService.score(articles);
        Test.stopTest();

        Assert.isTrue(result.score >= 50, 'Score should be >= 50 for High/Critical, got: ' + result.score);
        Assert.isTrue(result.level == 'High' || result.level == 'Critical', 'Should be High or Critical');
    }

    @IsTest
    static void testCriticalRiskScore() {
        List<NewsAPICallout.NewsArticle> articles = new List<NewsAPICallout.NewsArticle>{
            makeArticle('Bankruptcy lawsuit fraud scandal', 'Layoff investigation fine.'),
            makeArticle('Recall penalty loss layoff scandal', 'Major investigation bankruptcy.'),
            makeArticle('Fraud fine penalty recall', 'Investigation lawsuit layoff.'),
            makeArticle('Loss scandal bankruptcy fraud', 'Fine penalty investigation.'),
            makeArticle('Layoff investigation recall fraud', 'Penalty loss lawsuit scandal.')
        };

        Test.startTest();
        RiskScoringService.ScoringResult result = RiskScoringService.score(articles);
        Test.stopTest();

        Assert.areEqual(100, result.score, 'Score should be capped at 100');
        Assert.areEqual('Critical', result.level, 'Should be Critical');
    }

    @IsTest
    static void testEmptyArticles() {
        Test.startTest();
        RiskScoringService.ScoringResult result = RiskScoringService.score(new List<NewsAPICallout.NewsArticle>());
        Test.stopTest();

        Assert.areEqual(0, result.score, 'Empty articles should give 0 score');
        Assert.areEqual('Low', result.level, 'Empty articles should give Low level');
    }

    @IsTest
    static void testNullArticles() {
        Test.startTest();
        RiskScoringService.ScoringResult result = RiskScoringService.score(null);
        Test.stopTest();

        Assert.areEqual(0, result.score, 'Null articles should give 0 score');
        Assert.areEqual('Low', result.level);
    }

    @IsTest
    static void testRecommendationContainsHeadlines() {
        List<NewsAPICallout.NewsArticle> articles = new List<NewsAPICallout.NewsArticle>{
            makeArticle('Test Headline One', 'Some description.')
        };

        Test.startTest();
        RiskScoringService.ScoringResult result = RiskScoringService.score(articles);
        Test.stopTest();

        Assert.isTrue(result.recommendation.contains('Test Headline One'), 'Recommendation should contain headlines');
    }
}
