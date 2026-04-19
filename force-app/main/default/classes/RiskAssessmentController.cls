public with sharing class RiskAssessmentController {

    @AuraEnabled(cacheable=true)
    public static Risk_Assessment__c getLatestAssessment(Id opportunityId) {
        List<Risk_Assessment__c> assessments = [
            SELECT Id, Name, Status__c, Risk_Score__c, Risk_Level__c,
                   Recommendation__c, Assessment_Date__c, Article_Count__c,
                   Negative_Signal_Count__c, External_Reference__c
            FROM Risk_Assessment__c
            WHERE Opportunity__c = :opportunityId
            ORDER BY CreatedDate DESC, Id DESC
            LIMIT 1
        ];
        return assessments.isEmpty() ? null : assessments[0];
    }

    @AuraEnabled
    public static Id requestManualAssessment(Id opportunityId) {
        if (!FeatureManagement.checkPermission('Can_Request_Manual_Assessment')) {
            throw new AuraHandledException('You do not have permission to request a manual assessment.');
        }

        Risk_Assessment__c assessment = new Risk_Assessment__c(
            Opportunity__c = opportunityId,
            Status__c = 'Pending'
        );
        insert assessment;

        RiskAssessmentQueueable.enqueue(opportunityId, assessment.Id);

        return assessment.Id;
    }

    @AuraEnabled(cacheable=true)
    public static Boolean hasManualAssessmentPermission() {
        return FeatureManagement.checkPermission('Can_Request_Manual_Assessment');
    }
}
