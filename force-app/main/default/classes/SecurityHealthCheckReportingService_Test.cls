@isTest
global with sharing class SecurityHealthCheckReportingService_Test {
  @TestSetup
  public static void createData() {
    MultiOrgSecuritySummary_TestFactory.setUpDefaultThisOrgData(Date.today());
  }
  global class HealthCheckPayload {
    public Security_Health_Check_Org__c org { get; set; }
    public Security_Health_Check__c healthCheck { get; set; }
    public List<Security_Health_Check_Risk__c> risks { get; set; }
  }

  @isTest
  static void createHealthCheckData_negative() {
    Test.startTest();
    List<Security_Health_Check__c> securityHealthChecks = [
      SELECT Id
      FROM Security_Health_Check__c
      LIMIT 1
    ];
    Security_Health_Check__c securityHealthCheck = (securityHealthChecks.size() == 1)
      ? securityHealthChecks.get(0)
      : null;

    HealthCheckPayload payload = new HealthCheckPayload();
    payload.healthCheck = SecurityHealthCheckService.getSecurityHealthCheckById(
      securityHealthCheck.Id
    );
    payload.risks = SecurityHealthCheckService.getSecurityHealthCheckRisks(securityHealthCheck.Id);

    Security_Health_Check_Org__c org = new Security_Health_Check_Org__c();
    org.Name = UserInfo.getOrganizationName();
    org.Organization_Id__c = '1536';
    Security_Health_Check_Config__mdt config = SecurityHealthCheckService.getSecurityHealthCheckConfig();
    org.Token__c = config.Token__c;
    payload.org = org;

    RestRequest request = new RestRequest();
    request.requestUri = '/services/apexrest/SecurityHealthCheckReporting/';
    request.httpMethod = 'POST';
    request.requestBody = Blob.valueOf(JSON.serialize(payload));
    RestResponse response = new RestResponse();
    RestContext.request = request;
    RestContext.response = response;

    String responseString = SecurityHealthCheckReportingService.createHealthCheckData();

    Test.stopTest();

    system.assertEquals(
      '{"outcome":"false", "error" : Please contact the administrator for details}',
      responseString
    );
  }

  @isTest
  static void createHealthCheckData_positive() {
    List<Security_Health_Check__c> securityHealthChecks = [
      SELECT Id
      FROM Security_Health_Check__c
      LIMIT 1
    ];
    Security_Health_Check__c securityHealthCheck = (securityHealthChecks.size() == 1)
      ? securityHealthChecks.get(0)
      : null;
    HealthCheckPayload payload = new HealthCheckPayload();
    payload.healthCheck = SecurityHealthCheckService.getSecurityHealthCheckById(
      securityHealthCheck.Id
    );
    payload.risks = SecurityHealthCheckService.getSecurityHealthCheckRisks(securityHealthCheck.Id);
    Security_Health_Check_Org__c org = new Security_Health_Check_Org__c();
    org.Name = UserInfo.getOrganizationName();
    org.Organization_Id__c = UserInfo.getOrganizationId();
    Security_Health_Check_Config__mdt config = SecurityHealthCheckService.getSecurityHealthCheckConfig();
    org.Token__c = '12345678';
    payload.org = org;

    Test.startTest();
    RestRequest request = new RestRequest();
    request.requestUri = '/services/apexrest/SecurityHealthCheckReporting/';
    request.httpMethod = 'POST';
    request.requestBody = Blob.valueOf(JSON.serialize(payload));
    RestResponse response = new RestResponse();
    RestContext.request = request;
    RestContext.response = response;

    String responseString = SecurityHealthCheckReportingService.createHealthCheckData();

    Test.stopTest();

    system.assertEquals('{"outcome":"true"}', responseString);
  }
}
