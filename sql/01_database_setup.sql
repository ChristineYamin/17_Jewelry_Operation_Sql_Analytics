-- Create project schemas

CREATE SCHEMA IF NOT EXISTS raw;
CREATE SCHEMA IF NOT EXISTS cleaned;
CREATE SCHEMA IF NOT EXISTS analytics;

-- Verify schemas

SELECT schema_name
FROM information_schema.schemata
WHERE schema_name IN ('raw', 'cleaned', 'analytics')
ORDER BY schema_name;