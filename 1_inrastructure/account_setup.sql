-- =============================================================================
-- ACCOUNT ADMINISTRATION - NETWORK POLICIES & SECURITY SETTINGS
-- =============================================================================

USE ROLE ACCOUNTADMIN;

-- =============================================================================
-- SECTION 1: SECURITY SCHEMA SETUP
-- =============================================================================

CREATE DATABASE IF NOT EXISTS Healthcare_DB;
CREATE SCHEMA IF NOT EXISTS Healthcare_DB.NETWORK_SECURITY;

-- =============================================================================
-- SECTION 2: NETWORK RULE AND POLICY (Modern Approach)
-- =============================================================================

-- Single Network Rule
CREATE OR REPLACE NETWORK RULE Healthcare_DB.NETWORK_SECURITY.HCLS_ALLOWED_IPS_RULE
    MODE = INGRESS
    TYPE = IPV4
    VALUE_LIST = ('0.0.0.0/0')
    COMMENT = 'Allowed IP addresses for HCLS access';

-- Single Network Policy
CREATE OR REPLACE NETWORK POLICY HCLS_NETWORK_POLICY
    ALLOWED_NETWORK_RULE_LIST = (
        'Healthcare_DB.NETWORK_SECURITY.HCLS_ALLOWED_IPS_RULE'
    )
    COMMENT = 'HCLS network policy';

-- =============================================================================
-- SECTION 4: ACCOUNT-LEVEL SECURITY SETTINGS
-- =============================================================================

-- Enable MFA enforcement for account (optional - uncomment to enable)
-- ALTER ACCOUNT SET REQUIRE_MFA = TRUE;

-- Set session timeout (15 minutes of inactivity)
ALTER ACCOUNT SET CLIENT_SESSION_KEEP_ALIVE = FALSE;
--ALTER ACCOUNT SET SESSION_POLICY_EVAL_ON_LOGIN = TRUE;

-- =============================================================================
-- SECTION 5: SESSION POLICIES
-- =============================================================================

CREATE OR REPLACE SESSION POLICY Healthcare_DB.NETWORK_SECURITY.STANDARD_SESSION_POLICY
    SESSION_IDLE_TIMEOUT_MINS = 30
    SESSION_UI_IDLE_TIMEOUT_MINS = 15
    COMMENT = 'Standard session timeout policy';

CREATE OR REPLACE SESSION POLICY Healthcare_DB.NETWORK_SECURITY.STRICT_SESSION_POLICY
    SESSION_IDLE_TIMEOUT_MINS = 15
    SESSION_UI_IDLE_TIMEOUT_MINS = 10
    COMMENT = 'Strict session timeout for sensitive access';

-- =============================================================================
-- SECTION 6: PASSWORD POLICIES
-- =============================================================================

CREATE OR REPLACE PASSWORD POLICY Healthcare_DB.NETWORK_SECURITY.STANDARD_PASSWORD_POLICY
    PASSWORD_MIN_LENGTH = 12
    PASSWORD_MAX_LENGTH = 256
    PASSWORD_MIN_UPPER_CASE_CHARS = 1
    PASSWORD_MIN_LOWER_CASE_CHARS = 1
    PASSWORD_MIN_NUMERIC_CHARS = 1
    PASSWORD_MIN_SPECIAL_CHARS = 1
    PASSWORD_MIN_AGE_DAYS = 1
    PASSWORD_MAX_AGE_DAYS = 90
    PASSWORD_MAX_RETRIES = 5
    PASSWORD_LOCKOUT_TIME_MINS = 30
    PASSWORD_HISTORY = 12
    COMMENT = 'Standard password policy for HCLS users';

