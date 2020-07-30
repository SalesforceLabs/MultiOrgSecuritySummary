@isTest
public with sharing class SecurityHealthCheckService_Test {
  @TestSetup
  public static void createData() {
    MultiOrgSecuritySummary_TestFactory.setUpDefaultThisOrgData(Date.today());
  }

  public static String securityHealthCheckJSON = '{"size" : 1, "totalSize" : 1, "done" : true, "queryLocator" : null, "entityTypeName" : "SecurityHealthCheck", "records" : [ {"attributes" : {"type" : "SecurityHealthCheck", "url" : "/services/data/v47.0/tooling/sobjects/SecurityHealthCheck/0"}, "CustomBaselineId" : "0", "DurableId" : "0","Score" : "61"}]}';
  public static String securityHealthCheckRisksJSON = '{"size" : 37,"totalSize" : 37,"done" : true,"queryLocator" : null,"entityTypeName" : "SecurityHealthCheckRisks","records" : [ {"attributes" : {"type" : "SecurityHealthCheckRisks","url" : "/services/data/v47.0/tooling/sobjects/SecurityHealthCheckRisks/SessionSettings.enableSmsIdentity"}, "DurableId" : "SessionSettings.enableSmsIdentity", "OrgValue" : "Disabled", "OrgValueRaw" : "false", "RiskType" : "HIGH_RISK", "SecurityHealthCheckId" : null, "Setting" : "Let users verify their identity by text (SMS)", "SettingGroup" : "SessionSettings","SettingRiskCategory" : "HIGH_RISK", "StandardValue" : "Enabled", "StandardValueRaw" : "true"}, {"attributes" : {"type" : "SecurityHealthCheckRisks", "url" : "/services/data/v47.0/tooling/sobjects/SecurityHealthCheckRisks/SessionSettings.clickjackVisualForceHeaders"}, "DurableId" : "SessionSettings.clickjackVisualForceHeaders", "OrgValue" : "Disabled", "OrgValueRaw" : "false","RiskType" : "HIGH_RISK", "SecurityHealthCheckId" : null, "Setting" : "Enable clickjack protection for customer Visualforce pages with standard headers", "SettingGroup" : "SessionSettings", "SettingRiskCategory" : "HIGH_RISK", "StandardValue" : "Enabled", "StandardValueRaw" : "true"}, {"attributes" : {"type" : "SecurityHealthCheckRisks", "url" : "/services/data/v47.0/tooling/sobjects/SecurityHealthCheckRisks/SessionSettings.clickjackVisualForceNoHeaders"}, "DurableId" : "SessionSettings.clickjackVisualForceNoHeaders", "OrgValue" : "Disabled", "OrgValueRaw" : "false", "RiskType" : "HIGH_RISK", "SecurityHealthCheckId" : null, "Setting" : "Enable clickjack protection for customer Visualforce pages with headers disabled","SettingGroup" : "SessionSettings", "SettingRiskCategory" : "HIGH_RISK", "StandardValue" : "Enabled", "StandardValueRaw" : "true"}, {"attributes" : {"type" : "SecurityHealthCheckRisks", "url" : "/services/data/v47.0/tooling/sobjects/SecurityHealthCheckRisks/SessionSettings.requireHttpOnly"}, "DurableId" : "SessionSettings.requireHttpOnly", "OrgValue" : "Disabled","OrgValueRaw" : "false", "RiskType" : "HIGH_RISK", "SecurityHealthCheckId" : null, "Setting" : "Require HttpOnly attribute", "SettingGroup" : "SessionSettings","SettingRiskCategory" : "HIGH_RISK", "StandardValue" : "Enabled", "StandardValueRaw" : "true"}]}';
  public static String baseUrl =
    URL.getSalesforceBaseUrl().toExternalForm() + '/services/data/v48.0/tooling/query';

  @isTest
  static void invokeSecurityEndpoint_positive() {
    SecurityHealthCheckServiceMockFactory mock = new SecurityHealthCheckServiceMockFactory(
      200,
      'OK',
      securityHealthCheckJSON,
      new Map<String, String>()
    );
    Test.setMock(HttpCalloutMock.class, mock);

    Test.startTest();
    String securityHealthCheckUrl =
      baseUrl +
      '?q=' +
      'Select CustomBaselineId, DurableId, Score from SecurityHealthCheck';
    String response = SecurityHealthCheckService.invokeSecurityEndpoint(securityHealthCheckUrl);

    Test.stopTest();

    system.assertEquals(securityHealthCheckJSON, response);
  }

  @isTest
  static void createNewSecurityHealthCheckOrg_positive() {
    List<Organization> organizations = [SELECT Id, Name FROM Organization LIMIT 1];
    Organization organization = (organizations.size() == 1) ? organizations.get(0) : null;
    Test.startTest();
    SObject response = SecurityHealthCheckService.createNewSecurityHealthCheckOrg(organization, 10);
    Test.stopTest();

    List<Security_Health_Check_Org__c> securityHealthCheckOrgs = [
      SELECT Id
      FROM Security_Health_Check_Org__c
      WHERE Actual_Org_Id__c = :organization.Id
      LIMIT 1
    ];

    system.assertEquals(1, securityHealthCheckOrgs.size());
  }

  @isTest
  static void sendHealthCheckData_positive() {
    SecurityHealthCheckServiceMockFactory mock = new SecurityHealthCheckServiceMockFactory(
      200,
      'OK',
      'Success',
      new Map<String, String>()
    );

    List<Security_Health_Check__c> securityHealthChecks = [
      SELECT Id
      FROM Security_Health_Check__c
      LIMIT 1
    ];
    Security_Health_Check__c securityHealthCheck = (securityHealthChecks.size() == 1)
      ? securityHealthChecks.get(0)
      : null;
    Test.setMock(HttpCalloutMock.class, mock);

    Integer calloutsBefore = Limits.getCallouts();

    Test.startTest();
    SecurityHealthCheckService.sendHealthCheckData(securityHealthCheck.Id);
    Test.stopTest();

    System.assertEquals(calloutsBefore, Limits.getCallouts());
  }

  @isTest
  static void createSecurityHealthCheck_positive() {
    Test.startTest();

    Id securityHealthCheckId = SecurityHealthCheckService.createSecurityHealthCheck(
      securityHealthCheckJSON
    );

    Test.stopTest();

    List<Security_Health_Check__c> securityHealthChecks = [
      SELECT Id
      FROM Security_Health_Check__c
      WHERE Id = :securityHealthCheckId
      LIMIT 1
    ];

    System.assert(securityHealthChecks.size() >= 1, 'Callout was not run');
  }

  @isTest
  static void createSecurityHealthCheckRisks_positive() {
    String securityHealthCheckId = SecurityHealthCheckService.createSecurityHealthCheck(
      securityHealthCheckJSON
    );

    Test.startTest();

    SecurityHealthCheckService.createSecurityHealthCheckRisks(
      securityHealthCheckRisksJSON,
      securityHealthCheckId
    );

    Test.stopTest();

    List<Security_Health_Check_Risk__c> securityHealthCheckRisks = [
      SELECT Id
      FROM Security_Health_Check_Risk__c
      LIMIT 1
    ];

    System.assert(securityHealthCheckRisks.size() == 1, 'Records were not inserted');
  }
}
