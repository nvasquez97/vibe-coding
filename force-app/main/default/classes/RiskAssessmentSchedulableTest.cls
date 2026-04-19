@IsTest
private class RiskAssessmentSchedulableTest {

    private class MockHttpSuccess implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"status":"ok","totalResults":1,"articles":[{"source":{"name":"Test"},"title":"Positive news","description":"Good outlook.","publishedAt":"2026-04-17T10:00:00Z"}]}');
            return res;
        }
    }

    @TestSetup
    static void setupData() {
        Account acc = new Account(Name = 'Schedulable Test Account');
        insert acc;
        List<Opportunity> opps = new List<Opportunity>();
        for (Integer i = 0; i < 3; i++) {
            opps.add(new Opportunity(
                Name = 'Schedulable Test Opp ' + i,
                AccountId = acc.Id,
                StageName = 'Prospecting',
                CloseDate = Date.today().addDays(30),
                Amount = 1000 * (i + 1)
            ));
        }
        insert opps;
    }

    @IsTest
    static void testSchedulableExecuteCreatesAssessments() {
        List<Opportunity> opps = [SELECT Id FROM Opportunity WHERE Name LIKE 'Schedulable Test Opp%'];
        Test.setMock(HttpCalloutMock.class, new MockHttpSuccess());

        Integer beforeCount = [SELECT COUNT() FROM Risk_Assessment__c WHERE Opportunity__c IN :opps];

        Test.startTest();
        RiskAssessmentSchedulable schedulable = new RiskAssessmentSchedulable();
        schedulable.execute(null);
        Test.stopTest();

        Integer afterCount = [SELECT COUNT() FROM Risk_Assessment__c WHERE Opportunity__c IN :opps];
        Assert.isTrue(afterCount > beforeCount, 'Schedulable should create new assessments for open opportunities');
    }

    @IsTest
    static void testScheduleNightly() {
        Test.startTest();
        RiskAssessmentSchedulable.scheduleNightly();
        Test.stopTest();

        List<CronTrigger> jobs = [
            SELECT Id, CronExpression, State
            FROM CronTrigger
            WHERE CronJobDetail.Name = :RiskAssessmentSchedulable.JOB_NAME
        ];
        Assert.isFalse(jobs.isEmpty(), 'Scheduled job should exist');
        Assert.areEqual(RiskAssessmentSchedulable.DEFAULT_CRON, jobs[0].CronExpression);
    }

    @IsTest
    static void testScheduleNightlyReplacesExisting() {
        Test.startTest();
        RiskAssessmentSchedulable.scheduleNightly();
        RiskAssessmentSchedulable.scheduleNightly();
        Test.stopTest();

        List<CronTrigger> jobs = [
            SELECT Id FROM CronTrigger
            WHERE CronJobDetail.Name = :RiskAssessmentSchedulable.JOB_NAME
            AND State NOT IN ('DELETED', 'COMPLETE', 'ERROR')
        ];
        Assert.areEqual(1, jobs.size(), 'Only one scheduled job should exist');
    }

    @IsTest
    static void testSchedulableConstants() {
        Assert.areEqual('0 0 2 * * ?', RiskAssessmentSchedulable.DEFAULT_CRON);
        Assert.areEqual('Nightly Risk Assessment', RiskAssessmentSchedulable.JOB_NAME);
    }
}
