global with sharing class SecurityHealthCheckApexScheduler implements Schedulable, Database.AllowsCallouts {
  global void execute(SchedulableContext context) {
    if (!Test.isRunningTest()) {
      SecurityHealthCheckService.generateHealthCheckData();
    }
  }
}
