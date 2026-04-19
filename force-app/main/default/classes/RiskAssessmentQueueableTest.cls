@IsTest
private class RiskAssessmentQueueableTest {

    private class MockHttpSuccess implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"status":"ok","totalResults":2,"articles":['
                + '{"source":{"name":"Reuters"},"title":"Company reports solid growth","description":"Revenue increases 15%.","publishedAt":"2026-04-17T10:00:00Z"},'
                + '{"source":{"name":"Bloomberg"},"title":"New product launch success","description":"Market reception positive.","publishedAt":"2026-04-17T09:00:00Z"}'
                + ']}');
            return res;
        }
    }

    private class MockHttpFailure implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(500);
            res.setBody('{"status":"error","message":"Internal server error"}');
            return res;
        }
    }

    @TestSetup
    static void setupData() {
        Account acc = new Account(Name = 'Queueable Test Account');
        insert acc;
        Opportunity opp = new Opportunity(
            Name = 'Queueable Test Opp',
            AccountId = acc.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            Amount = 25000
        );
        insert opp;
    }

    @IsTest
    static void testQueueableCompletesSuccessfully() {
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Queueable Test Opp' LIMIT 1];
        Risk_Assessment__c assessment = new Risk_Assessment__c(
            Opportunity__c = opp.Id,
            Status__c = 'Pending'
        );
        insert assessment;

        Test.setMock(HttpCalloutMock.class, new MockHttpSuccess());

        Test.startTest();
        RiskAssessmentQueueable.enqueue(opp.Id, assessment.Id);
        Test.stopTest();

        assessment = [
            SELECT Id, Status__c, Risk_Score__c, Risk_Level__c, Article_Count__c
            FROM Risk_Assessment__c WHERE Id = :assessment.Id
        ];
        Assert.areEqual('Completed', assessment.Status__c, 'Assessment should be Completed');
        Assert.isNotNull(assessment.Risk_Score__c, 'Risk score should be set');
        Assert.isNotNull(assessment.Risk_Level__c, 'Risk level should be set');
        Assert.areEqual(2, (Integer)assessment.Article_Count__c, 'Article count should be 2');
    }

    @IsTest
    static void testQueueableHandlesApiError() {
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Queueable Test Opp' LIMIT 1];
        Risk_Assessment__c assessment = new Risk_Assessment__c(
            Opportunity__c = opp.Id,
            Status__c = 'Pending'
        );
        insert assessment;

        Test.setMock(HttpCalloutMock.class, new MockHttpFailure());

        Test.startTest();
        RiskAssessmentQueueable.enqueue(opp.Id, assessment.Id);
        Test.stopTest();

        assessment = [SELECT Id, Status__c FROM Risk_Assessment__c WHERE Id = :assessment.Id];
        Assert.areEqual('Completed', assessment.Status__c, 'Should be Completed (with 0 score when API returns non-200)');
    }
}
