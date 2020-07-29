/**
 * Created by apaterson on 17/03/2020.
 */

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
    List<multioss__Security_Health_Check_Org__c> securityHealthCheckOrgs = [
      SELECT
        Id,
        multioss__Active__c,
        multioss__Category__c,
        multioss__Actual_Org_Id__c,
        multioss__Data_Classification__c,
        multioss__Sync_Status__c,
        multioss__Description__c,
        Name,
        multioss__Token__c,
        multioss__Point_of_Contact__r.Name
      FROM multioss__Security_Health_Check_Org__c
      WHERE Id = :selectedOrgId
      WITH SECURITY_ENFORCED
      LIMIT 1
    ];
    multioss__Security_Health_Check_Org__c securityHealthCheckOrg = (securityHealthCheckOrgs.size() == 1) ? securityHealthCheckOrgs.get(0) : null;
    multioss__Security_Health_Check__c latestSecurityHealthCheck = getLatestSecurityHealthCheck(securityHealthCheckOrg.Id);
    multioss__Security_Health_Check__c firstSecurityHealthCheck = getFirstSecurityHealthCheck(securityHealthCheckOrg.Id);
    Integer totalOpenSecurityTasks = getTotalOpenSecurityTasks(securityHealthCheckOrg.Id);
    Map<String, Object> orgDetails = new Map<String, Object>();

    List<multioss__Security_Health_Check_Org__c> overviewList = new List<multioss__Security_Health_Check_Org__c>();
    overviewList.add(securityHealthCheckOrg);

    orgDetails.put('Id', securityHealthCheckOrg.Id);
    orgDetails.put('Active', securityHealthCheckOrg.multioss__Active__c);
    orgDetails.put('Status', securityHealthCheckOrg.multioss__Active__c ? 'Active' : 'Inactive');
    orgDetails.put('StatusIconVariant', securityHealthCheckOrg.multioss__Active__c ? 'success' : 'warning');
    orgDetails.put('Category', securityHealthCheckOrg.multioss__Category__c);
    orgDetails.put('DataClassification', securityHealthCheckOrg.multioss__Data_Classification__c);
    orgDetails.put('SecurityAdmin', securityHealthCheckOrg.multioss__Point_of_Contact__r.Name);
    orgDetails.put('SecurityAdminId', securityHealthCheckOrg.multioss__Point_of_Contact__c);
    orgDetails.put('Description', securityHealthCheckOrg.multioss__Description__c);
    orgDetails.put('Name', securityHealthCheckOrg.Name);
    orgDetails.put('Token', securityHealthCheckOrg.multioss__Token__c);
    orgDetails.put('SyncStatus', securityHealthCheckOrg.multioss__Sync_Status__c);
    orgDetails.put('TotalOpenSecurityTasks', totalOpenSecurityTasks);
    orgDetails.put('LatestHealthCheckScore', latestSecurityHealthCheck != null ? String.valueOf(latestSecurityHealthCheck.multioss__Score__c) : 'N/A');
    orgDetails.put('LatestHealthCheckDate', latestSecurityHealthCheck != null ? (Date.valueOf(latestSecurityHealthCheck.multioss__Check_Date__c)).daysBetween(System.today()) : null);
    orgDetails.put('DaysSinceFirstHealthCheck', firstSecurityHealthCheck != null ? ((Date.valueOf(latestSecurityHealthCheck.multioss__Check_Date__c)).daysBetween(System.today()) + 1) : null);
    orgDetails.put('LatestHealthCheckSync', latestSecurityHealthCheck != null ? latestSecurityHealthCheck.CreatedDate : null);
    orgDetails.put('LatestHealthCheckId', latestSecurityHealthCheck != null ? latestSecurityHealthCheck.Id : null);

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
        FROM multioss__Security_Health_Check_Task__c
        WHERE (multioss__Status__c = 'Created' OR multioss__Status__c = 'In Progress') AND multioss__Related_To_Org__c = :healthCheckOrgRecordId
        WITH SECURITY_ENFORCED
      ];
    } else {
      totalOpenSecurityTasks = [SELECT COUNT() FROM multioss__Security_Health_Check_Task__c WHERE multioss__Status__c = 'Created' OR multioss__Status__c = 'In Progress' WITH SECURITY_ENFORCED];
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
    multioss__Security_Health_Check_Org__c overview = getCurrentOrgOverview(organization.Id);
    Security_Health_Check_Config__mdt config = SecurityHealthCheckService.getSecurityHealthCheckConfig();
    Integer totalOpenSecurityTasks = getTotalOpenSecurityTasks(null);

    List<multioss__Security_Health_Check_Org__c> securityHealthCheckOrgs = getAllSecurityHealthCheckOrgs();

    Integer totalProductionOrgs = 0;
    Integer totalSandboxOrgs = 0;
    Decimal securityScoreSum = 0;
    for (multioss__Security_Health_Check_Org__c securityHealthCheckOrg : securityHealthCheckOrgs) {
      securityScoreSum = securityScoreSum + (securityHealthCheckOrg.multioss__Latest_Score__c != null ? securityHealthCheckOrg.multioss__Latest_Score__c : 0);
      if (securityHealthCheckOrg.multioss__Category__c == 'Production') {
        totalProductionOrgs++;
      } else if (securityHealthCheckOrg.multioss__Category__c == 'Sandbox') {
        totalSandboxOrgs++;
      }
    }

    Map<String, Object> configurationDetails = new Map<String, Object>();

    List<multioss__Security_Health_Check_Org__c> overviewList = new List<multioss__Security_Health_Check_Org__c>();

    overviewList.add(overview);

    if (overview == null) {
      configurationDetails = null;
    } else {
      configurationDetails.put('OrgInfo', organization);
      configurationDetails.put('OrgConfiguration', config);
      configurationDetails.put('OrgOverview', overview);
      configurationDetails.put('SecurityAdmin', overviewList.size() >= 1 ? overview.multioss__Point_of_Contact__r.Name : null);
      configurationDetails.put('LocalDate', Date.today());
      configurationDetails.put('TotalProductionOrgs', totalProductionOrgs);
      configurationDetails.put('TotalSandboxOrgs', totalSandboxOrgs);
      configurationDetails.put('TotalOpenSecurityTasks', totalOpenSecurityTasks);
      configurationDetails.put('AverageSecurityScore', securityHealthCheckOrgs != null ? (securityScoreSum / securityHealthCheckOrgs.size()).intValue() : 0);
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
      SELECT Id, Name, Email, FullPhotoUrl, MediumPhotoUrl, SmallPhotoUrl, Title, Country, AboutMe, multioss__Trailblazer_me_Profile__c
      FROM User
      WHERE Id = :userId
      WITH SECURITY_ENFORCED
      LIMIT 1
    ];
    User user = (users.size() == 1) ? users.get(0) : null;

    Security_Health_Check_Config__mdt config = SecurityHealthCheckService.getSecurityHealthCheckConfig();

    List<multioss__Admin_Security_Skill__c> securitySkills = [
      SELECT
        Id,
        multioss__Course_Name__c,
        multioss__Image_Path__c,
        multioss__Security_Skill__r.multioss__Point_value__c,
        multioss__Completed_Date__c,
        multioss__Course_Image__c,
        multioss__Description__c,
        multioss__Due_Date__c,
        multioss__Link__c,
        multioss__Security_Skill__c,
        multioss__Skill_Level__c,
        multioss__Status__c,
        multioss__Type__c,
        multioss__User__c,
        Name,
        OwnerId,
        SystemModstamp
      FROM multioss__Admin_Security_Skill__c
      WHERE multioss__User__c = :userId
      WITH SECURITY_ENFORCED
      ORDER BY multioss__Type__c, multioss__Course_Name__c
    ];

    List<Map<String, Object>> groupSkillsList = new List<Map<String, Object>>();

    Map<String, List<SObject>> groupedSkills = new Map<String, List<SObject>>();

    Decimal pointValue = 0;
    for (multioss__Admin_Security_Skill__c record : securitySkills) {
      pointValue = pointValue + record.multioss__Security_Skill__r.multioss__Point_value__c;
      String value = (String) record.get('multioss__Type__c');
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
    adminDetails.put('SecuritySuperstarThreshold', config.multioss__Security_Superstar_Threshold__c);

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
  public static List<Map<String, Object>> getAdminSkillsToManage(Id userId, String staticResourceUrlString) {
    List<multioss__Admin_Security_Skill__c> adminSecuritySkills = [
      SELECT Id, multioss__Security_Skill__c
      FROM multioss__Admin_Security_Skill__c
      WHERE multioss__User__c = :userId
      WITH SECURITY_ENFORCED
    ];

    Map<Id, String> skillIds = new Map<Id, String>();

    for (multioss__Admin_Security_Skill__c adminSecuritySkill : adminSecuritySkills) {
      skillIds.put(adminSecuritySkill.multioss__Security_Skill__c, adminSecuritySkill.Id);
    }

    List<multioss__Security_Skill__c> securitySkills = [
      SELECT Id, Name, multioss__Skill_Level__c, multioss__Description__c, multioss__Type__c, multioss__Image_Path__c
      FROM multioss__Security_Skill__c
      WITH SECURITY_ENFORCED
      ORDER BY multioss__Type__c, Name
    ];

    List<Map<String, Object>> skillsListMap = new List<Map<String, Object>>();

    for (multioss__Security_Skill__c skill : securitySkills) {
      Map<String, Object> skillMap = new Map<String, Object>();

      skillMap.put('Id', skill.Id);
      skillMap.put('AdminSkillId', skillIds.get(skill.Id));
      skillMap.put('Name', skill.Name);
      skillMap.put('multioss__Skill_Level__c', skill.multioss__Skill_Level__c);
      skillMap.put('multioss__Description__c', skill.multioss__Description__c);
      skillMap.put('multioss__Type__c', skill.multioss__Type__c);
      skillMap.put('resourceURL', staticResourceUrlString + skill.multioss__Image_Path__c.substring(23));
      skillMap.put('Completed', skillIds.containsKey(skill.Id));

      skillsListMap.add(skillMap);
    }

    List<Map<String, Object>> groupSkillsList = new List<Map<String, Object>>();

    Map<String, List<Map<String, Object>>> groupedSkills = new Map<String, List<Map<String, Object>>>();

    for (Map<String, Object> record : skillsListMap) {
      String value = (String) record.get('multioss__Type__c');

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
  public static MultiOrgSummaries getSummaries(String format, Date theDate, String orgId, Integer maxRows) {
    MultiOrgSummaries orgSum = new MultiOrgSummaries();
    orgSum.mode = format;

    // check the metadata and see what results we should be showing
    Security_Health_Check_Config__mdt config = SecurityHealthCheckService.getSecurityHealthCheckConfig();

    if (config == null) {
      // for now, just return empty array
    } else if (config.multioss__Is_this_the_Central_org__c == true) {
      if (format == 'bydate') {
        orgSum.summaries = getSecurityCheckByDate(theDate);
      } else if (format == 'byorg') {
        orgSum.summaries = getSecurityCheckByOrg(orgId, maxRows);
      }
    } else {
      // this is a spoke org, so need to load for thisorg only
      orgSum.mode = 'thisorg';
      multioss__Security_Health_Check_Org__c tempOrg = getCurrentOrgOverview(UserInfo.getOrganizationId());
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
    List<multioss__Security_Health_Check__c> dailyChecks = [
      SELECT
        Id,
        Name,
        multioss__Score__c,
        multioss__Previous_Score__c,
        multioss__Check_Date__c,
        multioss__Org_Name__c,
        multioss__Org_Identifier__c,
        multioss__Security_Health_Check_Org__c,
        (
          SELECT
            Id,
            multioss__DurableId__c,
            Name,
            multioss__OrgValue__c,
            multioss__OrgValueRaw__c,
            multioss__RiskType__c,
            multioss__Security_Health_Check__c,
            multioss__Setting__c,
            multioss__SettingGroup__c,
            multioss__SettingRiskCategory__c,
            multioss__StandardValue__c,
            multioss__StandardValueRaw__c
          FROM Security_Health_Check_Risks__r
          WHERE multioss__Security_Health_Check__r.multioss__Check_Date__c = :theDate
          ORDER BY multioss__SettingRiskCategory__c, multioss__DurableId__c
        )
      FROM Security_Health_Check__c
      WHERE multioss__Check_Date__c = :theDate
      WITH SECURITY_ENFORCED
    ];

    // Get the list of active orgs and create a default DOS for each
    List<Security_Health_Check_Org__c> activeOrgs = getActiveSecurityHealthCheckOrgs();

    Integer i = 0;

    for (Security_Health_Check_Org__c activeOrg : activeOrgs) {
      DailyOrgSummary dosDefault = new DailyOrgSummary();
      dosDefault.org = activeOrg;

      Security_Health_Check__c shc = new Security_Health_Check__c();
      shc.multioss__Check_Date__c = theDate;
      shc.multioss__Org_Identifier__c = activeOrg.Actual_Org_Id__c;
      shc.multioss__security_health_check_Org__c = activeOrg.Id;
      shc.multioss__Score__c = -1; // indicates that there is no data for this date
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

      for (Security_Health_Check_Risk__c orgRisk : check.multioss__Security_Health_Check_Risks__r) {
        orgRisks.put(orgRisk.multioss__DurableId__c, orgRisk);
      }

      Integer index = 0;
      for (DailyOrgSummary dos : results) {
        if (dos.org.Id == check.multioss__Security_Health_Check_Org__c) {
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
      shc.multioss__Check_Date__c = myDate;
      shc.multioss__Org_Identifier__c = orgId;
      shc.multioss__security_health_check_Org__c = org.Id;
      shc.multioss__Score__c = -1; // indicates that there is no data for this date
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
          multioss__Security_Health_Check_Org__c,
          multioss__Score__c,
          multioss__Check_Date__c,
          multioss__Change__c,
          multioss__Org_Name__c,
          multioss__Org_Identifier__c,
          (
            SELECT
              Id,
              multioss__DurableId__c,
              Name,
              multioss__OrgValue__c,
              multioss__OrgValueRaw__c,
              multioss__RiskType__c,
              multioss__Previous_Rating__c,
              multioss__Change__c,
              multioss__Security_Health_Check__c,
              multioss__Setting__c,
              multioss__SettingGroup__c,
              multioss__SettingRiskCategory__c,
              multioss__StandardValue__c,
              multioss__StandardValueRaw__c
            FROM multioss__Security_Health_Check_Risks__r
            ORDER BY multioss__SettingRiskCategory__c, multioss__DurableId__c
          )
        FROM multioss__Security_Health_Check__c
        WITH SECURITY_ENFORCED
        ORDER BY multioss__Check_Date__c DESC
        LIMIT :maxRows
      ];
    } else {
      dailyChecks = [
        SELECT
          Id,
          Name,
          multioss__Security_Health_Check_Org__c,
          multioss__Score__c,
          multioss__Check_Date__c,
          multioss__Change__c,
          multioss__Org_Name__c,
          multioss__Org_Identifier__c,
          (
            SELECT
              Id,
              multioss__DurableId__c,
              Name,
              multioss__OrgValue__c,
              multioss__OrgValueRaw__c,
              multioss__RiskType__c,
              multioss__Previous_Rating__c,
              multioss__Change__c,
              multioss__Security_Health_Check__c,
              multioss__Setting__c,
              multioss__SettingGroup__c,
              multioss__SettingRiskCategory__c,
              multioss__StandardValue__c,
              multioss__StandardValueRaw__c
            FROM multioss__Security_Health_Check_Risks__r
            ORDER BY multioss__SettingRiskCategory__c, multioss__DurableId__c
          )
        FROM multioss__Security_Health_Check__c
        WHERE multioss__Security_Health_Check_Org__c = :orgId
        WITH SECURITY_ENFORCED
        ORDER BY multioss__Check_Date__c DESC
        LIMIT :maxRows
      ];
    }

    // generate the daily summaries

    for (multioss__Security_Health_Check__c check : dailyChecks) {
      // first set the default list of values
      Map<String, multioss__Security_Health_Check_Risk__c> orgRisks = defaultCategories.clone();

      for (multioss__Security_Health_Check_Risk__c orgRisk : check.multioss__Security_Health_Check_Risks__r) {
        orgRisks.put(orgRisk.multioss__DurableId__c, orgRisk);
      }

      DailyOrgSummary dos = new DailyOrgSummary();
      dos.healthCheck = check;
      dos.iterator = check.Id;
      dos.org = org;

      //     dos.risks = orgRisks;

      if (dailySummaryMap.containsKey(dos.healthCheck.multioss__Check_Date__c)) {
        dailySummaryMap.put(dos.healthCheck.multioss__Check_Date__c, dos);
      }
    }

    return dailySummaryMap.values();
  }

  /* Get a list of the default risk categories based on the existing data */
  static Map<String, multioss__Security_Health_Check_Risk__c> getDefaultRiskCategories() {
    // Get the latest security health check record
    List<multioss__Security_Health_Check__c> securityHealthChecks = [SELECT Id FROM multioss__Security_Health_Check__c ORDER BY CreatedDate DESC LIMIT 1];
    multioss__Security_Health_Check__c securityHealthCheck = (securityHealthChecks.size() == 1) ? securityHealthChecks.get(0) : null;

    // Get a list of all possible risks, sorted by SettingRiskCategory__c and DurableId__c associated to the latest health check
    List<AggregateResult> risks = [
      SELECT multioss__SettingRiskCategory__c, multioss__DurableId__c
      FROM multioss__Security_Health_Check_Risk__c
      WHERE multioss__Security_Health_Check__c = :securityHealthCheck.Id
      WITH SECURITY_ENFORCED
      GROUP BY multioss__SettingRiskCategory__c, multioss__DurableId__c
      ORDER BY multioss__SettingRiskCategory__c, multioss__DurableId__c
    ];
    // Define the baseline list of categories to be populated later from data. Need this to ensure UI is consistent
    Map<String, multioss__Security_Health_Check_Risk__c> defaultCategories = new Map<String, multioss__security_Health_Check_Risk__c>();

    for (AggregateResult risk : risks) {
      String category = (String) risk.get('multioss__SettingRiskCategory__c');
      String durableId = (String) risk.get('multioss__DurableId__c');
      defaultCategories.put(durableId, null);
    }

    return defaultCategories;
  }

  /* Get a list of the summary Categories */
  public static Map<String, List<String>> getSummaryCategories() {
    List<multioss__Security_Health_Check__c> securityHealthChecks = [SELECT Id FROM multioss__Security_Health_Check__c ORDER BY CreatedDate DESC LIMIT 1];
    multioss__Security_Health_Check__c securityHealthCheck = (securityHealthChecks.size() == 1) ? securityHealthChecks.get(0) : null;

    // Get a list of all possible risks, sorted by SettingRiskCategory__c and DurableId__c
    List<AggregateResult> risks = [
      SELECT multioss__SettingRiskCategory__c, multioss__DurableId__c
      FROM multioss__Security_Health_Check_Risk__c
      WHERE multioss__Security_Health_Check__c = :securityHealthCheck.Id
      WITH SECURITY_ENFORCED
      GROUP BY multioss__SettingRiskCategory__c, multioss__DurableId__c
      ORDER BY multioss__SettingRiskCategory__c, multioss__DurableId__c
    ];
    // Define the baseline list of categories to be populated later from data. Need this to ensure UI is consistent
    Map<String, List<String>> summaryCategories = new Map<String, List<String>>();

    for (AggregateResult risk : risks) {
      String category = (String) risk.get('multioss__SettingRiskCategory__c');
      String durableId = (String) risk.get('multioss__DurableId__c');

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
  static multioss__Security_Health_Check_Org__c getSecurityHealthCheckOrgById(String orgId) {
    multioss__Security_Health_Check_Org__c org = new multioss__Security_Health_Check_Org__c();

    List<multioss__Security_Health_Check_Org__c> orgs = [
      SELECT Id, Name, CreatedDate, multioss__Category__c, multioss__Active__c, multioss__Actual_Org_Id__c, multioss__Token__c, multioss__Description__c
      FROM multioss__Security_Health_Check_Org__c
      WHERE Id = :orgId
      WITH SECURITY_ENFORCED
    ];

    if (orgs.size() > 0) {
      org = orgs[0];
    }

    return org;
  }

  static List<multioss__Security_Health_Check_Org__c> getActiveSecurityHealthCheckOrgs() {
    return [
      SELECT Id, Name, multioss__Active__c, multioss__Category__C, multioss__Actual_Org_Id__c, multioss__Description__c, multioss__Data_Classification__c
      FROM multioss__Security_Health_Check_Org__c
      WHERE multioss__ACTIVE__c = TRUE
      WITH SECURITY_ENFORCED
      ORDER BY NAME
    ];
  }

  @AuraEnabled(Cacheable=true)
  public static multioss__Security_Health_Check_Task__c getTaskDetails(Id taskId) {
    List<multioss__Security_Health_Check_Task__c> securityHealthCheckTasks = [
      SELECT
        CreatedById,
        CreatedDate,
        Id,
        multioss__Assigned_To__c,
        multioss__Assigned_To__r.Name,
        multioss__Related_To_Risk__r.multioss__DurableId__c,
        multioss__Related_To_Org__r.multioss__External_Contact_Email__c,
        multioss__Completed_Date__c,
        multioss__Due_Date__c,
        multioss__Related_To_Org__c,
        multioss__Related_To_Org__r.Name,
        multioss__Related_To_Org__r.multioss__Category__c,
        multioss__Related_To_Risk__c,
        multioss__Related_To_Risk__r.Name,
        multioss__Related_To_Risk__r.multioss__OrgValue__c,
        multioss__Related_To_Risk__r.multioss__Setting__c,
        multioss__Related_To_Risk__r.multioss__StandardValue__c,
        multioss__Severity__c,
        multioss__Status__c,
        multioss__Title__c
      FROM multioss__Security_Health_Check_Task__c
      WHERE Id = :taskId
      WITH SECURITY_ENFORCED
    ];
    multioss__Security_Health_Check_Task__c securityHealthCheckTask = (securityHealthCheckTasks.size() == 1) ? securityHealthCheckTasks.get(0) : null;

    return securityHealthCheckTask;
  }

  public static Organization getOrganization() {
    List<Organization> organizations = [SELECT Id, Name FROM Organization WITH SECURITY_ENFORCED LIMIT 1];
    Organization organization = (organizations.size() == 1) ? organizations.get(0) : null;

    return organization;
  }

  public static List<multioss__Security_Health_Check_Org__c> getAllSecurityHealthCheckOrgs() {
    List<multioss__Security_Health_Check_Org__c> securityHealthCheckOrgs = [
      SELECT Id, multioss__Latest_Score__c, multioss__Category__c
      FROM multioss__Security_Health_Check_Org__c
      WHERE multioss__Active__c = TRUE
      WITH SECURITY_ENFORCED
    ];

    return securityHealthCheckOrgs;
  }

  public static multioss__Security_Health_Check_Org__c getCurrentOrgOverview(Id organizationId) {
    List<multioss__Security_Health_Check_Org__c> securityHealthCheckOrgs = [
      SELECT Id, Name, multioss__Description__c, multioss__Point_of_Contact__c, multioss__Point_of_Contact__r.Name
      FROM multioss__Security_Health_Check_Org__c
      WHERE multioss__Actual_Org_Id__c = :organizationId
      WITH SECURITY_ENFORCED
      LIMIT 1
    ];
    multioss__Security_Health_Check_Org__c securityHealthCheckOrg = (securityHealthCheckOrgs.size() == 1) ? securityHealthCheckOrgs.get(0) : null;

    return securityHealthCheckOrg;
  }

  @AuraEnabled
  public static List<multioss__Security_Health_Check_Task__c> getSecurityHealthCheckTasks(Id selectedOrgId) {
    List<multioss__Security_Health_Check_Task__c> securityHealthCheckTasks = [
      SELECT
        Id,
        multioss__Assigned_To__c,
        multioss__Completed_Date__c,
        multioss__Description__c,
        multioss__Resolution__c,
        multioss__Assigned_Name__c,
        multioss__Assigned_To__r.Name,
        multioss__Due_Date__c,
        multioss__Related_To_Org__c,
        multioss__Related_To_Risk__c,
        Name,
        multioss__Severity__c,
        multioss__Status__c,
        multioss__Title__c
      FROM multioss__Security_Health_Check_Task__c
      WHERE multioss__Related_To_Org__c = :selectedOrgId
      WITH SECURITY_ENFORCED
      ORDER BY CreatedDate DESC
    ];

    return securityHealthCheckTasks;
  }

  public static multioss__Security_Health_Check__c getLatestSecurityHealthCheck(Id securityHealthCheckOrgId) {
    List<multioss__Security_Health_Check__c> securityHealthChecks = [
      SELECT Id, multioss__Score__c, multioss__Check_Date__c, CreatedDate
      FROM multioss__Security_Health_Check__c
      WHERE multioss__Security_Health_Check_Org__c = :securityHealthCheckOrgId AND multioss__Check_Date__c != TOMORROW
      WITH SECURITY_ENFORCED
      ORDER BY CreatedDate DESC
      LIMIT 1
    ];
    multioss__Security_Health_Check__c securityHealthCheck = (securityHealthChecks.size() == 1) ? securityHealthChecks.get(0) : null;
    //system.debug(securityHealthCheck);
    return securityHealthCheck;
  }

  public static multioss__Security_Health_Check__c getFirstSecurityHealthCheck(Id securityHealthCheckOrgId) {
    List<multioss__Security_Health_Check__c> securityHealthChecks = [
      SELECT Id, multioss__Check_Date__c
      FROM multioss__Security_Health_Check__c
      WHERE multioss__Security_Health_Check_Org__c = :securityHealthCheckOrgId
      WITH SECURITY_ENFORCED
      ORDER BY CreatedDate ASC
      LIMIT 1
    ];
    multioss__Security_Health_Check__c securityHealthCheck = (securityHealthChecks.size() == 1) ? securityHealthChecks.get(0) : null;

    return securityHealthCheck;
  }
}
