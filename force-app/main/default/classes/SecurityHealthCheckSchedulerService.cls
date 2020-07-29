global class SecurityHealthCheckSchedulerService {
  @InvocableMethod(label='Generate Security Health Check Data' description='Generate the health check data to be sent to the main org')
  global static void generateHealthCheckData() {
    try {
      SecurityHealthCheckService.generateHealthCheckData();
    } catch (Exception e) {
      System.debug('Exception occurred in scheduled service. ' + e.getMessage());
    }
  }
}
