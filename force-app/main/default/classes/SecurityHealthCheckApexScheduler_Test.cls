/**
 * Created by stephan.garcia on 2020-04-27.
 */
@isTest
public with sharing class SecurityHealthCheckApexScheduler_Test {
  @isTest
  public static void testSchedulerService() {
    SecurityHealthCheckServiceMockFactory mock = new SecurityHealthCheckServiceMockFactory(200, 'OK', 'Success', new Map<String, String>());
    Test.setMock(HttpCalloutMock.class, mock);

    Test.startTest();
    SecurityHealthCheckApexScheduler scheduler = new SecurityHealthCheckApexScheduler();
    String chron = '0 0 23 * * ?';
    System.schedule('Security Health Check Test Scheduler', chron, scheduler);
    Test.stopTest();

    List<AsyncApexJob> scheduledJobs = [SELECT Id FROM AsyncApexJob WHERE JobType = 'ScheduledApex'];
    System.assert(scheduledJobs.size() >= 1, 'Expecting a Schedule Batch Job');
  }
}
