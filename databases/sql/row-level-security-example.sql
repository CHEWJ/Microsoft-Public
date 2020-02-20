/* Rules:
i.e. in the database an RLS rule is set that

1. total number of rows is less than 10 return null

2. A segment within the total has less than say 4 so null is returned. I.e. lets assume Count Employees by Gender. If there are three values Male = 5, Female = 3, Not Defined = 3 then the result should be Male = 5, Female = Null, Not Defined = Null

3. if one segment returns null then no result should be returned. This is because you can calculate the result. I.e. Male = 5, Female = 5, Not Defined = 3. As per rule 2 this would be Male = 5, Female = 5 Note Defined = Null. However a user can calculate the result from the total. Therefore the result should be Male = 5, Female = 5.
*/

CREATE USER Manager WITHOUT LOGIN;
CREATE USER Manager2 WITHOUT LOGIN;
CREATE USER HR WITHOUT LOGIN;

CREATE TABLE Mock_Emps
  (
  EmpID int,
  Manager sysname,
  Emp varchar(10),
  Gender char(1)
  );

INSERT INTO Mock_Emps VALUES (1, 'Manager', 'F1', 'F'); 
INSERT INTO Mock_Emps VALUES (2, 'Manager', 'F2', 'F'); 
INSERT INTO Mock_Emps VALUES (3, 'Manager', 'F3', 'F'); 
INSERT INTO Mock_Emps VALUES (4, 'Manager', 'M4', 'M');
INSERT INTO Mock_Emps VALUES (5, 'Manager', 'M5', 'M'); 
INSERT INTO Mock_Emps VALUES (6, 'Manager', 'M6', 'M'); 
INSERT INTO Mock_Emps VALUES (7, 'Manager', 'M7', 'M');
INSERT INTO Mock_Emps VALUES (8, 'Manager', 'M8', 'M'); 
INSERT INTO Mock_Emps VALUES (9, 'Manager', 'M9', 'M'); 
INSERT INTO Mock_Emps VALUES (10, 'Manager', 'M10', 'M'); 
INSERT INTO Mock_Emps VALUES (11, 'Manager2', 'F11', 'F'); 
INSERT INTO Mock_Emps VALUES (12, 'Manager2', 'F12', 'F'); 
INSERT INTO Mock_Emps VALUES (13, 'Manager2', 'F13', 'F'); 
INSERT INTO Mock_Emps VALUES (14, 'Manager2', 'F14', 'F');
INSERT INTO Mock_Emps VALUES (15, 'Manager2', 'F15', 'F'); 
INSERT INTO Mock_Emps VALUES (16, 'Manager2', 'M16', 'M'); 
INSERT INTO Mock_Emps VALUES (17, 'Manager2', 'M17', 'M');
INSERT INTO Mock_Emps VALUES (18, 'Manager2', 'M18', 'M'); 
INSERT INTO Mock_Emps VALUES (19, 'Manager2', 'M19', 'M'); 
INSERT INTO Mock_Emps VALUES (20, 'Manager2', 'M20', 'M'); 
INSERT INTO Mock_Emps VALUES (21, 'Manager', 'N21', Null); 
INSERT INTO Mock_Emps VALUES (22, 'Manager', 'N22', Null); 
INSERT INTO Mock_Emps VALUES (23, 'Manager', 'N23', Null); 
INSERT INTO Mock_Emps VALUES (24, 'Manager', 'N24', Null); 
INSERT INTO Mock_Emps VALUES (25, 'Manager', 'N25', Null); 

SELECT * FROM Mock_Emps;
SELECT * FROM Mock_Emps where Manager = 'Manager';
SELECT * FROM Mock_Emps where Manager = 'Manager' AND Gender = 'F';

GRANT SELECT ON Mock_Emps TO Manager;  
GRANT SELECT ON Mock_Emps TO Manager2;  
GRANT SELECT ON Mock_Emps TO HR;
GO

CREATE SCHEMA Mock_EmpSecurity;  
GO

ALTER FUNCTION Mock_EmpSecurity.fn_securitypredicate(@Manager as sysname, @Gender AS char(1))  
    RETURNS TABLE  
    WITH SCHEMABINDING  
AS RETURN (
    SELECT 1 AS fn_securitypredicate_result
    FROM dbo.Mock_Emps
    WHERE (USER_NAME() = @Manager
           AND @Gender IS NOT NULL
           AND (SELECT 1
                FROM dbo.Mock_Emps
                WHERE USER_NAME() = Manager
                  AND @Gender = Gender
                GROUP BY Gender
                HAVING count(*) >= 4) = 1
          )
        OR USER_NAME() = 'HR'
    HAVING COUNT(*) >= 10
); 
GO

CREATE SECURITY POLICY EmpFilter  
ADD FILTER PREDICATE Mock_EmpSecurity.fn_securitypredicate(Manager, Gender)
ON dbo.Mock_Emps  
WITH (STATE = ON);

GRANT SELECT ON Mock_EmpSecurity.fn_securitypredicate TO Manager;  
GRANT SELECT ON Mock_EmpSecurity.fn_securitypredicate TO Manager2;  
GRANT SELECT ON Mock_EmpSecurity.fn_securitypredicate TO HR;

EXECUTE AS USER = 'Manager';  
SELECT * FROM Mock_Emps;
REVERT;  

EXECUTE AS USER = 'Manager2';  
SELECT * FROM Mock_Emps;
REVERT;  

EXECUTE AS USER = 'HR';  
SELECT * FROM Mock_Emps;
REVERT;
