public with sharing class RiskScoringService {

    private static final List<String> NEGATIVE_KEYWORDS = new List<String>{
        'lawsuit', 'fraud', 'bankruptcy', 'recall', 'fine',
        'penalty', 'loss', 'investigation', 'scandal', 'layoff', 'shutdown'
    };

    public class ScoringResult {
        public Integer score;
        public String  level;
        public String  recommendation;
        public Integer negativeSignals;
    }

    public static ScoringResult score(List<NewsAPICallout.NewsArticle> articles) {
        ScoringResult result = new ScoringResult();

        if (articles == null || articles.isEmpty()) {
            result.score = 0;
            result.negativeSignals = 0;
            result.level = 'Low';
            result.recommendation = 'No news articles found for this account.';
            return result;
        }

        Integer negativeCount = countNegativeSignals(articles);
        Integer riskScore = Math.min(100, negativeCount * 20);

        result.score = riskScore;
        result.negativeSignals = negativeCount;
        result.level = scoreToLevel(riskScore);
        result.recommendation = buildRecommendation(articles, result.level);

        return result;
    }

    private static String scoreToLevel(Integer score) {
        if (score >= 75) return 'Critical';
        if (score >= 50) return 'High';
        if (score >= 25) return 'Medium';
        return 'Low';
    }

    private static Integer countNegativeSignals(List<NewsAPICallout.NewsArticle> articles) {
        Integer count = 0;
        for (NewsAPICallout.NewsArticle article : articles) {
            String combined = '';
            if (article.title != null) combined += article.title.toLowerCase();
            if (article.description != null) combined += ' ' + article.description.toLowerCase();
            for (String keyword : NEGATIVE_KEYWORDS) {
                if (combined.contains(keyword)) {
                    count++;
                }
            }
        }
        return count;
    }

    private static String buildRecommendation(List<NewsAPICallout.NewsArticle> articles, String level) {
        List<String> headlines = new List<String>();
        for (NewsAPICallout.NewsArticle article : articles) {
            if (article.title != null) {
                headlines.add(article.title);
            }
        }
        String headlineSummary = String.join(headlines, ' | ');
        return 'Risk Level: ' + level + '. Recent headlines: ' + headlineSummary;
    }
}
