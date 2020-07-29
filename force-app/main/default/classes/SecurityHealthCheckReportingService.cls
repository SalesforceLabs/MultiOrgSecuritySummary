@RestResource(urlMapping='/SecurityHealthCheckReporting/*')
global with sharing class SecurityHealthCheckReportingService {
  /**
   * The security health check reporting service is used to consume child org Security Health Check data into the
   * central org.
   *
   * This method exposes a rest endpoint that accepts an HttpPost request. The request must contain a JSON body
   * of the security health check records. It verifies that the data submitted matches the token designated for the
   * org in the Security Health Check Org Object.
   *
   * @return result
   */

  @HttpPost
  global static String createHealthCheckData() {
    String body = RestContext.request.requestBody.toString();
    SecurityHealthCheckService.HealthCheckPayload payload = (SecurityHealthCheckService.HealthCheckPayload) System.JSON.deserialize(body, SecurityHealthCheckService.HealthCheckPayload.class);

    String errorMsg = '';

    try {
      // Get the payload from the org that sent the request
      multioss__Security_Health_Check_Org__c org = payload.org.clone();

      errorMsg = org.multioss__Organization_Id__c + ' was set as the OrgId';

      multioss__Security_Health_Check_Org__c matchOrg = [
        SELECT Id, multioss__Token__c
        FROM multioss__Security_Health_Check_Org__c
        WHERE multioss__Actual_Org_Id__c = :org.multioss__Organization_Id__c
        WITH SECURITY_ENFORCED
      ];

      if (matchOrg == null) {
        return '{"outcome":"false", "error": "no match found" }';
      }

      // Check if token is valid (but also do not allow no token, else it will likely never be set)
      if (matchOrg.multioss__Token__c != '' && matchOrg.multioss__Token__c != org.multioss__Token__c) {
        return '{"outcome":"false", "error": "invalid token"}';
      }
      // To get here, the data is from a valid org

      multioss__Security_Health_Check__c shc = payload.healthCheck.clone();
      shc.multioss__Source__c = 'External';
      shc.multioss__Security_Health_Check_org__c = matchOrg.Id;

      List<SObject> newSHCList = new List<Sobject>();
      newSHCList.add(shc);
      SObjectAccessDecision sanitisedSHCList = security.stripInaccessible(AccessType.CREATABLE, newSHCList);

      insert sanitisedSHCList.getRecords();

      List<multioss__Security_Health_Check_Risk__c> risks = payload.risks;

      List<multioss__Security_Health_Check_Risk__c> newRisks = new List<multioss__Security_Health_Check_Risk__c>();
      for (multioss__Security_Health_Check_Risk__c risk : risks) {
        multioss__Security_Health_Check_Risk__c newRisk = risk.clone();
        newRisk.multioss__Security_Health_Check__c = sanitisedSHCList.getRecords()[0].Id;
        newRisks.add(newRisk);
      }

      SObjectAccessDecision sanitisedNewRisks = security.stripInaccessible(AccessType.CREATABLE, newRisks);

      insert sanitisedNewRisks.getRecords();

      // Update the Matched org to reflect the recent changes
      matchOrg.multioss__Last_Sync__c = System.now();
      matchOrg.multioss__Sync_Status__c = 'Active';
      matchOrg.multioss__Latest_Score__c = shc.multioss__Score__c;

      List<SObject> securityHealthCheckOrgsToUpdate = new List<Sobject>();
      securityHealthCheckOrgsToUpdate.add(matchOrg);
      SObjectAccessDecision sanitisedSecurityHealthCheckOrgs = security.stripInaccessible(AccessType.UPDATABLE, securityHealthCheckOrgsToUpdate);

      update sanitisedSecurityHealthCheckOrgs.getRecords();

      return '{"outcome":"true"}';
    } catch (Exception e) {
      System.debug('Exception:' + e.getMessage());
      errorMsg = 'Please contact the administrator for details'; //+= e.getMessage();
    }

    return '{"outcome":"false", "error" : ' + errorMsg + '}';
  }
}
