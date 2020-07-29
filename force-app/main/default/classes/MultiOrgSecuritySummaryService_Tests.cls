/**
 * Created by apaterson on 18/04/2020.
 */

@IsTest
private class MultiOrgSecuritySummaryService_Tests {
  @TestSetup
  public static void createData() {
    MultiOrgSecuritySummary_TestFactory.setUpDefaultThisOrgData(Date.today());
  }
  private static String securityHealthCheckJSON = '{"size" : 1, "totalSize" : 1, "done" : true, "queryLocator" : null, "entityTypeName" : "SecurityHealthCheck", "records" : [ {"attributes" : {"type" : "SecurityHealthCheck", "url" : "/services/data/v47.0/tooling/sobjects/SecurityHealthCheck/0"}, "CustomBaselineId" : "0", "DurableId" : "0","Score" : "61"}]}';
  private static String securityHealthCheckRisksJSON = '{"size" : 37,"totalSize" : 37,"done" : true,"queryLocator" : null,"entityTypeName" : "SecurityHealthCheckRisks","records" : [ {"attributes" : {"type" : "SecurityHealthCheckRisks","url" : "/services/data/v47.0/tooling/sobjects/SecurityHealthCheckRisks/SessionSettings.enableSmsIdentity"}, "DurableId" : "SessionSettings.enableSmsIdentity", "OrgValue" : "Disabled", "OrgValueRaw" : "false", "RiskType" : "HIGH_RISK", "SecurityHealthCheckId" : null, "Setting" : "Let users verify their identity by text (SMS)", "SettingGroup" : "SessionSettings","SettingRiskCategory" : "HIGH_RISK", "StandardValue" : "Enabled", "StandardValueRaw" : "true"}, {"attributes" : {"type" : "SecurityHealthCheckRisks", "url" : "/services/data/v47.0/tooling/sobjects/SecurityHealthCheckRisks/SessionSettings.clickjackVisualForceHeaders"}, "DurableId" : "SessionSettings.clickjackVisualForceHeaders", "OrgValue" : "Disabled", "OrgValueRaw" : "false","RiskType" : "HIGH_RISK", "SecurityHealthCheckId" : null, "Setting" : "Enable clickjack protection for customer Visualforce pages with standard headers", "SettingGroup" : "SessionSettings", "SettingRiskCategory" : "HIGH_RISK", "StandardValue" : "Enabled", "StandardValueRaw" : "true"}, {"attributes" : {"type" : "SecurityHealthCheckRisks", "url" : "/services/data/v47.0/tooling/sobjects/SecurityHealthCheckRisks/SessionSettings.clickjackVisualForceNoHeaders"}, "DurableId" : "SessionSettings.clickjackVisualForceNoHeaders", "OrgValue" : "Disabled", "OrgValueRaw" : "false", "RiskType" : "HIGH_RISK", "SecurityHealthCheckId" : null, "Setting" : "Enable clickjack protection for customer Visualforce pages with headers disabled","SettingGroup" : "SessionSettings", "SettingRiskCategory" : "HIGH_RISK", "StandardValue" : "Enabled", "StandardValueRaw" : "true"}, {"attributes" : {"type" : "SecurityHealthCheckRisks", "url" : "/services/data/v47.0/tooling/sobjects/SecurityHealthCheckRisks/SessionSettings.requireHttpOnly"}, "DurableId" : "SessionSettings.requireHttpOnly", "OrgValue" : "Disabled","OrgValueRaw" : "false", "RiskType" : "HIGH_RISK", "SecurityHealthCheckId" : null, "Setting" : "Require HttpOnly attribute", "SettingGroup" : "SessionSettings","SettingRiskCategory" : "HIGH_RISK", "StandardValue" : "Enabled", "StandardValueRaw" : "true"}]}';

  @IsTest
  static void testGetSummaries() {
    Test.startTest();
    // Get the summaries bydate
    MultiOrgSecuritySummaryService.MultiOrgSummaries summary1 = MultiOrgSecuritySummaryService.getSummaries('bydate', Date.today(), '123456789012345', 30);

    //  (String format, Date theDate, String orgId, Integer maxRows)
    // Get the summaries byorg
    MultiOrgSecuritySummaryService.MultiOrgSummaries summary2 = MultiOrgSecuritySummaryService.getSummaries('byorg', Date.today(), '123456789012345', 30);

    Test.stopTest();

    System.assert(summary1.mode == 'bydate', 'Summary format set incorrectly');
    System.assert(summary2.mode == 'byorg', 'Summary format set incorrectly');
  }

