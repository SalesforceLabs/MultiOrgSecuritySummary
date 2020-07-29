global with sharing class SecurityHealthCheckQueueable implements Queueable {
  public Id securityHealthCheckId;

  public SecurityHealthCheckQueueable(Id securityHealthCheckId) {
    this.securityHealthCheckId = securityHealthCheckId;
  }

  global void execute(QueueableContext context) {
    SecurityHealthCheckService.sendHealthCheckData(securityHealthCheckId);
  }
}
