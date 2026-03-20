# Day 3 Runbook

## Task Objective
Create a MySQL database named `trainingdb` with two related tables (`users` and `tickets`), seed sample data, create a least-privilege database user, build a simple PHP CRUD application with basic validation, and document the DB grants without exposing credentials.[web:352][web:356][web:359]

## Work Completed

### 1. Database design
Created a MySQL database named `trainingdb`.[web:352]  
Created two tables:
- `users`
- `tickets`[web:356]

Configured a relationship between the tables using a foreign key:
- `tickets.user_id -> users.id`.[web:356][web:428]

### 2. Schema file
Created `sql/schema.sql` containing:
- database creation,
- table creation,
- foreign key relationship,
- least-privilege DB user creation,
- privilege grant statements.[web:352][web:414]

### 3. Seed file
Created `sql/seed.sql` containing:
- sample users data,
- sample tickets data linked to users.[web:384][web:428]

### 4. Database user
Created a restricted MySQL user for the PHP application:
- username: `trainingapp`
- host: `localhost`.[web:352][web:414]

Granted only required permissions on `trainingdb`:
- `SELECT`
- `INSERT`
- `UPDATE`
- `DELETE`.[web:352][web:355]

### 5. PHP database config
Created `/var/www/website/day3/config.php` for the PDO database connection.[web:405][web:407]  
Used PDO with:
- exception mode,
- default associative fetch mode,
- UTF-8 charset.[web:405][web:407]

### 6. PHP CRUD app
Created `/var/www/website/day3/index.php`.[web:351][web:357]

Implemented:
- **Read**: display seeded records from joined `users` and `tickets` tables.[web:351][web:357]
- **Create**: add a new ticket using a form.[web:351][web:405]
- **Update**: edit an existing ticket.[web:351]
- **Delete**: remove an existing ticket.[web:351][web:423]

### 7. Validation and security
Added basic input validation for:
- required user,
- required title,
- valid status,
- required description.[web:351][web:405]

Used PDO prepared statements for safer database operations.[web:405][web:407]  
Did not store real credentials in documentation or Git-tracked notes.[web:352][web:414]

### 8. Documentation
Created `docs/day3-db-php.md` containing:
- database overview,
- file list,
- app feature summary,
- sanitized DB grant statements,
- security note about not storing credentials in Git.[web:352][web:414]

## Files Created

```text
sql/schema.sql
sql/seed.sql
/var/www/website/day3/config.php
/var/www/website/day3/index.php
docs/day3-db-php.md

### Main steps Performed

#Step 1: Created project folders
```
mkdir -p ~/project/sql
mkdir -p ~/project/docs
sudo mkdir -p /var/www/website/day3
```

#Step 2: Created schema file
```
nano ~/project/sql/schema.sql
CREATE DATABASE IF NOT EXISTS trainingdb;
USE trainingdb;

DROP TABLE IF EXISTS tickets;
DROP TABLE IF EXISTS users;

