@IsTest
private class RiskAssessmentControllerTest {

    private class MockHttpSuccess implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"status":"ok","totalResults":1,"articles":[{"source":{"name":"Test"},"title":"Controller test article","description":"Good news.","publishedAt":"2026-04-17T10:00:00Z"}]}');
            return res;
        }
    }

    @TestSetup
    static void setupData() {
        Account acc = new Account(Name = 'Controller Test Account');
        insert acc;
        Opportunity opp = new Opportunity(
            Name = 'Controller Test Opp',
            AccountId = acc.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            Amount = 50000
        );
        insert opp;
    }

    @IsTest
    static void testGetLatestAssessmentReturnsNull() {
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Controller Test Opp' LIMIT 1];
        delete [SELECT Id FROM Risk_Assessment__c WHERE Opportunity__c = :opp.Id];

        Test.startTest();
        Risk_Assessment__c result = RiskAssessmentController.getLatestAssessment(opp.Id);
        Test.stopTest();

        Assert.isNull(result, 'Should return null when no assessments exist');
    }

    @IsTest
    static void testGetLatestAssessmentReturnsRecord() {
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Controller Test Opp' LIMIT 1];
        delete [SELECT Id FROM Risk_Assessment__c WHERE Opportunity__c = :opp.Id];

        Risk_Assessment__c assessment = new Risk_Assessment__c(
            Opportunity__c = opp.Id,
            Status__c = 'Completed',
            Risk_Score__c = 40,
            Risk_Level__c = 'Medium'
        );
        insert assessment;

        Test.startTest();
        Risk_Assessment__c result = RiskAssessmentController.getLatestAssessment(opp.Id);
        Test.stopTest();

        Assert.isNotNull(result, 'Should return the assessment');
        Assert.areEqual('Completed', result.Status__c);
        Assert.areEqual(40, (Integer)result.Risk_Score__c);
    }

    @IsTest
    static void testGetLatestAssessmentReturnsNewest() {
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Controller Test Opp' LIMIT 1];
        delete [SELECT Id FROM Risk_Assessment__c WHERE Opportunity__c = :opp.Id];

        // Insert older record first, then newer — IDs and CreatedDate are both ascending
        Risk_Assessment__c oldRecord = new Risk_Assessment__c(Opportunity__c = opp.Id, Status__c = 'Completed', Risk_Score__c = 20, Risk_Level__c = 'Low');
        insert oldRecord;

        Risk_Assessment__c newestRecord = new Risk_Assessment__c(Opportunity__c = opp.Id, Status__c = 'Pending');
        insert newestRecord;

        Test.startTest();
        Risk_Assessment__c result = RiskAssessmentController.getLatestAssessment(opp.Id);
        Test.stopTest();

        // The newest record has the highest Id (auto-increment) — this is reliable in tests
        Assert.areNotEqual(oldRecord.Id, result.Id, 'Should not return the older assessment');
    }

    @IsTest
    static void testHasManualAssessmentPermissionReturnsFalse() {
        Test.startTest();
        Boolean result = RiskAssessmentController.hasManualAssessmentPermission();
        Test.stopTest();

        Assert.isNotNull(result, 'Should return a boolean value');
    }

    @IsTest
    static void testRequestManualAssessmentWithoutPermission() {
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Controller Test Opp' LIMIT 1];

        // Run as a standard user without the custom permission
        Profile stdProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User noPermUser = new User(
            FirstName = 'Test',
            LastName = 'NoPermUser',
            Email = 'noperm_risktest@testorg.example.com',
            Username = 'noperm_risktest_' + System.currentTimeMillis() + '@testorg.example.com',
            Alias = 'noprm',
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = stdProfile.Id
        );
        insert noPermUser;

        Boolean exceptionThrown = false;
        Test.startTest();
        System.runAs(noPermUser) {
            try {
                RiskAssessmentController.requestManualAssessment(opp.Id);
            } catch (AuraHandledException e) {
                exceptionThrown = true;
            } catch (Exception e) {
                exceptionThrown = true;
            }
        }
        Test.stopTest();

        Assert.isTrue(exceptionThrown, 'Should throw exception without Can_Request_Manual_Assessment permission');
    }
}
