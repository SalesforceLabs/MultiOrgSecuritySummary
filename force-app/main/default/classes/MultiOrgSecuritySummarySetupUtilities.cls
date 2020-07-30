public with sharing class MultiOrgSecuritySummarySetupUtilities {
  /**
   * The setup utilities are used to manage scheduled jobs throughout the app. With these you can see the details
   * of a schedule job, schedule a job, or delete a scheduled job.
   */
  @AuraEnabled
  public static void runFirstSecurityJob() {
    SecurityHealthCheckService.generateHealthCheckData();
  }

  @AuraEnabled
  public static Datetime getCurrentDateTime() {
    return Datetime.now();
  }

  @AuraEnabled
  public static AsyncApexJob checkFirstSecurityJobStatus(Datetime submittedDatetime) {
    List<AsyncApexJob> asyncApexJobs = [
      SELECT Id, Status, ExtendedStatus
      FROM AsyncApexJob
      WHERE MethodName = 'sendHealthCheckData' AND CompletedDate >= :submittedDatetime
      WITH SECURITY_ENFORCED
      LIMIT 1
    ];
    AsyncApexJob asyncApexJob = (asyncApexJobs.size() == 1) ? asyncApexJobs.get(0) : null;

    if (asyncApexJob != null) {
      return asyncApexJob;
    }

    return null;
  }

  @AuraEnabled
  public static void deleteFalsePositiveHealthCheck() {
    List<Security_Health_Check__c> securityHealthChecks = [
      SELECT Id
      FROM Security_Health_Check__c
      WITH SECURITY_ENFORCED
      LIMIT 1
    ];
    if ((Security_Health_Check__c.sObjectType.getDescribe().isDeletable())) {
      Database.delete(securityHealthChecks, false);
    }
  }

  @AuraEnabled
  public static String getCurrentSecurityScheduleCron() {
    List<CronTrigger> cronTriggers = [
      SELECT Id, CronExpression
      FROM CronTrigger
      WHERE CronJobDetail.Name = 'SecurityHealthCheckApexScheduler'
      LIMIT 1
    ];
    CronTrigger cronTrigger = (cronTriggers.size() == 1) ? cronTriggers.get(0) : null;
    List<Security_Health_Check__c> securityHealthChecks = [
      SELECT Id
      FROM Security_Health_Check__c
      LIMIT 1
    ];
    Security_Health_Check__c securityHealthCheck = (securityHealthChecks.size() == 1)
      ? securityHealthChecks.get(0)
      : null;

    if (cronTrigger != null) {
      return cronTrigger.CronExpression;
    } else if (securityHealthCheck != null) {
      return 'schedule';
    } else {
      return 'first';
    }
  }

  @AuraEnabled
  public static Boolean scheduleSecuritySync(String cronString) {
    system.debug(cronString);

    try {
      SecurityHealthCheckApexScheduler scheduler = new SecurityHealthCheckApexScheduler();
      System.schedule('SecurityHealthCheckApexScheduler', cronString, scheduler);

      return true;
    } catch (Exception e) {
      System.debug(e.getMessage());

      return false;
    }
  }

  @AuraEnabled
  public static Boolean deleteScheduledJob() {
    try {
      List<CronTrigger> cronTriggers = [
        SELECT Id, CronExpression
        FROM CronTrigger
        WHERE CronJobDetail.Name = 'SecurityHealthCheckApexScheduler'
        LIMIT 1
      ];
      CronTrigger cronTrigger = (cronTriggers.size() == 1) ? cronTriggers.get(0) : null;

      System.abortJob(cronTrigger.Id);

      return true;
    } catch (Exception e) {
      System.debug(e.getMessage());

      return false;
    }
  }
}
