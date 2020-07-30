@isTest
public with sharing class MultiOrgSecuritySummarySetupUtils_Test {
  @isTest
  public static void testCheckFirstSecurityJobStatus_positive() {
    SecurityHealthCheckServiceMockFactory mock = new SecurityHealthCheckServiceMockFactory(
      200,
      'OK',
      'Success',
      new Map<String, String>()
    );
    Test.setMock(HttpCalloutMock.class, mock);
    Test.startTest();
    Datetime dateandtime = MultiOrgSecuritySummarySetupUtilities.getCurrentDateTime();
    SecurityHealthCheckApexScheduler scheduler = new SecurityHealthCheckApexScheduler();
    String cron = '0 0 23 * * ?';
    System.schedule('SecurityHealthCheckApexScheduler', cron, scheduler);
    MultiOrgSecuritySummarySetupUtilities.checkFirstSecurityJobStatus(dateandtime);
    Test.stopTest();

    List<CronTrigger> cronTriggers = [
      SELECT Id, CronExpression
      FROM CronTrigger
      WHERE CronJobDetail.Name = 'SecurityHealthCheckApexScheduler'
      LIMIT 1
    ];
    System.assert(cronTriggers.size() >= 1, 'Expecting a Schedule Batch Job');
  }

  @isTest
  public static void deleteFalsePositiveHealthCheck_positive() {
    Test.startTest();
    MultiOrgSecuritySummarySetupUtilities.deleteFalsePositiveHealthCheck();
    Test.stopTest();

    List<Security_Health_Check__c> securityHealthChecks = [
      SELECT Id
      FROM Security_Health_Check__c
      LIMIT 1
    ];
    Security_Health_Check__c securityHealthCheck = (securityHealthChecks.size() == 1)
      ? securityHealthChecks.get(0)
      : null;

    System.assert(securityHealthCheck == null, 'Record should have been deleted');
  }

  @isTest
  public static void testGetCurrentSecurityScheduleCron_positive() {
    SecurityHealthCheckServiceMockFactory mock = new SecurityHealthCheckServiceMockFactory(
      200,
      'OK',
      'Success',
      new Map<String, String>()
    );
    Test.setMock(HttpCalloutMock.class, mock);

    Test.startTest();
    SecurityHealthCheckApexScheduler scheduler = new SecurityHealthCheckApexScheduler();
    String cron = '0 0 23 * * ?';
    System.schedule('SecurityHealthCheckApexScheduler', cron, scheduler);
    MultiOrgSecuritySummarySetupUtilities.getCurrentSecurityScheduleCron();
    Test.stopTest();

    List<CronTrigger> cronTriggers = [
      SELECT Id, CronExpression
      FROM CronTrigger
      WHERE CronJobDetail.Name = 'SecurityHealthCheckApexScheduler'
      LIMIT 1
    ];
    System.assert(cronTriggers.size() >= 1, 'Expecting a Schedule Batch Job');
  }

  @isTest
  public static void testScheduleSecuritySync_positive() {
    SecurityHealthCheckServiceMockFactory mock = new SecurityHealthCheckServiceMockFactory(
      200,
      'OK',
      'Success',
      new Map<String, String>()
    );
    Test.setMock(HttpCalloutMock.class, mock);

    Test.startTest();
    String cron = '0 0 23 * * ?';
    MultiOrgSecuritySummarySetupUtilities.scheduleSecuritySync(cron);
    Test.stopTest();

    List<CronTrigger> cronTriggers = [
      SELECT Id, CronExpression
      FROM CronTrigger
      WHERE CronJobDetail.Name = 'SecurityHealthCheckApexScheduler'
      LIMIT 1
    ];
    System.assert(cronTriggers.size() >= 1, 'Expecting a Schedule Batch Job');
  }

  @isTest
  public static void testDeleteScheduledJob_positive() {
    SecurityHealthCheckServiceMockFactory mock = new SecurityHealthCheckServiceMockFactory(
      200,
      'OK',
      'Success',
      new Map<String, String>()
    );
    Test.setMock(HttpCalloutMock.class, mock);

    Test.startTest();
    SecurityHealthCheckApexScheduler scheduler = new SecurityHealthCheckApexScheduler();
    String cron = '0 0 23 * * ?';
    System.schedule('SecurityHealthCheckApexScheduler', cron, scheduler);
    MultiOrgSecuritySummarySetupUtilities.deleteScheduledJob();
    Test.stopTest();

    List<CronTrigger> cronTriggers = [
      SELECT Id, CronExpression
      FROM CronTrigger
      WHERE CronJobDetail.Name = 'SecurityHealthCheckApexScheduler'
      LIMIT 1
    ];
    CronTrigger cronTrigger = (cronTriggers.size() == 1) ? cronTriggers.get(0) : null;
    System.assert(cronTrigger == null, 'Job Should Be Deleted');
  }
}
