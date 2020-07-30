@isTest
public with sharing class SecurityHealthCheckGenerateOrgToken_Test {
  @TestSetup
  public static void createData() {
    MultiOrgSecuritySummary_TestFactory.setUpDefaultThisOrgData(Date.today());
  }

  @IsTest
  static void testGenerateOrgToken() {
    List<Security_Health_Check_Org__c> securityHealthCheckOrgs = [
      SELECT Id
      FROM Security_Health_Check_Org__c
      LIMIT 1
    ];

    Test.startTest();
    SecurityHealthCheckGenerateOrgToken.generateOrgToken(securityHealthCheckOrgs);
    Test.stopTest();

    List<Security_Health_Check_Org__c> updatedSecurityHealthCheckOrgs = [
      SELECT Id
      FROM Security_Health_Check_Org__c
      WHERE Token__c != NULL
      LIMIT 1
    ];

    system.assert(updatedSecurityHealthCheckOrgs.size() == 1, 'Token Was Not Set');
  }
}
