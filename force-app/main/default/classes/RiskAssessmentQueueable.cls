public class RiskAssessmentQueueable implements Queueable, Database.AllowsCallouts {

    private Id opportunityId;
    private Id pendingAssessmentId;

    public RiskAssessmentQueueable(Id oppId, Id assessmentId) {
        this.opportunityId = oppId;
        this.pendingAssessmentId = assessmentId;
    }

    public static void enqueue(Id oppId, Id assessmentId) {
        System.enqueueJob(new RiskAssessmentQueueable(oppId, assessmentId));
    }

    public void execute(QueueableContext ctx) {
        Risk_Assessment__c assessment = new Risk_Assessment__c(Id = pendingAssessmentId);
        try {
            Opportunity opp = [
                SELECT Id, Name, Account.Name
                FROM Opportunity
                WHERE Id = :opportunityId
                LIMIT 1
            ];

            String accountName = (opp.Account != null && String.isNotBlank(opp.Account.Name))
                ? opp.Account.Name
                : opp.Name;

            NewsAPICallout callout = new NewsAPICallout();
            List<NewsAPICallout.NewsArticle> articles = callout.fetchArticles(accountName);

            RiskScoringService.ScoringResult result = RiskScoringService.score(articles);

            assessment.Status__c            = 'Completed';
            assessment.Risk_Score__c        = result.score;
            assessment.Risk_Level__c        = result.level;
            assessment.Recommendation__c    = result.recommendation;
            assessment.Negative_Signal_Count__c = result.negativeSignals;
            assessment.Article_Count__c     = articles.size();
            assessment.Assessment_Date__c   = System.now();
            assessment.External_Reference__c = 'newsapi-' + String.valueOf(System.now().getTime());

        } catch (Exception e) {
            assessment.Status__c = 'Error';
            assessment.Recommendation__c = 'Error during assessment: ' + e.getMessage();
            assessment.Assessment_Date__c = System.now();
            System.debug('RiskAssessmentQueueable error: ' + e.getMessage() + '\n' + e.getStackTraceString());
        }

        update assessment;
    }
}
