/**
 * Created by stephan.garcia on 2020-04-27.
 */

global with sharing class SecurityHealthCheckApexScheduler implements Schedulable, Database.AllowsCallouts {
  global void execute(SchedulableContext context) {
    if (!Test.isRunningTest()) {
      SecurityHealthCheckService.generateHealthCheckData();
    }
  }
}
