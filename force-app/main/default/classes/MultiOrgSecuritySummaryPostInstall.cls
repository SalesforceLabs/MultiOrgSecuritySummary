global class MultiOrgSecuritySummaryPostInstall implements InstallHandler {
  /**
   * Multi org security summary requires a number of skills to be added to the org - this static resource contains a
   * sample set of data to get teh users started.
   *
   * @param context - the context of the package install
   */
  global void onInstall(InstallContext context) {
    if (context.previousVersion() == null) {
      StaticResource someObjectStaticResource = [SELECT Body FROM StaticResource WHERE Name = 'securitySkills'];
      List<multioss__Security_Skill__c> securitySkills = (List<multioss__Security_Skill__c>) JSON.deserialize(someObjectStaticResource.Body.toString(), List<multioss__Security_Skill__c>.class);
      insert securitySkills;
    }
  }
}
