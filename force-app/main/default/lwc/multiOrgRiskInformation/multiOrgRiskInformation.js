import { LightningElement, api, track } from "lwc";

export default class MultiOrgRiskInformation extends LightningElement {
  @api riskKey;
  urls = [];
  helpUrls = [];

  connectedCallback() {
    //   console.log('Inside connectedCallBack');

    let myDefaultList = [
      { unid: 0, riskKey: "CertificateAndKeyManagement.expiredCert", name: "Overview of Certificates", url: "https://help.salesforce.com/articleView?id=000329338&type=1&mode=1" },
      {
        unid: 1,
        riskKey: "FileUploadAndDownloadSecurity.hybridSecurityRiskFileTypes",
        name: "Configure File Security Settings",
        url: "https://help.salesforce.com/articleView?id=admin_files_type_security.htm&type=5"
      },
      {
        unid: 2,
        riskKey: "FileUploadAndDownloadSecurity.hybridSecurityRiskFileTypes",
        name: "Guide to MIME types",
        url: "https://help.salesforce.com/articleView?id=000332030&language=en_US&type=1&mode=1"
      },
      {
        unid: 3,
        riskKey: "PasswordPolicies.maxLoginAttempts",
        name: "Set Password Policies",
        url: "https://developer.salesforce.com/docs/atlas.en-us.securityImplGuide.meta/securityImplGuide/admin_password.htm"
      },
      { unid: 4, riskKey: "PasswordPolicies.maxLoginAttempts", name: "Monitor Login History", url: "https://help.salesforce.com/articleView?id=users_login_history.htm&type=5" },
      {
        unid: 5,
        riskKey: "SessionSettings.clickjackNonSetup",
        name: "Prevent Clickjacking",
        url: "https://trailhead.salesforce.com/en/content/learn/modules/secdev_application_logic_vulnerabilities/secdev_app_logic_clickjacking"
      },
      { unid: 6, riskKey: "SessionSettings.clickjackNonSetup", name: "Enabling for Site.com", url: "https://help.salesforce.com/articleView?id=siteforce_clickjacking_enable.htm&type=5" },
      {
        unid: 7,
        riskKey: "SessionSettings.clickjackNonSetup",
        name: "Considerations for Field Service Lightning",
        url: "https://help.salesforce.com/articleView?id=000351889&language=en_US&mode=1&type=1"
      },
      {
        unid: 8,
        riskKey: "SessionSettings.clickjackSetup",
        name: "Security Implementation Guide",
        url: "https://developer.salesforce.com/docs/atlas.en-us.securityImplGuide.meta/securityImplGuide/admin_sessions.htm"
      },
      { unid: 9, riskKey: "SessionSettings.clickjackVisualForceHeaders", name: "Knowledge Article", url: "https://help.salesforce.com/articleView?id=000316904&type=1&mode=1" },
      { unid: 10, riskKey: "SessionSettings.clickjackVisualForceNoHeaders", name: "Console Considerations", url: "https://help.salesforce.com/articleView?id=000318543&type=1&mode=1" },
      { unid: 12, riskKey: "SessionSettings.csrfGet", name: "CSRF Protection Settings", url: "https://help.salesforce.com/articleView?id=000335668&type=1&mode=1" },
      { unid: 13, riskKey: "SessionSettings.csrfGet", name: "Salesforce Connect Considerations", url: "https://help.salesforce.com/articleView?id=odata_considerations_csrf.htm&type=5" },
      { unid: 14, riskKey: "SessionSettings.csrfPost", name: "CSRF Protection Settings", url: "https://help.salesforce.com/articleView?id=000335668&type=1&mode=1" },
      { unid: 15, riskKey: "SessionSettings.csrfPost", name: "Salesforce Connect Considerations", url: "https://help.salesforce.com/articleView?id=odata_considerations_csrf.htm&type=5" },
      { unid: 16, riskKey: "SessionSettings.requireHttpOnly", name: "Consideration for Console", url: "https://success.salesforce.com/ideaView?id=0873A000000lLfcQAE" },
      { unid: 17, riskKey: "SessionSettings.enableSmsIdentity", name: "Knowledge Article", url: "https://help.salesforce.com/articleView?id=000329528&language=en_US&type=1&mode=1" },
      {
        unid: 18,
        riskKey: "SessionSettings.enableSmsIdentity",
        name: "Configuring Identity Verification",
        url: "https://help.salesforce.com/articleView?id=security_auth_setup_identity_verification.htm&type=5"
      },
      { unid: 19, riskKey: "SessionSettings.enableSmsIdentity", name: "How it works", url: "https://help.salesforce.com/articleView?id=000332387&language=en_US&type=1&mode=1" },
      { unid: 20, riskKey: "SessionSettings.lockSessionsToDomain", name: "Knowledge Article", url: "https://help.salesforce.com/articleView?id=000338725&type=1&mode=1" },
      {
        unid: 21,
        riskKey: "SessionSettings.requireHttpOnly",
        name: "Consideration for AJAX Toolkit",
        url: "https://developer.salesforce.com/docs/atlas.en-us.securityImplGuide.meta/securityImplGuide/admin_sessions.htm"
      },
      { unid: 22, riskKey: "SessionSettings.requireSecureConnections", name: "Knowledge Article", url: "https://help.salesforce.com/articleView?id=000339312&type=1&mode=1" },
      {
        unid: 23,
        riskKey: "SessionSettings.requireSecureConnections",
        name: "Winter 15: Release Notes",
        url: "https://releasenotes.docs.salesforce.com/en-us/winter15/release-notes/rn_forcecom_sites_https_require.htm"
      },
      { unid: 24, riskKey: "SessionSettings.requireSecureConnections", name: "Salesforce Sites Security", url: "https://help.salesforce.com/articleView?id=sites_security.htm&type=5" },
      {
        unid: 25,
        riskKey: "SessionSettings.requireSecureConnections",
        name: "Spring 20: Critical Update",
        url: "https://releasenotes.docs.salesforce.com/en-us/spring20/release-notes/rn_general_https_required.htm"
      },
      { unid: 26, riskKey: "SessionSettings.upgradeInsecureRequests", name: "Session Security Settings", url: "https://help.salesforce.com/articleView?id=admin_sessions.htm" },
      {
        unid: 27,
        riskKey: "SharingSettings.orgWideDefaults",
        name: "Setting External Organization-Wide Defaults",
        url: "https://help.salesforce.com/articleView?id=security_owd_external_setting.htm&type=5"
      },
      { unid: 28, riskKey: "SharingSettings.orgWideDefaults", name: "Organization-Wide Defaults Explained", url: "https://help.salesforce.com/articleView?id=security_owd_external.htm&type=5" },
      { unid: 29, riskKey: "LoginAccessPolicies.adminLoginAsAnyUser", name: "Considerations for this Setting", url: "https://help.salesforce.com/articleView?id=000334140&type=1&mode=1" },
      { unid: 30, riskKey: "LoginAccessPolicies.adminLoginAsAnyUser", name: "Control Login Access", url: "https://help.salesforce.com/articleView?id=controlling_login_access.htm&type=5" },
      { unid: 31, riskKey: "LoginAccessPolicies.adminLoginAsAnyUser", name: "Log In as Another User", url: "https://help.salesforce.com/articleView?id=logging_in_as_another_user.htm&type=5" },
      { unid: 32, riskKey: "PasswordPolicies.complexity", name: "Set Password Policies", url: "https://help.salesforce.com/articleView?id=admin_password.htm&type=5" },
      { unid: 33, riskKey: "PasswordPolicies.complexity", name: "Passwords Summary", url: "https://help.salesforce.com/articleView?id=security_overview_passwords.htm&type=5" },
      { unid: 34, riskKey: "PasswordPolicies.expiration", name: "Manage Password Expiration", url: "https://help.salesforce.com/articleView?id=000338935&type=1&mode=1" },
      { unid: 35, riskKey: "PasswordPolicies.expiration", name: "Set Password Policies", url: "https://help.salesforce.com/articleView?id=admin_password.htm&type=5" },
      { unid: 36, riskKey: "PasswordPolicies.history", name: "Set Password Policies", url: "https://help.salesforce.com/articleView?id=admin_password.htm&type=5" },
      { unid: 37, riskKey: "PasswordPolicies.minOneDayPasswordLifetime", name: "Set Password Policies", url: "https://help.salesforce.com/articleView?id=admin_password.htm&type=5" },
      { unid: 38, riskKey: "PasswordPolicies.minPasswordLength", name: "Set Password Policies", url: "https://help.salesforce.com/articleView?id=admin_password.htm&type=5" },
      { unid: 39, riskKey: "PasswordPolicies.minPasswordLength", name: "Passwords Summary", url: "https://help.salesforce.com/articleView?id=security_overview_passwords.htm&type=5" },
      {
        unid: 40,
        riskKey: "SessionSettings.contentSniffingProtection",
        name: "Configuring Site Properties",
        url: "https://help.salesforce.com/articleView?id=siteforce_website_properties.htm&type=5"
      },
      {
        unid: 41,
        riskKey: "SessionSettings.contentSniffingProtection",
        name: "Known Issue with Oauth",
        url:
          "https://success.salesforce.com/issues_view?id=a1p3A0000008w9KQAQ&title=content-type-is-not-set-when-content-sniffing-protection-enabled-and-oauth-web-server-flow-invoked-with-immediate-true"
      },
      { unid: 42, riskKey: "SessionSettings.enforceLoginIp", name: "Knowledge Article", url: "https://help.salesforce.com/articleView?id=000339125&type=1&mode=1" },
      { unid: 43, riskKey: "SessionSettings.enforceLoginIp", name: "Restrict Where and When Users Login", url: "https://help.salesforce.com/articleView?id=admin_loginrestrict.htm&type=5" },
      { unid: 44, riskKey: "SessionSettings.forceRelogin", name: "Considerations", url: "https://help.salesforce.com/articleView?id=000312323&language=en_US&type=1&mode=1" },
      { unid: 45, riskKey: "SessionSettings.xssProtection", name: "Platform Security FAQs", url: "https://help.salesforce.com/articleView?id=000318378&language=en_US&type=1&mode=1" },
      { unid: 46, riskKey: "PasswordPolicies.lockoutInterval", name: "Set Password Policies", url: "https://help.salesforce.com/articleView?id=admin_password.htm&type=5" },
      { unid: 47, riskKey: "PasswordPolicies.obscureSecretAnswer", name: "Set Password Policies", url: "https://help.salesforce.com/articleView?id=admin_password.htm&type=5" },
      { unid: 48, riskKey: "PasswordPolicies.questionRestriction", name: "Set Password Policies", url: "https://help.salesforce.com/articleView?id=admin_password.htm&type=5" },
      { unid: 49, riskKey: "RemoteSiteSettings.remoteSiteSettings", name: "Configuring Remote Sites", url: "https://help.salesforce.com/articleView?id=configuring_remoteproxy.htm&type=5" },
      { unid: 50, riskKey: "SessionSettings.forceLogoutOnTimeout", name: "Session Security", url: "https://help.salesforce.com/articleView?id=security_overview_sessions.htm&type=5" },
      { unid: 51, riskKey: "SessionSettings.forceLogoutOnTimeout", name: "Modify Session Settings", url: "https://help.salesforce.com/articleView?id=admin_sessions.htm&type=5" },
      { unid: 52, riskKey: "SessionSettings.forceLogoutOnTimeout", name: "Session timeout issues", url: "https://help.salesforce.com/articleView?id=000317746&language=en_US&type=1&mode=1" },
      { unid: 53, riskKey: "SessionSettings.icOn2faRegistration", name: "Two-Factor Authentication", url: "https://help.salesforce.com/articleView?id=security_overview_2fa.htm&type=5" },
      { unid: 54, riskKey: "SessionSettings.icOn2faRegistration", name: "Set Up Two-Factor Authentication", url: "https://help.salesforce.com/articleView?id=security_2fa_config.htm&type=5" },
      {
        unid: 55,
        riskKey: "SessionSettings.icOn2faRegistration",
        name: "Configure Identity Verification Settings",
        url: "https://help.salesforce.com/articleView?id=security_auth_setup_identity_verification.htm&type=5"
      },
      { unid: 56, riskKey: "SessionSettings.icOnEmailChange", name: "Recommendations on Settings", url: "https://help.salesforce.com/articleView?id=000324664&type=1&mode=1" },
      { unid: 57, riskKey: "SessionSettings.timeout", name: "Session Security", url: "https://help.salesforce.com/articleView?id=security_overview_sessions.htm&type=5" },
      { unid: 58, riskKey: "SessionSettings.timeout", name: "Modify Session Settings", url: "https://help.salesforce.com/articleView?id=admin_sessions.htm&type=5" },
      { unid: 59, riskKey: "SessionSettings.timeout", name: "Session timeout issues", url: "https://help.salesforce.com/articleView?id=000317746&language=en_US&type=1&mode=1" },
      { unid: 60, riskKey: "CertificateAndKeyManagement.certExpiration", name: "Certificates and Keys", url: "https://help.salesforce.com/articleView?id=security_keys_about.htm&type=5" },
      { unid: 61, riskKey: "CertificateAndKeyManagement.keySize", name: "Certificates and Keys", url: "https://help.salesforce.com/articleView?id=security_keys_about.htm&type=5" },
      { unid: 62, riskKey: "SessionSettings.hstsOnForcecomSites", name: "Enable Browser Security Settings", url: "https://help.salesforce.com/articleView?id=browser_security.htm&type=5" }
    ];
    // console.log('created list and is ' + myDefaultList.length);
    this.helpUrls = myDefaultList;
  }

  get riskKeyDisplay() {
    // console.log("risk url: " + this.riskKey);

    let riskUrls = [];

    for (var myCounter = 0; myCounter < this.helpUrls.length; myCounter++) {
      //console.log('Checking entry ' + myCounter);
      if (this.helpUrls[myCounter].riskKey === this.riskKey) {
        //console.log('Added risk url to list');
        riskUrls.push(this.helpUrls[myCounter]);
      }
    }

    this.urls = JSON.parse(JSON.stringify(riskUrls));

    return this.urls.length > 0;
  }

  openDocument(event) {
    let link = event.currentTarget.dataset.id;

    window.open(link, "_blank");
  }
}