CREATE TABLE users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(150) NOT NULL UNIQUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE tickets (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    title VARCHAR(150) NOT NULL,
    status ENUM('open', 'in_progress', 'closed') NOT NULL DEFAULT 'open',
    description TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_tickets_user
        FOREIGN KEY (user_id) REFERENCES users(id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);

CREATE USER IF NOT EXISTS 'trainingapp'@'localhost' IDENTIFIED BY 'StrongPassword123!';
GRANT SELECT, INSERT, UPDATE, DELETE ON trainingdb.* TO 'trainingapp'@'localhost';
FLUSH PRIVILEGES;

```
#Step 3: Created seed file
```
nano ~/project/sql/seed.sql

USE trainingdb;

INSERT INTO users (name, email) VALUES
('Amit Sharma', 'amit@example.com'),
('Neha Verma', 'neha@example.com'),
('Rahul Singh', 'rahul@example.com');

INSERT INTO tickets (user_id, title, status, description) VALUES
(1, 'Laptop issue', 'open', 'Laptop is not booting properly'),
(2, 'VPN access', 'in_progress', 'Need VPN access for remote work'),
(3, 'Email setup', 'closed', 'Configured mail client successfully');

```

#Step 4: Ran SQL files in MySQL
```
sudo mysql
```
#inside sql
```
SOURCE /home/webadmin/project/sql/schema.sql;
SOURCE /home/webadmin/project/sql/seed.sql;
```
#Step 5: Verified data
```
sql
USE trainingdb;
SELECT * FROM users;
SELECT * FROM tickets;
SHOW GRANTS FOR 'trainingapp'@'localhost';
```

#Step 6: Created PHP config file

```
sudo nano /var/www/website/day3/config.php

<?php
$host = 'localhost';
$db   = 'trainingdb';
$user = 'trainingapp';
$pass = 'StrongPassword123!';
$charset = 'utf8mb4';

$dsn = "mysql:host=$host;dbname=$db;charset=$charset";

$options = [
    PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
    PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
];

try {
    $pdo = new PDO($dsn, $user, $pass, $options);
} catch (PDOException $e) {
    exit('Database connection failed.');
}
?>

```
#Step 7: Created PHP CRUD app
```
sudo nano /var/www/website/day3/index.php

<?php
require_once 'config.php';

$errors = [];
$success = '';
$editTicket = null;

function clean($value) {
    return htmlspecialchars((string)$value, ENT_QUOTES, 'UTF-8');
}

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $action = $_POST['action'] ?? '';

    if ($action === 'create' || $action === 'update') {
        $ticket_id = trim($_POST['ticket_id'] ?? '');
        $user_id = trim($_POST['user_id'] ?? '');
        $title = trim($_POST['title'] ?? '');
        $status = trim($_POST['status'] ?? '');
        $description = trim($_POST['description'] ?? '');

        if ($user_id === '' || !ctype_digit($user_id)) {
            $errors[] = 'Valid user is required.';
        }

        if ($title === '') {
            $errors[] = 'Title is required.';
        }

        if (!in_array($status, ['open', 'in_progress', 'closed'], true)) {
            $errors[] = 'Valid status is required.';
        }

        if ($description === '') {
            $errors[] = 'Description is required.';
        }

        if (!$errors) {
            if ($action === 'create') {
                $stmt = $pdo->prepare("INSERT INTO tickets (user_id, title, status, description) VALUES (?, ?, ?, ?)");
                $stmt->execute([$user_id, $title, $status, $description]);
                $success = 'Ticket added successfully.';
            } else {
                if ($ticket_id === '' || !ctype_digit($ticket_id)) {
                    $errors[] = 'Valid ticket ID is required for update.';
                } else {
                    $stmt = $pdo->prepare("UPDATE tickets SET user_id = ?, title = ?, status = ?, description = ? WHERE id = ?");
                    $stmt->execute([$user_id, $title, $status, $description, $ticket_id]);
                    $success = 'Ticket updated successfully.';
                }
            }
        }
    }

    if ($action === 'delete') {
        $ticket_id = trim($_POST['ticket_id'] ?? '');

        if ($ticket_id === '' || !ctype_digit($ticket_id)) {
            $errors[] = 'Valid ticket ID is required for delete.';
        } else {
            $stmt = $pdo->prepare("DELETE FROM tickets WHERE id = ?");
            $stmt->execute([$ticket_id]);
            $success = 'Ticket deleted successfully.';
        }
    }
}

if (isset($_GET['edit']) && ctype_digit($_GET['edit'])) {
    $stmt = $pdo->prepare("SELECT * FROM tickets WHERE id = ?");
    $stmt->execute([$_GET['edit']]);
    $editTicket = $stmt->fetch();
}

$users = $pdo->query("SELECT id, name FROM users ORDER BY name")->fetchAll();

$sql = "SELECT tickets.id, tickets.user_id, tickets.title, tickets.status, tickets.description, tickets.created_at,
               users.name AS user_name, users.email
        FROM tickets
        JOIN users ON tickets.user_id = users.id
        ORDER BY tickets.id DESC";
