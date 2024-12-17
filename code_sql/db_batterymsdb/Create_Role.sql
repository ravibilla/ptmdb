USE batterymsdb;

-- Create the role
CREATE ROLE 'role_executestoredprocedure';

-- Grant execute permissions on all stored procedures in a specific database
GRANT EXECUTE ON batterymsdb.* TO 'role_executestoredprocedure';

-- Assign the role to a specific user
GRANT 'role_executestoredprocedure' TO 'ptmdbreader'@'%';
