# Day 3 DB + PHP Notes

## Database
- Database name: trainingdb
- Tables: users, tickets
- Relationship: tickets.user_id -> users.id

## SQL files
- sql/schema.sql
- sql/seed.sql

## App
- PHP page shows seeded data from joined users + tickets
- PHP form inserts one new ticket
- Basic input validation implemented
- Prepared statements used with PDO

## DB user grants (sanitized)
```sql
CREATE USER 'trainingapp'@'localhost' IDENTIFIED BY '***';
GRANT SELECT, INSERT, UPDATE, DELETE ON trainingdb.* TO 'trainingapp'@'localhost';
SHOW GRANTS FOR 'trainingapp'@'localhost';

###Security

Real DB credentials are stored in config.php locally.

Real credentials are not committed to Git.



## Run order

 After creating the files, run them in this order:

```
sudo mysql

```

##Then inside MySQL:

```
SOURCE /full/path/to/sql/schema.sql;
SOURCE /full/path/to/sql/seed.sql;
SHOW GRANTS FOR 'trainingapp'@'localhost';
USE trainingdb;
SELECT * FROM users;
SELECT * FROM tickets;
```

##Then open in browser:
```
http://localhost/day3/
```