$tickets = $pdo->query($sql)->fetchAll();
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Training DB CRUD</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 30px; background: #f7f7f7; }
        .container { max-width: 1100px; margin: auto; background: #fff; padding: 24px; border-radius: 10px; box-shadow: 0 0 10px rgba(0,0,0,0.08); }
        h1, h2 { margin-top: 0; }
        table { border-collapse: collapse; width: 100%; margin-top: 20px; }
        table, th, td { border: 1px solid #ccc; }
        th, td { padding: 10px; text-align: left; vertical-align: top; }
        .error { color: #b30000; margin-bottom: 15px; }
        .success { color: #006400; margin-bottom: 15px; }
        form { margin-bottom: 30px; }
        input, select, textarea { width: 100%; padding: 8px; margin: 6px 0 12px; box-sizing: border-box; }
        button { padding: 10px 16px; cursor: pointer; }
        .inline-form { display: inline; }
        .actions a, .actions button { margin-right: 8px; }
        .small-btn { padding: 6px 10px; }
    </style>
</head>
<body>
<div class="container">
    <h1>Training DB - PHP CRUD</h1>

    <?php if ($errors): ?>
        <div class="error">
            <?php foreach ($errors as $error): ?>
                <div><?= clean($error) ?></div>
            <?php endforeach; ?>
        </div>
    <?php endif; ?>

    <?php if ($success): ?>
        <div class="success"><?= clean($success) ?></div>
    <?php endif; ?>

    <h2><?= $editTicket ? 'Edit Ticket' : 'Add Ticket' ?></h2>
    <form method="post">
        <input type="hidden" name="action" value="<?= $editTicket ? 'update' : 'create' ?>">
        <?php if ($editTicket): ?>
            <input type="hidden" name="ticket_id" value="<?= clean($editTicket['id']) ?>">
        <?php endif; ?>

        <label>User</label>
        <select name="user_id" required>
            <option value="">Select user</option>
            <?php foreach ($users as $userRow): ?>
                <option value="<?= clean($userRow['id']) ?>"
                    <?= $editTicket && (int)$editTicket['user_id'] === (int)$userRow['id'] ? 'selected' : '' ?>>
                    <?= clean($userRow['name']) ?>
                </option>
            <?php endforeach; ?>
        </select>

        <label>Title</label>
        <input type="text" name="title" required value="<?= $editTicket ? clean($editTicket['title']) : '' ?>">

        <label>Status</label>
        <select name="status" required>
            <?php
            $statuses = ['open', 'in_progress', 'closed'];
            $selectedStatus = $editTicket['status'] ?? 'open';
            foreach ($statuses as $statusOption):
            ?>
                <option value="<?= clean($statusOption) ?>" <?= $selectedStatus === $statusOption ? 'selected' : '' ?>>
                    <?= clean($statusOption) ?>
                </option>
            <?php endforeach; ?>
        </select>

        <label>Description</label>
        <textarea name="description" required><?= $editTicket ? clean($editTicket['description']) : '' ?></textarea>

        <button type="submit"><?= $editTicket ? 'Update Ticket' : 'Add Ticket' ?></button>
        <?php if ($editTicket): ?>
            <a href="index.php">Cancel Edit</a>
        <?php endif; ?>
    </form>

    <h2>Tickets</h2>
    <table>
        <tr>
            <th>ID</th>
            <th>User</th>
            <th>Email</th>
            <th>Title</th>
            <th>Status</th>
            <th>Description</th>
            <th>Created At</th>
            <th>Actions</th>
        </tr>
        <?php foreach ($tickets as $ticket): ?>
            <tr>
                <td><?= clean($ticket['id']) ?></td>
                <td><?= clean($ticket['user_name']) ?></td>
                <td><?= clean($ticket['email']) ?></td>
                <td><?= clean($ticket['title']) ?></td>
                <td><?= clean($ticket['status']) ?></td>
                <td><?= clean($ticket['description']) ?></td>
                <td><?= clean($ticket['created_at']) ?></td>
                <td class="actions">
                    <a href="index.php?edit=<?= clean($ticket['id']) ?>">Edit</a>
                    <form method="post" class="inline-form" onsubmit="return confirm('Delete this ticket?');">
                        <input type="hidden" name="action" value="delete">
                        <input type="hidden" name="ticket_id" value="<?= clean($ticket['id']) ?>">
                        <button type="submit" class="small-btn">Delete</button>
                    </form>
                </td>
            </tr>
        <?php endforeach; ?>
    </table>
</div>
</body>
</html>

```
##Testing Performed
#Browser test
#Opened the app in browser:

```
http://localhost/day3/
```
