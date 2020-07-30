public with sharing class SecurityHealthCheckGenerateOrgToken {
  /**
   * Using an invokable method - generate a unique integration token for each org in the parent. This uses a SHA-256
   * hash to write the org id and a 15 char string to a token.
   *
   * @param orgsToUpdate
   */

  @InvocableMethod(
    label='Generate Unique Org Token'
    description='Determines the default Entitlement for the Case and returns the updated Cases.'
  )
  public static void generateOrgToken(List<Security_Health_Check_Org__c> orgsToUpdate) {
    List<Security_Health_Check_Org__c> securityHealthCheckOrgs = [
      SELECT Id
      FROM Security_Health_Check_Org__c
      WHERE Id IN :new Map<Id, Security_Health_Check_Org__c>(orgsToUpdate).keySet()
    ];

    for (Security_Health_Check_Org__c securityHealthCheckOrg : securityHealthCheckOrgs) {
      String characters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxyz';
      String randomString = '';
      while (randomString.length() < 15) {
        Integer idx = Math.mod(Math.abs(Crypto.getRandomInteger()), characters.length());
        randomString += characters.substring(idx, idx + 1);
      }

      Blob orgId = Blob.valueOf(securityHealthCheckOrg.Id + randomString);
      Blob hash = Crypto.generateDigest('SHA-256', orgId);
      securityHealthCheckOrg.Token__c = EncodingUtil.base64Encode(hash);
      securityHealthCheckOrg.Refresh_Token__c = false;
    }

    update securityHealthCheckOrgs;
  }
}
