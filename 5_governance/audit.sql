-- =============================================================================
-- AUDIT TRACKING - LOGIN, GRANTS & USER MONITORING
-- =============================================================================

USE ROLE ACCOUNTADMIN;
USE WAREHOUSE COMPUTE_WH;

-- =============================================================================
-- VIEW 1: LOGIN AUDIT (All login tracking)
-- =============================================================================

CREATE OR REPLACE VIEW Healthcare_DB.GOVERNANCE_SCHEMA.V_LOGIN_AUDIT AS
SELECT 
    event_timestamp,
    user_name,
    client_ip,
    reported_client_type,
    first_authentication_factor,
    is_success,
    error_code,
    error_message
FROM SNOWFLAKE.ACCOUNT_USAGE.LOGIN_HISTORY
WHERE event_timestamp >= DATEADD(DAY, -30, CURRENT_TIMESTAMP())
ORDER BY event_timestamp DESC;

-- =============================================================================
-- VIEW 2: LOGIN SUMMARY (Aggregated login stats)
-- =============================================================================

CREATE OR REPLACE VIEW Healthcare_DB.GOVERNANCE_SCHEMA.V_LOGIN_SUMMARY AS
SELECT 
    user_name,
    COUNT(*) AS total_logins,
    SUM(CASE WHEN is_success = 'YES' THEN 1 ELSE 0 END) AS successful,
    SUM(CASE WHEN is_success = 'NO' THEN 1 ELSE 0 END) AS failed,
    COUNT(DISTINCT client_ip) AS unique_ips,
    MAX(event_timestamp) AS last_login
FROM SNOWFLAKE.ACCOUNT_USAGE.LOGIN_HISTORY
WHERE event_timestamp >= DATEADD(DAY, -30, CURRENT_TIMESTAMP())
GROUP BY user_name
ORDER BY failed DESC, total_logins DESC;

-- =============================================================================
-- VIEW 3: GRANTS AUDIT (All grants to roles)
-- =============================================================================

CREATE OR REPLACE VIEW Healthcare_DB.GOVERNANCE_SCHEMA.V_GRANTS_AUDIT AS
SELECT 
    created_on,
    privilege,
    granted_on AS object_type,
    name AS object_name,
    grantee_name,
    granted_by,
    grant_option
FROM SNOWFLAKE.ACCOUNT_USAGE.GRANTS_TO_ROLES
ORDER BY created_on DESC;

-- =============================================================================
-- VIEW 4: ROLE HIERARCHY & PRIVILEGED ACCESS
-- =============================================================================

CREATE OR REPLACE VIEW Healthcare_DB.GOVERNANCE_SCHEMA.V_ROLE_ACCESS AS
SELECT 
    grantee_name AS user_or_role,
    name AS role_granted,
    granted_by,
    created_on,
    CASE WHEN name IN ('ACCOUNTADMIN', 'SECURITYADMIN', 'SYSADMIN', 'USERADMIN') 
         THEN 'PRIVILEGED' ELSE 'STANDARD' END AS access_level
FROM SNOWFLAKE.ACCOUNT_USAGE.GRANTS_TO_ROLES
WHERE privilege = 'USAGE' AND granted_on = 'ROLE'
ORDER BY access_level DESC, role_granted, grantee_name;

-- =============================================================================
-- VIEW 5: USER INVENTORY (All user details and status)
-- =============================================================================

CREATE OR REPLACE VIEW Healthcare_DB.GOVERNANCE_SCHEMA.V_USER_INVENTORY AS
SELECT 
    name AS user_name,
    email,
    default_role,
    created_on,
    last_success_login,
    DATEDIFF(DAY, last_success_login, CURRENT_TIMESTAMP()) AS days_since_login,
    disabled,
    CASE 
        WHEN disabled = 'true' THEN 'DISABLED'
        WHEN last_success_login IS NULL THEN 'NEVER_LOGGED_IN'
        WHEN last_success_login < DATEADD(DAY, -30, CURRENT_TIMESTAMP()) THEN 'INACTIVE'
        ELSE 'ACTIVE'
    END AS status,
    owner
FROM SNOWFLAKE.ACCOUNT_USAGE.USERS
WHERE deleted_on IS NULL
ORDER BY last_success_login DESC NULLS LAST;

-- =============================================================================
-- VIEW 6: DDL & SECURITY CHANGES AUDIT
-- =============================================================================

CREATE OR REPLACE VIEW Healthcare_DB.GOVERNANCE_SCHEMA.V_DDL_AUDIT AS
SELECT 
    start_time,
    user_name,
    role_name,
    query_type,
    database_name,
    schema_name,
    LEFT(query_text, 500) AS query_preview,
    execution_status
FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
WHERE query_type IN ('CREATE_TABLE', 'DROP_TABLE', 'ALTER_TABLE', 
                     'CREATE_VIEW', 'DROP_VIEW', 'CREATE_USER', 
                     'DROP_USER', 'ALTER_USER', 'CREATE_ROLE', 
                     'DROP_ROLE', 'GRANT', 'REVOKE')
    AND start_time >= DATEADD(DAY, -30, CURRENT_TIMESTAMP())
ORDER BY start_time DESC;

-- =============================================================================
-- VERIFICATION
-- =============================================================================

SHOW VIEWS IN SCHEMA Healthcare_DB.GOVERNANCE_SCHEMA;

SELECT * FROM Healthcare_DB.GOVERNANCE_SCHEMA.V_LOGIN_SUMMARY LIMIT 10;
SELECT * FROM Healthcare_DB.GOVERNANCE_SCHEMA.V_USER_INVENTORY WHERE status != 'ACTIVE';
SELECT * FROM Healthcare_DB.GOVERNANCE_SCHEMA.V_ROLE_ACCESS WHERE access_level = 'PRIVILEGED';

