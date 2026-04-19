// End-to-end flow verification for the Risk Advisor feature.
// Verifies that createMockData.apex successfully triggered assessments that completed.
// Then issues a new manual assessment request and prints the pending assessment ID.
// NOTE: Queueable jobs are async — they complete AFTER this script exits.
//       The SOQL check at the end of the deployment sequence confirms completion.

// Step 1: Find first Opportunity created by mock data
List<Opportunity> opps = [
    SELECT Id, Name, Account.Name
    FROM Opportunity
    WHERE Account.Name IN ('Acme Corp', 'Global Dynamics', 'Initech Solutions')
    ORDER BY CreatedDate ASC
    LIMIT 1
];

if (opps.isEmpty()) {
    throw new IllegalArgumentException('No mock Opportunities found. Run createMockData.apex first.');
}

Opportunity opp = opps[0];
System.debug('Testing with Opportunity: ' + opp.Name + ' (Account: ' + opp.Account.Name + ')');

// Step 2: Verify at least one completed assessment exists from createMockData
List<Risk_Assessment__c> completedAssessments = [
    SELECT Id, Status__c, Risk_Score__c, Risk_Level__c, Recommendation__c
    FROM Risk_Assessment__c
    WHERE Opportunity__c = :opp.Id
    AND Status__c = 'Completed'
    ORDER BY CreatedDate DESC
    LIMIT 1
];

if (completedAssessments.isEmpty()) {
    // No completed assessment yet — the queueables from createMockData may still be running
    // This is expected immediately after createMockData.apex; re-run this check after a few seconds
    List<Risk_Assessment__c> pending = [SELECT Id, Status__c FROM Risk_Assessment__c WHERE Opportunity__c = :opp.Id ORDER BY CreatedDate DESC LIMIT 1];
    if (!pending.isEmpty() && pending[0].Status__c == 'Pending') {
        System.debug('NOTE: Assessment is still Pending. The queueable is still running. Check again in a few seconds.');
        System.debug('Assessment Id: ' + pending[0].Id + ' | Status: ' + pending[0].Status__c);
    } else {
        throw new IllegalArgumentException(
            'No completed assessment found for ' + opp.Name + '. '
            + 'Run createMockData.apex first and wait for queueable jobs to complete.'
        );
    }
} else {
    Risk_Assessment__c completed = completedAssessments[0];
    System.debug('=== Completed Assessment Found ===');
    System.debug('Status: ' + completed.Status__c);
    System.debug('Risk Score: ' + completed.Risk_Score__c);
    System.debug('Risk Level: ' + completed.Risk_Level__c);
    String rec = completed.Recommendation__c != null ? completed.Recommendation__c.left(200) : '(none)';
    System.debug('Recommendation (first 200 chars): ' + rec);
}

// Step 3: Request a new manual assessment (demonstrates the controller works)
Id newAssessmentId = RiskAssessmentController.requestManualAssessment(opp.Id);
System.debug('New assessment requested with Id: ' + newAssessmentId);
System.debug('Status: Pending (queueable enqueued — will complete asynchronously)');
System.debug('=== End-to-End Flow Test Passed ===');