  @IsTest
  static void testSecurityHealthCheckJSONParser() {
    //String json = '{"size" : 1, "totalSize" : 1, "done" : true, "queryLocator" : null, "entityTypeName" : "SecurityHealthCheck", "records" : [ {"attributes" : {"type" : "SecurityHealthCheck", "url" : "/services/data/v47.0/tooling/sobjects/SecurityHealthCheck/0"}, "CustomBaselineId" : "0", "DurableId" : "0","Score" : "61"}]}';
    Test.startTest();
    SecurityHealthCheckJSONParser result = SecurityHealthCheckJSONParser.parse(securityHealthCheckJSON);
    Test.stopTest();
    //   String json2 = '{"size" : 1, "totalSize" : 1, "done" : true, "queryLocator" : "[]", "entityTypeName" : "SecurityHealthCheck", "records" : [ {"attributes" : {"type" : "SecurityHealthCheck", "url" : "/services/data/v47.0/tooling/sobjects/SecurityHealthCheck/0"}, "CustomBaselineId" : "0", "DurableId" : "0","Score" : "61"}]}';
    //   SecurityHealthCheckJSONParser parse2 = SecurityHealthCheckJSONParser.parse(json2);

    System.assert(result.size == 1, 'Summary parsed incorrectly');
  }

  @IsTest
  static void testSecurityHealthCheckRiskJSONParser() {
    Test.startTest();
    SecurityHealthCheckRiskJSONParser result = SecurityHealthCheckRiskJSONParser.parse(securityHealthCheckRisksJSON);
    Test.stopTest();

    System.assert(result.size == 37, 'Risks parsed incorrectly');
  }

  @isTest
  static void createSecurityHealthCheckRisks_positive() {
    Test.startTest();

    List<multioss__Security_Health_Check_Org__c> securityHealthCheckOrgs = [SELECT Id FROM multioss__Security_Health_Check_Org__c LIMIT 1];
    multioss__Security_Health_Check_Org__c securityHealthCheckOrg = (securityHealthCheckOrgs.size() == 1) ? securityHealthCheckOrgs.get(0) : null;

    Map<String, Object> results = MultiOrgSecuritySummaryService.getCurrentOrgDetails(securityHealthCheckOrg.Id);

    Test.stopTest();

    System.assert(results.get('Active') == true, 'Data not Found');
  }

  @isTest
  static void getCurrentOrgConfigurationDetails_positive() {
    Test.startTest();

    Map<String, Object> results = MultiOrgSecuritySummaryService.getCurrentOrgConfigurationDetails();

    Test.stopTest();

    System.assert(results.get('LocalDate') == Date.today(), 'Data not set');
  }

  @isTest
  static void getSecurityAdminDetails_positive() {
    Id userId = UserInfo.getUserId();

    Test.startTest();

    Map<String, Object> results = MultiOrgSecuritySummaryService.getSecurityAdminDetails(userId);

    Test.stopTest();

    System.assert(results.get('Points') == 10, 'Data not set');
  }

  @isTest
  static void getAdminSkillsToManage() {
    Id userId = UserInfo.getUserId();

    Test.startTest();

    List<Map<String, Object>> results = MultiOrgSecuritySummaryService.getAdminSkillsToManage(userId, 'test');

    Test.stopTest();

    System.assert(results.size() >= 1, 'Data not set');
  }

  @isTest
  static void getSecurityCheckByOrgWithId_positive() {
    Test.startTest();

    List<MultiOrgSecuritySummaryService.DailyOrgSummary> results = MultiOrgSecuritySummaryService.getSecurityCheckByOrg('', 10);

    Test.stopTest();

    System.assertEquals(10, results.size(), 'Data not set');
  }

  @isTest
  static void getSecurityCheckByOrgWithout_positive() {
    List<multioss__Security_Health_Check_Org__c> securityHealthCheckOrgs = [SELECT Id FROM multioss__Security_Health_Check_Org__c LIMIT 1];
    multioss__Security_Health_Check_Org__c securityHealthCheckOrg = (securityHealthCheckOrgs.size() == 1) ? securityHealthCheckOrgs.get(0) : null;
    Test.startTest();

    List<MultiOrgSecuritySummaryService.DailyOrgSummary> results = MultiOrgSecuritySummaryService.getSecurityCheckByOrg(securityHealthCheckOrg.Id, 10);

    Test.stopTest();

    System.assertEquals(10, results.size(), 'Data not set');
  }
}
