global with sharing class SecurityHealthCheckService {
  public class SecurityHealthCheckServiceException extends Exception {
  }

  private static String baseUrl = URL.getSalesforceBaseUrl().toExternalForm() + '/services/data/v48.0/tooling/query';
  //TODO - look at making this latest

  /**
   * The security health check service is used to generate the health check data from the Tooling API and write it
   * to the Salesforce org. It will generate the Security Health Check and the Security Health check Risk object Records.
   *
   * If successful, it will enqueue the data for sending through the security health check queueable.
   */

  @Future(Callout=true)
  public static void generateHealthCheckData() {
    // Get the Header information (i.e. the score)
    String securityHealthCheckUrl = baseUrl + '?q=' + 'Select CustomBaselineId, DurableId, Score from SecurityHealthCheck';
    String securityHealthCheckData = invokeSecurityEndpoint(securityHealthCheckUrl);

    // Get the Individual Risk records
    String securityHealthCheckRiskUrl =
      baseUrl +
      '?q=' +
      'Select DurableID, OrgValue, OrgValueRaw, RiskType, SecurityHealthCheckId, Setting, SettingGroup, SettingRiskCategory, StandardValue, StandardValueRaw from SecurityHealthCheckRisks';
    String riskData = invokeSecurityEndpoint(securityHealthCheckRiskUrl);

    // Finished Callouts, so can now create via DML statements
    String securityHealthCheckId = createSecurityHealthCheck(securityHealthCheckData);

    // Create the individual risk items
    createSecurityHealthCheckRisks(riskData, securityHealthCheckId);

    // finally update the header to mark as all risks loaded
    SecurityHealthCheckQueueable securityHealthCheckQueueable = new SecurityHealthCheckQueueable(securityHealthCheckId);

    Id jobId = System.enqueueJob(securityHealthCheckQueueable);
  }

  /* Inside the source org, Create the security health check top level record from the returned JSON data. */
  @TestVisible
  private static Id createSecurityHealthCheck(String data) {
    List<Organization> organizations = [SELECT Id FROM Organization WITH SECURITY_ENFORCED LIMIT 1];
    Organization organization = (organizations.size() == 1) ? organizations.get(0) : null;

    List<multioss__Security_Health_Check_Org__c> securityHealthCheckOrgs = [
      SELECT Id
      FROM multioss__Security_Health_Check_Org__c
      WHERE multioss__Actual_Org_Id__c = :organization.Id
      WITH SECURITY_ENFORCED
      LIMIT 1
    ];
    multioss__Security_Health_Check_Org__c securityHealthCheckOrg = (securityHealthCheckOrgs.size() == 1) ? securityHealthCheckOrgs.get(0) : null;

    SecurityHealthCheckJSONParser convertedData = SecurityHealthCheckJSONParser.parse(data);

    Id securityHealthCheckOrgId;

    if (securityHealthCheckOrgs == null) {
      SObject newSecurityHealthCheckOrg = createNewSecurityHealthCheckOrg(organization, Decimal.valueOf(convertedData.Records[0].Score));

      securityHealthCheckOrgId = newSecurityHealthCheckOrg.Id;
    } else {
      Decimal updatedScore = Decimal.valueOf(convertedData.Records[0].Score);

      updateSecurityHealthCheckOrg(organizations, updatedScore);
      securityHealthCheckOrgId = securityHealthCheckOrg.Id;
    }

    multioss__Security_Health_Check__c shc = new multioss__Security_Health_Check__c();
    shc.multioss__Check_Date__c = Date.today();
    shc.multioss__CustomBaselineId__c = convertedData.Records[0].CustomBaselineId;
    shc.multioss__DurableId__c = convertedData.Records[0].DurableId;
    shc.multioss__Score__c = Decimal.valueOf(convertedData.Records[0].Score);
    shc.multioss__Org_Name__c = UserInfo.getOrganizationName();
    shc.multioss__Org_Identifier__c = UserInfo.getOrganizationId();
    shc.multioss__Source__c = 'This';
    shc.multioss__Security_Health_Check_Org__c = securityHealthCheckOrgId;

    // Before Inserting, lookup the previous record and set the previous value
    List<multioss__Security_Health_Check__c> previousChecks = [
      SELECT Id, multioss__Score__c
      FROM multioss__Security_Health_Check__c
      WHERE multioss__Org_Identifier__c = :UserInfo.getOrganizationId()
      ORDER BY CreatedDate DESC
      LIMIT 1
    ];

    if (previousChecks.size() > 0) {
      shc.multioss__Previous_Score__c = previousChecks[0].multioss__Score__c;
    } else {
      shc.multioss__Previous_Score__c = shc.multioss__Score__c;
    }

    List<SObject> newSHCList = new List<SObject>();
    newSHCList.add(shc);
    SObjectAccessDecision sanitisedRecords = Security.stripInaccessible(AccessType.CREATABLE, newSHCList);

    insert sanitisedRecords.getRecords();

    return sanitisedRecords.getRecords()[0].Id;
  }

  public static SObject createNewSecurityHealthCheckOrg(Organization organization, Decimal latestScore) {
    multioss__Security_Health_Check_Org__c securityHealthCheckOrg = new multioss__Security_Health_Check_Org__c(
      Name = organization.Name,
      multioss__Organization_Id__c = organization.Id,
      multioss__Active__c = true,
      multioss__Refresh_Token__c = true,
      multioss__Sync_Status__c = 'Active',
      multioss__Last_Sync__c = System.now(),
      multioss__Latest_Score__c = latestScore
    );

    List<SObject> newSecurityHealthCheckOrgs = new List<SObject>();
    newSecurityHealthCheckOrgs.add(securityHealthCheckOrg);
    SObjectAccessDecision sanitisedRecords = Security.stripInaccessible(AccessType.CREATABLE, newSecurityHealthCheckOrgs);

    insert sanitisedRecords.getRecords();

    return sanitisedRecords.getRecords()[0];
  }

  public static void updateSecurityHealthCheckOrg(List<Organization> organizations, Decimal latestScore) {
    List<multioss__Security_Health_Check_Org__c> securityHealthCheckOrgs = [
      SELECT Id, multioss__Last_Sync__c, multioss__Latest_Score__c
      FROM multioss__Security_Health_Check_Org__c
      WHERE multioss__Actual_Org_Id__c = :organizations[0].Id
      WITH SECURITY_ENFORCED
    ];

    for (multioss__Security_Health_Check_Org__c healthCheckOrg : securityHealthCheckOrgs) {
      healthCheckOrg.multioss__Last_Sync__c = System.now();
      healthCheckOrg.multioss__Latest_Score__c = latestScore;
    }

    SObjectAccessDecision sanitisedRecords = Security.stripInaccessible(AccessType.UPDATABLE, securityHealthCheckOrgs);

    update sanitisedRecords.getRecords();
  }

  @TestVisible
  private static void createSecurityHealthCheckRisks(String data, Id securityHealthCheckId) {
    SecurityHealthCheckRiskJSONParser converteddata = SecurityHealthCheckRiskJSONParser.parse(data);

    List<multioss__Security_Health_Check_Risk__c> risks = new List<multioss__Security_Health_Check_Risk__c>();

    // Before Loading, lookup the previous record and get a list of ratings (RiskType) s to set as previous
    List<multioss__Security_Health_Check__c> previousChecks = [
      SELECT Id, multioss__Score__c
      FROM multioss__Security_Health_Check__c
      WHERE multioss__Org_Identifier__c = :UserInfo.getOrganizationId() AND multioss__All_Risks_Loaded__c = TRUE
      WITH SECURITY_ENFORCED
      ORDER BY CreatedDate DESC
      LIMIT 1
    ];
    Map<String, String> previousRiskScores = new Map<String, String>();

    if (previousChecks.size() > 0) {
      // Get the related risk scores
      List<multioss__Security_Health_Check_Risk__c> previousRisks = [
        SELECT Id, multioss__DurableId__c, multioss__RiskType__c
        FROM multioss__Security_Health_Check_Risk__c
        WHERE multioss__Security_Health_Check__c = :previousChecks[0].Id
        WITH SECURITY_ENFORCED
      ];

      for (multioss__Security_Health_Check_Risk__c risk : previousRisks) {
        previousRiskScores.put(risk.multioss__DurableId__c, risk.multioss__RiskType__c);
      }
    }
    for (SecurityHealthCheckRiskJSONParser.Records risk : converteddata.records) {
      multioss__Security_Health_Check_Risk__c shcr = new multioss__Security_Health_Check_Risk__c();

      shcr.multioss__Security_Health_Check__c = securityHealthCheckId;
      shcr.multioss__DurableId__c = risk.DurableId;
      shcr.multioss__OrgValue__c = risk.OrgValue;
      shcr.multioss__OrgValueRaw__c = risk.OrgValueRaw;
      shcr.multioss__RiskType__c = risk.RiskType;
      shcr.multioss__Setting__c = risk.Setting;
      // set the previous score
      if (previousRiskScores.containsKey(risk.DurableId)) {
        shcr.multioss__previous_Rating__C = previousRiskScores.get(risk.DurableId);
      } else {
        shcr.multioss__Previous_Rating__c = risk.RiskType;
      }
      shcr.multioss__SettingGroup__c = risk.SettingGroup;
      shcr.multioss__SettingRiskCategory__c = risk.SettingRiskCategory;
      shcr.multioss__StandardValue__c = risk.StandardValue;
      shcr.multioss__StandardValueRaw__c = risk.StandardValueRaw;

      risks.add(shcr);
    }

    SObjectAccessDecision sanitisedRecords = security.stripInaccessible(AccessType.CREATABLE, risks);

    insert sanitisedRecords.getRecords();
  }

  @TestVisible
  private static String invokeSecurityEndpoint(String url) {
    HTTPRequest req = new HTTPRequest();
    url = url.replace(' ', '+');
    req.setEndpoint(url);
    req.setMethod('GET');
    // OAuth header
    req.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionId());
    req.setHeader('Content-Type', 'application/json');

    Http h = new Http();
    HttpResponse res = h.send(req);

    // Check if worked
    if (res.getStatusCode() != 200) {
      throw new SecurityHealthCheckServiceException(res.getStatus());
    }
    return res.getBody();
  }

  @InvocableMethod(label='Send Health Check Data' description='Send the org health check data to the main org')
  public static void sendHealthCheckToCentralOrg(List<String> requests) {
    String securityHealthCheckId = requests[0];

    sendHealthCheckData(securityHealthCheckId);
  }

  /**
   * The sendHealthCheckData method is called by the queueable that we scheduled when the records were created
   * correctly. This is used to gather the config for the central org and post the data to the designated endpoint
   * using named credentials. If this IS the central org - the request is not sent.
   *
   * @param securityHealthCheckId
   */

  /* Send the data to the central endpoint */
  @Future(callout=true)
  public static void sendHealthCheckData(Id securityHealthCheckId) {
    HealthCheckPayload payload = new HealthCheckPayload();
    payload.healthCheck = getSecurityHealthCheckById(securityHealthCheckId);
    payload.risks = getSecurityHealthCheckRisks(securityHealthCheckId);

    multioss__Security_Health_Check_Org__c org = new multioss__Security_Health_Check_Org__c();
    org.Name = UserInfo.getOrganizationName();
    org.multioss__Organization_Id__c = UserInfo.getOrganizationId();

    Security_Health_Check_Config__mdt config = getSecurityHealthCheckConfig();

    if (config == null) {
      throw new SecurityHealthCheckServiceException('No Configuration Exists. Please define the custom meta data - Security Health Check Config');
    }

    if (config.multioss__Is_this_the_Central_org__c == true) {
    } else {
      org.multioss__Token__c = config.multioss__Token__c;
      payload.org = org;
      HTTPRequest req = new HTTPRequest();
      String url = 'callout:' + config.multioss__Named_Credentials__c + config.multioss__Central_Org_URL__c;
      req.setEndpoint(url);
      req.setMethod('POST');
      req.setHeader('Content-Type', 'application/json');
      req.setBody(JSON.serializePretty(payload));
      HttpResponse res;

      Http h = new Http();
      res = h.send(req);

      // Check if worked
      if (res.getStatusCode() != 200) {
        throw new SecurityHealthCheckServiceException(res.getStatus());
      } else if (res.getBody().contains('false')) {
        throw new SecurityHealthCheckServiceException(res.getBody());
      }
    }
  }

  /* Retrieve the custom metadata configuration */
  public static Security_Health_Check_Config__mdt getSecurityHealthCheckConfig() {
    if (!Test.isRunningTest()) {
      List<multioss__Security_Health_Check_Config__mdt> securityHealthCheckConfigs = [
        SELECT multioss__Central_Org_URL__c, multioss__Token__c, multioss__Security_Superstar_Threshold__c, multioss__Named_Credentials__c, multioss__Is_this_the_Central_org__c
        FROM Security_Health_Check_Config__mdt
        WHERE DeveloperName != 'Configuration'
        WITH SECURITY_ENFORCED
        LIMIT 1
      ];
      multioss__Security_Health_Check_Config__mdt securityHealthCheckConfig = (securityHealthCheckConfigs.size() == 1) ? securityHealthCheckConfigs.get(0) : null;

      if (securityHealthCheckConfig == null) {
        List<multioss__Security_Health_Check_Config__mdt> securityHealthCheckConfigsDefault = [
          SELECT multioss__Central_Org_URL__c, multioss__Token__c, multioss__Security_Superstar_Threshold__c, multioss__Named_Credentials__c, multioss__Is_this_the_Central_org__c
          FROM Security_Health_Check_Config__mdt
          WITH SECURITY_ENFORCED
          LIMIT 1
        ];
        securityHealthCheckConfig = (securityHealthCheckConfigsDefault.size() == 1) ? securityHealthCheckConfigsDefault.get(0) : null;
      }

      return securityHealthCheckConfig;
    } else {
      List<multioss__Security_Health_Check_Config__mdt> securityHealthCheckConfigsDefault = [
        SELECT multioss__Central_Org_URL__c, multioss__Token__c, multioss__Security_Superstar_Threshold__c, multioss__Named_Credentials__c, multioss__Is_this_the_Central_org__c
        FROM Security_Health_Check_Config__mdt
        WHERE DeveloperName = 'Configuration'
        WITH SECURITY_ENFORCED
        LIMIT 1
      ];
      multioss__Security_Health_Check_Config__mdt securityHealthCheckConfigTest = (securityHealthCheckConfigsDefault.size() == 1) ? securityHealthCheckConfigsDefault.get(0) : null;

      return securityHealthCheckConfigTest;
    }
  }

  public static multioss__Security_Health_Check__c getSecurityHealthCheckById(Id securityHealthCheckId) {
    return [
      SELECT
        Id,
        multioss__CustomBaselineId__c,
        multioss__DurableId__c,
        multioss__Score__c,
        multioss__Previous_Score__c,
        multioss__Check_Date__c,
        multioss__Org_Identifier__c,
        multioss__Org_Name__c,
        multioss__All_Risks_Loaded__c
      FROM multioss__Security_Health_Check__c
      WHERE Id = :securityHealthCheckId
      WITH SECURITY_ENFORCED
    ];
  }

  public static List<multioss__Security_Health_Check_Risk__c> getSecurityHealthCheckRisks(Id securityHealthCheckId) {
    return [
      SELECT
        Id,
        Name,
        multioss__DurableId__c,
        multioss__OrgValue__c,
        multioss__OrgValueRaw__c,
        multioss__RiskType__c,
        multioss__Previous_Rating__c,
        multioss__Security_Health_Check__c,
        multioss__Setting__c,
        multioss__SettingGroup__c,
        multioss__SettingRiskCategory__c,
        multioss__StandardValue__c,
        multioss__StandardValueRaw__c
      FROM multioss__Security_Health_Check_Risk__c
      WHERE multioss__Security_Health_Check__c = :securityHealthCheckId
      WITH SECURITY_ENFORCED
    ];
  }

  global class HealthCheckPayload {
    public multioss__Security_Health_Check_Org__c org { get; set; }
    public multioss__Security_Health_Check__c healthCheck { get; set; }
    public List<multioss__Security_Health_Check_Risk__c> risks { get; set; }
  }
}
