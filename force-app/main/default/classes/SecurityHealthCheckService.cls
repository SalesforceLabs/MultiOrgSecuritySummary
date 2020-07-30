global with sharing class SecurityHealthCheckService {
  public class SecurityHealthCheckServiceException extends Exception {
  }

  private static String baseUrl =
    URL.getSalesforceBaseUrl().toExternalForm() + '/services/data/v48.0/tooling/query';
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
    String securityHealthCheckUrl =
      baseUrl +
      '?q=' +
      'Select CustomBaselineId, DurableId, Score from SecurityHealthCheck';
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
    SecurityHealthCheckQueueable securityHealthCheckQueueable = new SecurityHealthCheckQueueable(
      securityHealthCheckId
    );

    Id jobId = System.enqueueJob(securityHealthCheckQueueable);
  }

  /* Inside the source org, Create the security health check top level record from the returned JSON data. */
  @TestVisible
  private static Id createSecurityHealthCheck(String data) {
    List<Organization> organizations = [SELECT Id FROM Organization WITH SECURITY_ENFORCED LIMIT 1];
    Organization organization = (organizations.size() == 1) ? organizations.get(0) : null;

    List<Security_Health_Check_Org__c> securityHealthCheckOrgs = [
      SELECT Id
      FROM Security_Health_Check_Org__c
      WHERE Actual_Org_Id__c = :organization.Id
      WITH SECURITY_ENFORCED
      LIMIT 1
    ];
    Security_Health_Check_Org__c securityHealthCheckOrg = (securityHealthCheckOrgs.size() == 1)
      ? securityHealthCheckOrgs.get(0)
      : null;

    SecurityHealthCheckJSONParser convertedData = SecurityHealthCheckJSONParser.parse(data);

    Id securityHealthCheckOrgId;

    if (securityHealthCheckOrgs == null) {
      SObject newSecurityHealthCheckOrg = createNewSecurityHealthCheckOrg(
        organization,
        Decimal.valueOf(convertedData.Records[0].Score)
      );

      securityHealthCheckOrgId = newSecurityHealthCheckOrg.Id;
    } else {
      Decimal updatedScore = Decimal.valueOf(convertedData.Records[0].Score);

      updateSecurityHealthCheckOrg(organizations, updatedScore);
      securityHealthCheckOrgId = securityHealthCheckOrg.Id;
    }

    Security_Health_Check__c shc = new Security_Health_Check__c();
    shc.Check_Date__c = Date.today();
    shc.CustomBaselineId__c = convertedData.Records[0].CustomBaselineId;
    shc.DurableId__c = convertedData.Records[0].DurableId;
    shc.Score__c = Decimal.valueOf(convertedData.Records[0].Score);
    shc.Org_Name__c = UserInfo.getOrganizationName();
    shc.Org_Identifier__c = UserInfo.getOrganizationId();
    shc.Source__c = 'This';
    shc.Security_Health_Check_Org__c = securityHealthCheckOrgId;

    // Before Inserting, lookup the previous record and set the previous value
    List<Security_Health_Check__c> previousChecks = [
      SELECT Id, Score__c
      FROM Security_Health_Check__c
      WHERE Org_Identifier__c = :UserInfo.getOrganizationId()
      ORDER BY CreatedDate DESC
      LIMIT 1
    ];

    if (previousChecks.size() > 0) {
      shc.Previous_Score__c = previousChecks[0].Score__c;
    } else {
      shc.Previous_Score__c = shc.Score__c;
    }

    List<SObject> newSHCList = new List<SObject>();
    newSHCList.add(shc);
    SObjectAccessDecision sanitisedRecords = Security.stripInaccessible(
      AccessType.CREATABLE,
      newSHCList
    );

    insert sanitisedRecords.getRecords();

    return sanitisedRecords.getRecords()[0].Id;
  }

  public static SObject createNewSecurityHealthCheckOrg(
    Organization organization,
    Decimal latestScore
  ) {
    Security_Health_Check_Org__c securityHealthCheckOrg = new Security_Health_Check_Org__c(
      Name = organization.Name,
      Organization_Id__c = organization.Id,
      Active__c = true,
      Refresh_Token__c = true,
      Sync_Status__c = 'Active',
      Last_Sync__c = System.now(),
      Latest_Score__c = latestScore
    );

    List<SObject> newSecurityHealthCheckOrgs = new List<SObject>();
    newSecurityHealthCheckOrgs.add(securityHealthCheckOrg);
    SObjectAccessDecision sanitisedRecords = Security.stripInaccessible(
      AccessType.CREATABLE,
      newSecurityHealthCheckOrgs
    );

    insert sanitisedRecords.getRecords();

    return sanitisedRecords.getRecords()[0];
  }

  public static void updateSecurityHealthCheckOrg(
    List<Organization> organizations,
    Decimal latestScore
  ) {
    List<Security_Health_Check_Org__c> securityHealthCheckOrgs = [
      SELECT Id, Last_Sync__c, Latest_Score__c
      FROM Security_Health_Check_Org__c
      WHERE Actual_Org_Id__c = :organizations[0].Id
      WITH SECURITY_ENFORCED
    ];

    for (Security_Health_Check_Org__c healthCheckOrg : securityHealthCheckOrgs) {
      healthCheckOrg.Last_Sync__c = System.now();
      healthCheckOrg.Latest_Score__c = latestScore;
    }

    SObjectAccessDecision sanitisedRecords = Security.stripInaccessible(
      AccessType.UPDATABLE,
      securityHealthCheckOrgs
    );

    update sanitisedRecords.getRecords();
  }

  @TestVisible
  private static void createSecurityHealthCheckRisks(String data, Id securityHealthCheckId) {
    SecurityHealthCheckRiskJSONParser converteddata = SecurityHealthCheckRiskJSONParser.parse(data);

    List<Security_Health_Check_Risk__c> risks = new List<Security_Health_Check_Risk__c>();

    // Before Loading, lookup the previous record and get a list of ratings (RiskType) s to set as previous
    List<Security_Health_Check__c> previousChecks = [
      SELECT Id, Score__c
      FROM Security_Health_Check__c
      WHERE Org_Identifier__c = :UserInfo.getOrganizationId() AND All_Risks_Loaded__c = TRUE
      WITH SECURITY_ENFORCED
      ORDER BY CreatedDate DESC
      LIMIT 1
    ];
    Map<String, String> previousRiskScores = new Map<String, String>();

    if (previousChecks.size() > 0) {
      // Get the related risk scores
      List<Security_Health_Check_Risk__c> previousRisks = [
        SELECT Id, DurableId__c, RiskType__c
        FROM Security_Health_Check_Risk__c
        WHERE Security_Health_Check__c = :previousChecks[0].Id
        WITH SECURITY_ENFORCED
      ];

      for (Security_Health_Check_Risk__c risk : previousRisks) {
        previousRiskScores.put(risk.DurableId__c, risk.RiskType__c);
      }
    }
    for (SecurityHealthCheckRiskJSONParser.Records risk : converteddata.records) {
      Security_Health_Check_Risk__c shcr = new Security_Health_Check_Risk__c();

      shcr.Security_Health_Check__c = securityHealthCheckId;
      shcr.DurableId__c = risk.DurableId;
      shcr.OrgValue__c = risk.OrgValue;
      shcr.OrgValueRaw__c = risk.OrgValueRaw;
      shcr.RiskType__c = risk.RiskType;
      shcr.Setting__c = risk.Setting;
      // set the previous score
      if (previousRiskScores.containsKey(risk.DurableId)) {
        shcr.previous_Rating__C = previousRiskScores.get(risk.DurableId);
      } else {
        shcr.Previous_Rating__c = risk.RiskType;
      }
      shcr.SettingGroup__c = risk.SettingGroup;
      shcr.SettingRiskCategory__c = risk.SettingRiskCategory;
      shcr.StandardValue__c = risk.StandardValue;
      shcr.StandardValueRaw__c = risk.StandardValueRaw;

      risks.add(shcr);
    }

    SObjectAccessDecision sanitisedRecords = security.stripInaccessible(
      AccessType.CREATABLE,
      risks
    );

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

  @InvocableMethod(
    label='Send Health Check Data'
    description='Send the org health check data to the main org'
  )
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

    Security_Health_Check_Org__c org = new Security_Health_Check_Org__c();
    org.Name = UserInfo.getOrganizationName();
    org.Organization_Id__c = UserInfo.getOrganizationId();

    Security_Health_Check_Config__mdt config = getSecurityHealthCheckConfig();

    if (config == null) {
      throw new SecurityHealthCheckServiceException(
        'No Configuration Exists. Please define the custom meta data - Security Health Check Config'
      );
    }

    if (config.Is_this_the_Central_org__c == true) {
    } else {
      org.Token__c = config.Token__c;
      payload.org = org;
      HTTPRequest req = new HTTPRequest();
      String url = 'callout:' + config.Named_Credentials__c + config.Central_Org_URL__c;
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
      List<Security_Health_Check_Config__mdt> securityHealthCheckConfigs = [
        SELECT
          Central_Org_URL__c,
          Token__c,
          Security_Superstar_Threshold__c,
          Named_Credentials__c,
          Is_this_the_Central_org__c
        FROM Security_Health_Check_Config__mdt
        WHERE DeveloperName != 'Configuration'
        WITH SECURITY_ENFORCED
        LIMIT 1
      ];
      Security_Health_Check_Config__mdt securityHealthCheckConfig = (securityHealthCheckConfigs.size() ==
        1)
        ? securityHealthCheckConfigs.get(0)
        : null;

      if (securityHealthCheckConfig == null) {
        List<Security_Health_Check_Config__mdt> securityHealthCheckConfigsDefault = [
          SELECT
            Central_Org_URL__c,
            Token__c,
            Security_Superstar_Threshold__c,
            Named_Credentials__c,
            Is_this_the_Central_org__c
          FROM Security_Health_Check_Config__mdt
          WITH SECURITY_ENFORCED
          LIMIT 1
        ];
        securityHealthCheckConfig = (securityHealthCheckConfigsDefault.size() == 1)
          ? securityHealthCheckConfigsDefault.get(0)
          : null;
      }

      return securityHealthCheckConfig;
    } else {
      List<Security_Health_Check_Config__mdt> securityHealthCheckConfigsDefault = [
        SELECT
          Central_Org_URL__c,
          Token__c,
          Security_Superstar_Threshold__c,
          Named_Credentials__c,
          Is_this_the_Central_org__c
        FROM Security_Health_Check_Config__mdt
        WHERE DeveloperName = 'Configuration'
        WITH SECURITY_ENFORCED
        LIMIT 1
      ];
      Security_Health_Check_Config__mdt securityHealthCheckConfigTest = (securityHealthCheckConfigsDefault.size() ==
        1)
        ? securityHealthCheckConfigsDefault.get(0)
        : null;

      return securityHealthCheckConfigTest;
    }
  }

  public static Security_Health_Check__c getSecurityHealthCheckById(Id securityHealthCheckId) {
    return [
      SELECT
        Id,
        CustomBaselineId__c,
        DurableId__c,
        Score__c,
        Previous_Score__c,
        Check_Date__c,
        Org_Identifier__c,
        Org_Name__c,
        All_Risks_Loaded__c
      FROM Security_Health_Check__c
      WHERE Id = :securityHealthCheckId
      WITH SECURITY_ENFORCED
    ];
  }

  public static List<Security_Health_Check_Risk__c> getSecurityHealthCheckRisks(
    Id securityHealthCheckId
  ) {
    return [
      SELECT
        Id,
        Name,
        DurableId__c,
        OrgValue__c,
        OrgValueRaw__c,
        RiskType__c,
        Previous_Rating__c,
        Security_Health_Check__c,
        Setting__c,
        SettingGroup__c,
        SettingRiskCategory__c,
        StandardValue__c,
        StandardValueRaw__c
      FROM Security_Health_Check_Risk__c
      WHERE Security_Health_Check__c = :securityHealthCheckId
      WITH SECURITY_ENFORCED
    ];
  }

  global class HealthCheckPayload {
    public Security_Health_Check_Org__c org { get; set; }
    public Security_Health_Check__c healthCheck { get; set; }
    public List<Security_Health_Check_Risk__c> risks { get; set; }
  }
}
