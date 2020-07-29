/**
 * Created by stephan.garcia on 2020-04-30.
 */
@isTest
public with sharing class SecurityHealthCheckQueueable_Test {
  @TestSetup
  public static void createData() {
    MultiOrgSecuritySummary_TestFactory.setUpDefaultThisOrgData(Date.today());
  }

  @isTest
  static void securityHealthCheckQueueable_Tests() {
    List<multioss__Security_Health_Check__c> securityHealthChecks = [SELECT Id FROM multioss__Security_Health_Check__c LIMIT 1];
    multioss__Security_Health_Check__c securityHealthCheck = (securityHealthChecks.size() == 1) ? securityHealthChecks.get(0) : null;

    SecurityHealthCheckServiceMockFactory mock = new SecurityHealthCheckServiceMockFactory(200, 'OK', 'success', new Map<String, String>());
    Test.setMock(HttpCalloutMock.class, mock);

    Test.startTest();
    SecurityHealthCheckQueueable queueable = new SecurityHealthCheckQueueable(securityHealthCheck.Id);
    System.enqueueJob(queueable);
    Test.stopTest();

    List<AsyncApexJob> scheduledJobs = [SELECT Id, JobType FROM AsyncApexJob WHERE JobType = 'Queueable'];
    System.assert(scheduledJobs.size() == 1, 'Expected a Queueable AsyncApexJob');
  }
}
