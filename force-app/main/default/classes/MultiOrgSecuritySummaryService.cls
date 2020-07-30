public with sharing class MultiOrgSecuritySummaryService {
  /**
   * Predefined classes are used to store the core security response data as it can get to complex for other datatypes.
   */
  public class MultiOrgSummaries {
    @AuraEnabled
    public String mode { get; set; } /* byorg, bydate, thisorg */

    @AuraEnabled
    public Map<String, List<String>> summaryCategories { get; set; }

    @AuraEnabled
    public List<DailyOrgSummary> summaries { get; set; }
  }

  public class DailyOrgSummary {
    @AuraEnabled
    public Security_Health_Check_Org__c org { get; set; }
    @AuraEnabled
    public Security_Health_Check__c healthCheck { get; set; }
    @AuraEnabled
    public String iterator { get; set; }
  }

  /**
   * When an org in the app is selected - we need to get a number of datapoints for the user to access in the UI.
   * This requires an imperative method to get as the state requires a precise response time.
   *
   * @param selectedOrgId - The Id of the org selected
   *
   * @return Map<String, Object> Data for the UI
   */
  @AuraEnabled(Cacheable=true)
  public static Map<String, Object> getCurrentOrgDetails(String selectedOrgId) {
    List<Security_Health_Check_Org__c> securityHealthCheckOrgs = [
      SELECT
        Id,
        Active__c,
        Category__c,
        Actual_Org_Id__c,
        Data_Classification__c,
        Sync_Status__c,
        Description__c,
        Name,
        Token__c,
        Point_of_Contact__r.Name
      FROM Security_Health_Check_Org__c
      WHERE Id = :selectedOrgId
      WITH SECURITY_ENFORCED
      LIMIT 1
    ];
    Security_Health_Check_Org__c securityHealthCheckOrg = (securityHealthCheckOrgs.size() == 1)
      ? securityHealthCheckOrgs.get(0)
      : null;
    Security_Health_Check__c latestSecurityHealthCheck = getLatestSecurityHealthCheck(
      securityHealthCheckOrg.Id
    );
    Security_Health_Check__c firstSecurityHealthCheck = getFirstSecurityHealthCheck(
      securityHealthCheckOrg.Id
    );
    Integer totalOpenSecurityTasks = getTotalOpenSecurityTasks(securityHealthCheckOrg.Id);
    Map<String, Object> orgDetails = new Map<String, Object>();

    List<Security_Health_Check_Org__c> overviewList = new List<Security_Health_Check_Org__c>();
    overviewList.add(securityHealthCheckOrg);

    orgDetails.put('Id', securityHealthCheckOrg.Id);
    orgDetails.put('Active', securityHealthCheckOrg.Active__c);
    orgDetails.put('Status', securityHealthCheckOrg.Active__c ? 'Active' : 'Inactive');
    orgDetails.put('StatusIconVariant', securityHealthCheckOrg.Active__c ? 'success' : 'warning');
    orgDetails.put('Category', securityHealthCheckOrg.Category__c);
    orgDetails.put('DataClassification', securityHealthCheckOrg.Data_Classification__c);
    orgDetails.put('SecurityAdmin', securityHealthCheckOrg.Point_of_Contact__r.Name);
    orgDetails.put('SecurityAdminId', securityHealthCheckOrg.Point_of_Contact__c);
    orgDetails.put('Description', securityHealthCheckOrg.Description__c);
    orgDetails.put('Name', securityHealthCheckOrg.Name);
    orgDetails.put('Token', securityHealthCheckOrg.Token__c);
    orgDetails.put('SyncStatus', securityHealthCheckOrg.Sync_Status__c);
    orgDetails.put('TotalOpenSecurityTasks', totalOpenSecurityTasks);
    orgDetails.put(
      'LatestHealthCheckScore',
      latestSecurityHealthCheck != null ? String.valueOf(latestSecurityHealthCheck.Score__c) : 'N/A'
    );
    orgDetails.put(
      'LatestHealthCheckDate',
      latestSecurityHealthCheck != null
        ? (Date.valueOf(latestSecurityHealthCheck.Check_Date__c)).daysBetween(System.today())
        : null
    );
    orgDetails.put(
      'DaysSinceFirstHealthCheck',
      firstSecurityHealthCheck != null
        ? ((Date.valueOf(latestSecurityHealthCheck.Check_Date__c)).daysBetween(System.today()) + 1)
        : null
    );
    orgDetails.put(
      'LatestHealthCheckSync',
      latestSecurityHealthCheck != null ? latestSecurityHealthCheck.CreatedDate : null
    );
    orgDetails.put(
      'LatestHealthCheckId',
      latestSecurityHealthCheck != null ? latestSecurityHealthCheck.Id : null
    );

    return orgDetails;
  }

  /**
   * Get the total number of open security tasks for the org selected. If there is no Id submitted, get All of the open
   * Tasks for the org.
   *
   * @param healthCheckOrgRecordId - The health check Id selected in the UI
   *
   * @return Integer
   */
  public static Integer getTotalOpenSecurityTasks(Id healthCheckOrgRecordId) {
    Integer totalOpenSecurityTasks = 0;

    if (healthCheckOrgRecordId != null) {
      totalOpenSecurityTasks = [
        SELECT COUNT()
        FROM Security_Health_Check_Task__c
        WHERE
          (Status__c = 'Created'
          OR Status__c = 'In Progress')
          AND Related_To_Org__c = :healthCheckOrgRecordId
        WITH SECURITY_ENFORCED
      ];
    } else {
      totalOpenSecurityTasks = [
        SELECT COUNT()
        FROM Security_Health_Check_Task__c
        WHERE Status__c = 'Created' OR Status__c = 'In Progress'
        WITH SECURITY_ENFORCED
      ];
    }

    return totalOpenSecurityTasks;
  }

  /**
   * Get the configuration details for the current org - when an org is selected in the UI, we can get a number of
   * details to enrich the data being viewed by the user. If no config record is found - return null and display the
   * setup screen to the user.
   *
   * @return Map<String, Object>
   */
  @AuraEnabled(Cacheable=true)
  public static Map<String, Object> getCurrentOrgConfigurationDetails() {
    Organization organization = getOrganization();
    Security_Health_Check_Org__c overview = getCurrentOrgOverview(organization.Id);
    Security_Health_Check_Config__mdt config = SecurityHealthCheckService.getSecurityHealthCheckConfig();
    Integer totalOpenSecurityTasks = getTotalOpenSecurityTasks(null);

    List<Security_Health_Check_Org__c> securityHealthCheckOrgs = getAllSecurityHealthCheckOrgs();

    Integer totalProductionOrgs = 0;
    Integer totalSandboxOrgs = 0;
    Decimal securityScoreSum = 0;
    for (Security_Health_Check_Org__c securityHealthCheckOrg : securityHealthCheckOrgs) {
      securityScoreSum =
        securityScoreSum +
        (securityHealthCheckOrg.Latest_Score__c != null
          ? securityHealthCheckOrg.Latest_Score__c
          : 0);
      if (securityHealthCheckOrg.Category__c == 'Production') {
        totalProductionOrgs++;
      } else if (securityHealthCheckOrg.Category__c == 'Sandbox') {
        totalSandboxOrgs++;
      }
    }

    Map<String, Object> configurationDetails = new Map<String, Object>();

    List<Security_Health_Check_Org__c> overviewList = new List<Security_Health_Check_Org__c>();

    overviewList.add(overview);

    if (overview == null) {
      configurationDetails = null;
    } else {
      configurationDetails.put('OrgInfo', organization);
      configurationDetails.put('OrgConfiguration', config);
      configurationDetails.put('OrgOverview', overview);
      configurationDetails.put(
        'SecurityAdmin',
        overviewList.size() >= 1 ? overview.Point_of_Contact__r.Name : null
      );
      configurationDetails.put('LocalDate', Date.today());
      configurationDetails.put('TotalProductionOrgs', totalProductionOrgs);
      configurationDetails.put('TotalSandboxOrgs', totalSandboxOrgs);
      configurationDetails.put('TotalOpenSecurityTasks', totalOpenSecurityTasks);
      configurationDetails.put(
        'AverageSecurityScore',
        securityHealthCheckOrgs != null
          ? (securityScoreSum / securityHealthCheckOrgs.size()).intValue()
          : 0
      );
    }

    return configurationDetails;
  }

  /**
   * Get the details of the security admin assigned to the org and return them to the UI along with their skills.
   *
   * @param userId
   *
   * @return Map<String, Object>
   */
  @AuraEnabled
  public static Map<String, Object> getSecurityAdminDetails(Id userId) {
    List<User> users = [
      SELECT
        Id,
        Name,
        Email,
        FullPhotoUrl,
        MediumPhotoUrl,
        SmallPhotoUrl,
        Title,
        Country,
        AboutMe,
        Trailblazer_me_Profile__c
      FROM User
      WHERE Id = :userId
      WITH SECURITY_ENFORCED
      LIMIT 1
    ];
    User user = (users.size() == 1) ? users.get(0) : null;

    Security_Health_Check_Config__mdt config = SecurityHealthCheckService.getSecurityHealthCheckConfig();

    List<Admin_Security_Skill__c> securitySkills = [
      SELECT
        Id,
        Course_Name__c,
        Image_Path__c,
        Security_Skill__r.Point_value__c,
        Completed_Date__c,
        Course_Image__c,
        Description__c,
        Due_Date__c,
        Link__c,
        Security_Skill__c,
        Skill_Level__c,
        Status__c,
        Type__c,
        User__c,
        Name,
        OwnerId,
        SystemModstamp
      FROM Admin_Security_Skill__c
      WHERE User__c = :userId
      WITH SECURITY_ENFORCED
      ORDER BY Type__c, Course_Name__c
    ];

    List<Map<String, Object>> groupSkillsList = new List<Map<String, Object>>();

    Map<String, List<SObject>> groupedSkills = new Map<String, List<SObject>>();

    Decimal pointValue = 0;
    for (Admin_Security_Skill__c record : securitySkills) {
      pointValue = pointValue + record.Security_Skill__r.Point_value__c;
      String value = (String) record.get('Type__c');
      if (!groupedSkills.containsKey(value)) {
        groupedSkills.put(value, new List<SObject>());
      }

      groupedSkills.get(value).add(record);
    }

    for (String groupName : groupedSkills.keySet()) {
      Map<String, Object> namedGroup = new Map<String, Object>();

      namedGroup.put('Type', groupName);
      namedGroup.put('Values', groupedSkills.get(groupName));

      groupSkillsList.add(namedGroup);
    }

    Map<String, Object> adminDetails = new Map<String, Object>();

    adminDetails.put('UserInfo', user);
    adminDetails.put('SecuritySkills', groupSkillsList);
    adminDetails.put('Points', pointValue);
    adminDetails.put('SecuritySuperstarThreshold', config.Security_Superstar_Threshold__c);

    return adminDetails;
  }

  /**
   * Get the admins skills and identify if they are currently assigned - if so, then return them to the ui for management
   *
   * @param userId
   * @param staticResourceUrlString
   *
   * @return List<Map<String, Object>>
   */
  @AuraEnabled
  public static List<Map<String, Object>> getAdminSkillsToManage(
    Id userId,
    String staticResourceUrlString
  ) {
    List<Admin_Security_Skill__c> adminSecuritySkills = [
      SELECT Id, Security_Skill__c
      FROM Admin_Security_Skill__c
      WHERE User__c = :userId
      WITH SECURITY_ENFORCED
    ];

    Map<Id, String> skillIds = new Map<Id, String>();

    for (Admin_Security_Skill__c adminSecuritySkill : adminSecuritySkills) {
      skillIds.put(adminSecuritySkill.Security_Skill__c, adminSecuritySkill.Id);
    }

    List<Security_Skill__c> securitySkills = [
      SELECT Id, Name, Skill_Level__c, Description__c, Type__c, Image_Path__c
      FROM Security_Skill__c
      WITH SECURITY_ENFORCED
      ORDER BY Type__c, Name
    ];

    List<Map<String, Object>> skillsListMap = new List<Map<String, Object>>();

    for (Security_Skill__c skill : securitySkills) {
      Map<String, Object> skillMap = new Map<String, Object>();

      skillMap.put('Id', skill.Id);
      skillMap.put('AdminSkillId', skillIds.get(skill.Id));
      skillMap.put('Name', skill.Name);
      skillMap.put('Skill_Level__c', skill.Skill_Level__c);
      skillMap.put('Description__c', skill.Description__c);
      skillMap.put('Type__c', skill.Type__c);
      skillMap.put('resourceURL', staticResourceUrlString + skill.Image_Path__c.substring(23));
      skillMap.put('Completed', skillIds.containsKey(skill.Id));

      skillsListMap.add(skillMap);
    }

    List<Map<String, Object>> groupSkillsList = new List<Map<String, Object>>();

    Map<String, List<Map<String, Object>>> groupedSkills = new Map<String, List<Map<String, Object>>>();

    for (Map<String, Object> record : skillsListMap) {
      String value = (String) record.get('Type__c');

      if (!groupedSkills.containsKey(value)) {
        groupedSkills.put(value, new List<Map<String, Object>>());
      }
      groupedSkills.get(value).add(record);
    }

    for (String groupName : groupedSkills.keySet()) {
      Map<String, Object> namedGroup = new Map<String, Object>();

      namedGroup.put('Type', groupName);
      namedGroup.put('Values', groupedSkills.get(groupName));
      groupSkillsList.add(namedGroup);
    }

    return groupSkillsList;
  }

  /**
   * Get the security health check data and return it to the UI - It can be in three formats - a parent org viewing
   * it's children, a single org viewing a date view, or a child org viewing it's own data.
   *
   * @param format
   * @param theDate
   * @param orgId
   * @param maxRows
   *
   * @return MultiOrgSummaries
   */

  @AuraEnabled(Cacheable=true)
  public static MultiOrgSummaries getSummaries(
    String format,
    Date theDate,
    String orgId,
    Integer maxRows
  ) {
    MultiOrgSummaries orgSum = new MultiOrgSummaries();
    orgSum.mode = format;

    // check the metadata and see what results we should be showing
    Security_Health_Check_Config__mdt config = SecurityHealthCheckService.getSecurityHealthCheckConfig();

    if (config == null) {
      // for now, just return empty array
    } else if (config.Is_this_the_Central_org__c == true) {
      if (format == 'bydate') {
        orgSum.summaries = getSecurityCheckByDate(theDate);
      } else if (format == 'byorg') {
        orgSum.summaries = getSecurityCheckByOrg(orgId, maxRows);
      }
    } else {
      // this is a spoke org, so need to load for thisorg only
      orgSum.mode = 'thisorg';
      Security_Health_Check_Org__c tempOrg = getCurrentOrgOverview(UserInfo.getOrganizationId());
      orgSum.summaries = getSecurityCheckByOrg(tempOrg.Id, maxRows);
    }

    orgSum.summaryCategories = getSummaryCategories();

    return orgSum;
  }

  @AuraEnabled(Cacheable=true)
  public static List<DailyOrgSummary> getSecurityCheckByDate(Date theDate) {
    List<DailyOrgSummary> results = new List<DailyOrgSummary>();
    // Get a list of all possible risks, sorted by SettingRiskCategory__c and DurableId__c

    Map<String, Security_Health_Check_Risk__c> defaultCategories = getDefaultRiskCategories();
    List<Security_Health_Check__c> dailyChecks = [
      SELECT
        Id,
        Name,
        Score__c,
        Previous_Score__c,
        Check_Date__c,
        Org_Name__c,
        Org_Identifier__c,
        Security_Health_Check_Org__c,
        (
          SELECT
            Id,
            DurableId__c,
            Name,
            OrgValue__c,
            OrgValueRaw__c,
            RiskType__c,
            Security_Health_Check__c,
            Setting__c,
            SettingGroup__c,
            SettingRiskCategory__c,
            StandardValue__c,
            StandardValueRaw__c
          FROM Security_Health_Check_Risks__r
          WHERE Security_Health_Check__r.Check_Date__c = :theDate
          ORDER BY SettingRiskCategory__c, DurableId__c
        )
      FROM Security_Health_Check__c
      WHERE Check_Date__c = :theDate
      WITH SECURITY_ENFORCED
    ];

    // Get the list of active orgs and create a default DOS for each
    List<Security_Health_Check_Org__c> activeOrgs = getActiveSecurityHealthCheckOrgs();

    Integer i = 0;

    for (Security_Health_Check_Org__c activeOrg : activeOrgs) {
      DailyOrgSummary dosDefault = new DailyOrgSummary();
      dosDefault.org = activeOrg;

      Security_Health_Check__c shc = new Security_Health_Check__c();
      shc.Check_Date__c = theDate;
      shc.Org_Identifier__c = activeOrg.Actual_Org_Id__c;
      shc.security_health_check_Org__c = activeOrg.Id;
      shc.Score__c = -1; // indicates that there is no data for this date
      dosDefault.healthCheck = shc;
      dosDefault.iterator = activeOrg.Id + String.valueOf(i);

      results.add(dosDefault);
      i++;
    }

    // STEP 2. When it comes to the healthcheck, get the matching Org record and write the healthcheck
    // generate the daily summaries
    for (Security_Health_Check__c check : dailyChecks) {
      // first set the default list of values
      Map<String, Security_Health_Check_Risk__c> orgRisks = defaultCategories.clone();

      for (Security_Health_Check_Risk__c orgRisk : check.Security_Health_Check_Risks__r) {
        orgRisks.put(orgRisk.DurableId__c, orgRisk);
      }

      Integer index = 0;
      for (DailyOrgSummary dos : results) {
        if (dos.org.Id == check.Security_Health_Check_Org__c) {
          dos.healthCheck = check;
          dos.iterator = check.Id;
          results.set(index, dos);
        }

        index++;
      }
    }

    return results;
  }

  @AuraEnabled(Cacheable=true)
  public static List<DailyOrgSummary> getSecurityCheckByOrg(String orgId, Integer maxRows) {
    List<DailyOrgSummary> results = new List<DailyOrgSummary>();

    Map<Date, DailyOrgSummary> dailySummaryMap = new Map<Date, DailyOrgSummary>();

    // Get the Org record that matches the supplied Id
    Security_Health_Check_Org__c org = getSecurityHealthCheckOrgById(orgId);

    Map<String, Security_Health_Check_Risk__c> defaultCategories = getDefaultRiskCategories();

    List<Date> defaultDates = new List<Date>();
    Date myDate = Date.today();
    Integer i = 0;
    while (i < maxRows) {
      defaultDates.add(myDate);
      DailyOrgSummary dos = new DailyOrgSummary();
      Security_Health_Check__c shc = new Security_Health_Check__c();
      shc.Check_Date__c = myDate;
      shc.Org_Identifier__c = orgId;
      shc.security_health_check_Org__c = org.Id;
      shc.Score__c = -1; // indicates that there is no data for this date
      dos.healthCheck = shc;
      dos.org = org;
      dos.iterator = org.Id + String.valueOf(i);

      dailySummaryMap.put(myDate, dos);
      i++;
      myDate = myDate.addDays(-1);
    }

    List<Security_Health_Check__c> dailyChecks;
    if (orgId == '') {
      //only load for this org, no filter
      dailyChecks = [
        SELECT
          Id,
          Name,
          Security_Health_Check_Org__c,
          Score__c,
          Check_Date__c,
          Change__c,
          Org_Name__c,
          Org_Identifier__c,
          (
            SELECT
              Id,
              DurableId__c,
              Name,
              OrgValue__c,
              OrgValueRaw__c,
              RiskType__c,
              Previous_Rating__c,
              Change__c,
              Security_Health_Check__c,
              Setting__c,
              SettingGroup__c,
              SettingRiskCategory__c,
              StandardValue__c,
              StandardValueRaw__c
            FROM Security_Health_Check_Risks__r
            ORDER BY SettingRiskCategory__c, DurableId__c
          )
        FROM Security_Health_Check__c
        WITH SECURITY_ENFORCED
        ORDER BY Check_Date__c DESC
        LIMIT :maxRows
      ];
    } else {
      dailyChecks = [
        SELECT
          Id,
          Name,
          Security_Health_Check_Org__c,
          Score__c,
          Check_Date__c,
          Change__c,
          Org_Name__c,
          Org_Identifier__c,
          (
            SELECT
              Id,
              DurableId__c,
              Name,
              OrgValue__c,
              OrgValueRaw__c,
              RiskType__c,
              Previous_Rating__c,
              Change__c,
              Security_Health_Check__c,
              Setting__c,
              SettingGroup__c,
              SettingRiskCategory__c,
              StandardValue__c,
              StandardValueRaw__c
            FROM Security_Health_Check_Risks__r
            ORDER BY SettingRiskCategory__c, DurableId__c
          )
        FROM Security_Health_Check__c
        WHERE Security_Health_Check_Org__c = :orgId
        WITH SECURITY_ENFORCED
        ORDER BY Check_Date__c DESC
        LIMIT :maxRows
      ];
    }

    // generate the daily summaries

    for (Security_Health_Check__c check : dailyChecks) {
      // first set the default list of values
      Map<String, Security_Health_Check_Risk__c> orgRisks = defaultCategories.clone();

      for (Security_Health_Check_Risk__c orgRisk : check.Security_Health_Check_Risks__r) {
        orgRisks.put(orgRisk.DurableId__c, orgRisk);
      }

      DailyOrgSummary dos = new DailyOrgSummary();
      dos.healthCheck = check;
      dos.iterator = check.Id;
      dos.org = org;

      //     dos.risks = orgRisks;

      if (dailySummaryMap.containsKey(dos.healthCheck.Check_Date__c)) {
        dailySummaryMap.put(dos.healthCheck.Check_Date__c, dos);
      }
    }

    return dailySummaryMap.values();
  }

  /* Get a list of the default risk categories based on the existing data */
  static Map<String, Security_Health_Check_Risk__c> getDefaultRiskCategories() {
    // Get the latest security health check record
    List<Security_Health_Check__c> securityHealthChecks = [
      SELECT Id
      FROM Security_Health_Check__c
      ORDER BY CreatedDate DESC
      LIMIT 1
    ];
    Security_Health_Check__c securityHealthCheck = (securityHealthChecks.size() == 1)
      ? securityHealthChecks.get(0)
      : null;

    // Get a list of all possible risks, sorted by SettingRiskCategory__c and DurableId__c associated to the latest health check
    List<AggregateResult> risks = [
      SELECT SettingRiskCategory__c, DurableId__c
      FROM Security_Health_Check_Risk__c
      WHERE Security_Health_Check__c = :securityHealthCheck.Id
      WITH SECURITY_ENFORCED
      GROUP BY SettingRiskCategory__c, DurableId__c
      ORDER BY SettingRiskCategory__c, DurableId__c
    ];
    // Define the baseline list of categories to be populated later from data. Need this to ensure UI is consistent
    Map<String, Security_Health_Check_Risk__c> defaultCategories = new Map<String, security_Health_Check_Risk__c>();

    for (AggregateResult risk : risks) {
      String category = (String) risk.get('SettingRiskCategory__c');
      String durableId = (String) risk.get('DurableId__c');
      defaultCategories.put(durableId, null);
    }

    return defaultCategories;
  }

  /* Get a list of the summary Categories */
  public static Map<String, List<String>> getSummaryCategories() {
    List<Security_Health_Check__c> securityHealthChecks = [
      SELECT Id
      FROM Security_Health_Check__c
      ORDER BY CreatedDate DESC
      LIMIT 1
    ];
    Security_Health_Check__c securityHealthCheck = (securityHealthChecks.size() == 1)
      ? securityHealthChecks.get(0)
      : null;

    // Get a list of all possible risks, sorted by SettingRiskCategory__c and DurableId__c
    List<AggregateResult> risks = [
      SELECT SettingRiskCategory__c, DurableId__c
      FROM Security_Health_Check_Risk__c
      WHERE Security_Health_Check__c = :securityHealthCheck.Id
      WITH SECURITY_ENFORCED
      GROUP BY SettingRiskCategory__c, DurableId__c
      ORDER BY SettingRiskCategory__c, DurableId__c
    ];
    // Define the baseline list of categories to be populated later from data. Need this to ensure UI is consistent
    Map<String, List<String>> summaryCategories = new Map<String, List<String>>();

    for (AggregateResult risk : risks) {
      String category = (String) risk.get('SettingRiskCategory__c');
      String durableId = (String) risk.get('DurableId__c');

      // Add the category to the grouped
      List<String> categoryRisks = new List<String>();
      if (summaryCategories.containsKey(category)) {
        categoryRisks = summaryCategories.get(category);
      }

      categoryRisks.add(durableId);
      summaryCategories.put(category, categoryRisks);
    }

    return summaryCategories;
  }

  /**
   * A number of utility SOQL Queries are used to get the data back from some of the parent methods.
   *
   * @return SObject or List<SObject>
   */

  /* Lookup the org record that matches the passed OrganizationId */
  static Security_Health_Check_Org__c getSecurityHealthCheckOrgById(String orgId) {
    Security_Health_Check_Org__c org = new Security_Health_Check_Org__c();

    List<Security_Health_Check_Org__c> orgs = [
      SELECT
        Id,
        Name,
        CreatedDate,
        Category__c,
        Active__c,
        Actual_Org_Id__c,
        Token__c,
        Description__c
      FROM Security_Health_Check_Org__c
      WHERE Id = :orgId
      WITH SECURITY_ENFORCED
    ];

    if (orgs.size() > 0) {
      org = orgs[0];
    }

    return org;
  }

  static List<Security_Health_Check_Org__c> getActiveSecurityHealthCheckOrgs() {
    return [
      SELECT
        Id,
        Name,
        Active__c,
        Category__C,
        Actual_Org_Id__c,
        Description__c,
        Data_Classification__c
      FROM Security_Health_Check_Org__c
      WHERE ACTIVE__c = TRUE
      WITH SECURITY_ENFORCED
      ORDER BY NAME
    ];
  }

  @AuraEnabled(Cacheable=true)
  public static Security_Health_Check_Task__c getTaskDetails(Id taskId) {
    List<Security_Health_Check_Task__c> securityHealthCheckTasks = [
      SELECT
        CreatedById,
        CreatedDate,
        Id,
        Assigned_To__c,
        Assigned_To__r.Name,
        Related_To_Risk__r.DurableId__c,
        Related_To_Org__r.External_Contact_Email__c,
        Completed_Date__c,
        Due_Date__c,
        Related_To_Org__c,
        Related_To_Org__r.Name,
        Related_To_Org__r.Category__c,
        Related_To_Risk__c,
        Related_To_Risk__r.Name,
        Related_To_Risk__r.OrgValue__c,
        Related_To_Risk__r.Setting__c,
        Related_To_Risk__r.StandardValue__c,
        Severity__c,
        Status__c,
        Title__c
      FROM Security_Health_Check_Task__c
      WHERE Id = :taskId
      WITH SECURITY_ENFORCED
    ];
    Security_Health_Check_Task__c securityHealthCheckTask = (securityHealthCheckTasks.size() == 1)
      ? securityHealthCheckTasks.get(0)
      : null;

    return securityHealthCheckTask;
  }

  public static Organization getOrganization() {
    List<Organization> organizations = [
      SELECT Id, Name
      FROM Organization
      WITH SECURITY_ENFORCED
      LIMIT 1
    ];
    Organization organization = (organizations.size() == 1) ? organizations.get(0) : null;

    return organization;
  }

  public static List<Security_Health_Check_Org__c> getAllSecurityHealthCheckOrgs() {
    List<Security_Health_Check_Org__c> securityHealthCheckOrgs = [
      SELECT Id, Latest_Score__c, Category__c
      FROM Security_Health_Check_Org__c
      WHERE Active__c = TRUE
      WITH SECURITY_ENFORCED
    ];

    return securityHealthCheckOrgs;
  }

  public static Security_Health_Check_Org__c getCurrentOrgOverview(Id organizationId) {
    List<Security_Health_Check_Org__c> securityHealthCheckOrgs = [
      SELECT Id, Name, Description__c, Point_of_Contact__c, Point_of_Contact__r.Name
      FROM Security_Health_Check_Org__c
      WHERE Actual_Org_Id__c = :organizationId
      WITH SECURITY_ENFORCED
      LIMIT 1
    ];
    Security_Health_Check_Org__c securityHealthCheckOrg = (securityHealthCheckOrgs.size() == 1)
      ? securityHealthCheckOrgs.get(0)
      : null;

    return securityHealthCheckOrg;
  }

  @AuraEnabled
  public static List<Security_Health_Check_Task__c> getSecurityHealthCheckTasks(Id selectedOrgId) {
    List<Security_Health_Check_Task__c> securityHealthCheckTasks = [
      SELECT
        Id,
        Assigned_To__c,
        Completed_Date__c,
        Description__c,
        Resolution__c,
        Assigned_Name__c,
        Assigned_To__r.Name,
        Due_Date__c,
        Related_To_Org__c,
        Related_To_Risk__c,
        Name,
        Severity__c,
        Status__c,
        Title__c
      FROM Security_Health_Check_Task__c
      WHERE Related_To_Org__c = :selectedOrgId
      WITH SECURITY_ENFORCED
      ORDER BY CreatedDate DESC
    ];

    return securityHealthCheckTasks;
  }

  public static Security_Health_Check__c getLatestSecurityHealthCheck(Id securityHealthCheckOrgId) {
    List<Security_Health_Check__c> securityHealthChecks = [
      SELECT Id, Score__c, Check_Date__c, CreatedDate
      FROM Security_Health_Check__c
      WHERE Security_Health_Check_Org__c = :securityHealthCheckOrgId AND Check_Date__c != TOMORROW
      WITH SECURITY_ENFORCED
      ORDER BY CreatedDate DESC
      LIMIT 1
    ];
    Security_Health_Check__c securityHealthCheck = (securityHealthChecks.size() == 1)
      ? securityHealthChecks.get(0)
      : null;
    //system.debug(securityHealthCheck);
    return securityHealthCheck;
  }

  public static Security_Health_Check__c getFirstSecurityHealthCheck(Id securityHealthCheckOrgId) {
    List<Security_Health_Check__c> securityHealthChecks = [
      SELECT Id, Check_Date__c
      FROM Security_Health_Check__c
      WHERE Security_Health_Check_Org__c = :securityHealthCheckOrgId
      WITH SECURITY_ENFORCED
      ORDER BY CreatedDate ASC
      LIMIT 1
    ];
    Security_Health_Check__c securityHealthCheck = (securityHealthChecks.size() == 1)
      ? securityHealthChecks.get(0)
      : null;

    return securityHealthCheck;
  }
}
