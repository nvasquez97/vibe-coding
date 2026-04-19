// Verifies that the NewsAPI callout is correctly wired with the API key
// and returns real articles. Requires internet access from the org.

NewsAPICallout callout = new NewsAPICallout();
List<NewsAPICallout.NewsArticle> articles = callout.fetchArticles('Apple');

if (articles == null || articles.isEmpty()) {
    throw new IllegalArgumentException(
        'NewsAPI callout returned 0 articles. '
        + 'Verify the API key in NewsAPI_Config__mdt.Default and that NewsAPI Remote Site Setting is active.'
    );
}

System.debug('=== NewsAPI Callout Verification Passed ===');
System.debug('Articles returned: ' + articles.size());
System.debug('First article title: ' + articles[0].title);
System.debug('First article source: ' + articles[0].sourceName);
System.debug('First article date: ' + articles[0].publishedAt);