CREATE OR REPLACE PASSWORD POLICY Healthcare_DB.NETWORK_SECURITY.STRICT_PASSWORD_POLICY
    PASSWORD_MIN_LENGTH = 16
    PASSWORD_MAX_LENGTH = 256
    PASSWORD_MIN_UPPER_CASE_CHARS = 2
    PASSWORD_MIN_LOWER_CASE_CHARS = 2
    PASSWORD_MIN_NUMERIC_CHARS = 2
    PASSWORD_MIN_SPECIAL_CHARS = 2
    PASSWORD_MIN_AGE_DAYS = 1
    PASSWORD_MAX_AGE_DAYS = 60
    PASSWORD_MAX_RETRIES = 3
    PASSWORD_LOCKOUT_TIME_MINS = 60
    PASSWORD_HISTORY = 24
    COMMENT = 'Strict password policy for admin users';

-- =============================================================================
-- SECTION 7: APPLY POLICIES TO ACCOUNT/USERS
-- =============================================================================

-- Apply password policy to account (all users inherit unless overridden)
ALTER ACCOUNT SET PASSWORD POLICY Healthcare_DB.NETWORK_SECURITY.STANDARD_PASSWORD_POLICY;

-- Apply session policy to account
ALTER ACCOUNT SET SESSION POLICY Healthcare_DB.NETWORK_SECURITY.STANDARD_SESSION_POLICY;

-- Apply network policy to specific users (example)
-- ALTER USER ETL_SERVICE_USER SET NETWORK_POLICY = Healthcare_DB.NETWORK_SECURITY._ETL_POLICY;
-- ALTER USER DATA_PARTNER_USER SET NETWORK_POLICY = Healthcare_DB.NETWORK_SECURITY.HCLS_PARTNER_POLICY;

-- Apply strict policies to admin users (example)
-- ALTER USER ADMIN_USER SET PASSWORD POLICY = Healthcare_DB.NETWORK_SECURITY.STRICT_PASSWORD_POLICY;
-- ALTER USER ADMIN_USER SET SESSION POLICY = Healthcare_DB.NETWORK_SECURITY.STRICT_SESSION_POLICY;

-- =============================================================================
-- SECTION 8: AUTHENTICATION POLICIES
-- =============================================================================

CREATE OR REPLACE AUTHENTICATION POLICY Healthcare_DB.NETWORK_SECURITY.MFA_REQUIRED_POLICY
    AUTHENTICATION_METHODS = ('PASSWORD')
    MFA_ENROLLMENT = 'REQUIRED'
    CLIENT_TYPES = ('SNOWFLAKE_UI', 'SNOWSQL', 'DRIVERS')
    SECURITY_INTEGRATIONS = ()
    COMMENT = 'Require MFA for interactive logins';

CREATE OR REPLACE AUTHENTICATION POLICY Healthcare_DB.NETWORK_SECURITY.SERVICE_ACCOUNT_POLICY
    AUTHENTICATION_METHODS = ('PASSWORD')
    MFA_ENROLLMENT = 'OPTIONAL'
    CLIENT_TYPES = ('DRIVERS')
    SECURITY_INTEGRATIONS = ()
    COMMENT = 'Service account authentication (no MFA required)';

--=============================================================================
-- SECTION 9: VERIFICATION COMMANDS
-- =============================================================================

-- Show all network rules
SHOW NETWORK RULES IN SCHEMA Healthcare_DB.NETWORK_SECURITY;

-- Show all network policies
SHOW NETWORK POLICIES;

-- Show password policies
SHOW PASSWORD POLICIES IN SCHEMA Healthcare_DB.NETWORK_SECURITY;

-- Show session policies
SHOW SESSION POLICIES IN SCHEMA Healthcare_DB.NETWORK_SECURITY;

-- show authentication policies
SHOW AUTHENTICATION POLICIES IN SCHEMA Healthcare_DB.NETWORK_SECURITY;

-- describe a specific network policy
DESC NETWORK POLICY HCLS_NETWORK_POLICY;

-- check account-level parameters
SHOW PARAMETERS LIKE '%POLICY%' IN ACCOUNT;
SHOW PARAMETERS LIKE '%NETWORK%' IN ACCOUNT;
