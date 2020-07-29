/**
 * Created by stephan.garcia on 2020-05-01.
 */
@isTest
public with sharing class MultiOrgSecuritySummaryPostInstall_Test {
  @isTest
  static void testInstallScript() {
    MultiOrgSecuritySummaryPostInstall postinstall = new MultiOrgSecuritySummaryPostInstall();
    Test.testInstall(postinstall, null);
    List<multioss__Security_Skill__c> securitySkills = [SELECT Id FROM multioss__Security_Skill__c LIMIT 1];
    System.assert(securitySkills.size() >= 1, 'Skill not found');
  }
}
