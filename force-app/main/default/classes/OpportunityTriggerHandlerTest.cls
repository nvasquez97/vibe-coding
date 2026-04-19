@IsTest
private class OpportunityTriggerHandlerTest {

    private class MockHttpSuccess implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"status":"ok","totalResults":1,"articles":[{"source":{"name":"Test"},"title":"Test article","description":"Positive news.","publishedAt":"2026-04-17T10:00:00Z"}]}');
            return res;
        }
    }

    @TestSetup
    static void setupData() {
        Account acc = new Account(Name = 'Trigger Test Account');
        insert acc;
    }

    @IsTest
    static void testAfterInsertCreatesAssessment() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Trigger Test Account' LIMIT 1];
        Test.setMock(HttpCalloutMock.class, new MockHttpSuccess());

        Test.startTest();
        Opportunity opp = new Opportunity(
            Name = 'Test Opp Insert',
            AccountId = acc.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            Amount = 10000
        );
        insert opp;
        Test.stopTest();

        List<Risk_Assessment__c> assessments = [
            SELECT Id, Status__c, Opportunity__c
            FROM Risk_Assessment__c
            WHERE Opportunity__c = :opp.Id
        ];
        Assert.isFalse(assessments.isEmpty(), 'Assessment should be created after Opportunity insert');
    }

    @IsTest
    static void testAfterUpdateAmountChangeCreatesAssessment() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Trigger Test Account' LIMIT 1];
        Test.setMock(HttpCalloutMock.class, new MockHttpSuccess());

        Test.startTest();
        Opportunity opp = new Opportunity(
            Name = 'Test Opp Update Amount',
            AccountId = acc.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            Amount = 5000
        );
        insert opp;
        Integer beforeCount = [SELECT COUNT() FROM Risk_Assessment__c WHERE Opportunity__c = :opp.Id];

        opp.Amount = 99999;
        update opp;
        Test.stopTest();

        Integer afterCount = [SELECT COUNT() FROM Risk_Assessment__c WHERE Opportunity__c = :opp.Id];
        Assert.isTrue(afterCount > beforeCount, 'Assessment should be created when Amount changes');
    }

    @IsTest
    static void testAfterUpdateStageChangeCreatesAssessment() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Trigger Test Account' LIMIT 1];
        Test.setMock(HttpCalloutMock.class, new MockHttpSuccess());

        Test.startTest();
        Opportunity opp = new Opportunity(
            Name = 'Test Opp Update Stage',
            AccountId = acc.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            Amount = 5000
        );
        insert opp;
        Integer beforeCount = [SELECT COUNT() FROM Risk_Assessment__c WHERE Opportunity__c = :opp.Id];

        opp.StageName = 'Qualification';
        update opp;
        Test.stopTest();

        Integer afterCount = [SELECT COUNT() FROM Risk_Assessment__c WHERE Opportunity__c = :opp.Id];
        Assert.isTrue(afterCount > beforeCount, 'Assessment should be created when StageName changes');
    }

    @IsTest
    static void testAfterUpdateNoChangeNoNewAssessment() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Trigger Test Account' LIMIT 1];
        Test.setMock(HttpCalloutMock.class, new MockHttpSuccess());

        Opportunity opp = new Opportunity(
            Name = 'Test Opp No Change',
            AccountId = acc.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            Amount = 5000
        );
        insert opp;

        Integer beforeCount = [SELECT COUNT() FROM Risk_Assessment__c WHERE Opportunity__c = :opp.Id];

        Test.startTest();
        opp.Description = 'Some non-triggering change';
        update opp;
        Test.stopTest();

        Integer afterCount = [SELECT COUNT() FROM Risk_Assessment__c WHERE Opportunity__c = :opp.Id];
        Assert.areEqual(beforeCount, afterCount, 'No new assessment when Amount and Stage unchanged');
    }
}
