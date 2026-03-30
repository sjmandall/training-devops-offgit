<?php
require_once 'config.php';

$errors = [];
$success = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
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
        $stmt = $pdo->prepare("INSERT INTO tickets (user_id, title, status, description) VALUES (?, ?, ?, ?)");
        $stmt->execute([$user_id, $title, $status, $description]);
        $success = 'Ticket added successfully.';
    }
}

$users = $pdo->query("SELECT id, name FROM users ORDER BY name")->fetchAll();

$sql = "SELECT tickets.id, tickets.title, tickets.status, tickets.description, tickets.created_at,
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
        body { font-family: Arial, sans-serif; margin: 30px; }
        table { border-collapse: collapse; width: 100%; margin-top: 20px; }
        table, th, td { border: 1px solid #ccc; }
        th, td { padding: 10px; text-align: left; }
        .error { color: red; }
        .success { color: green; }
        form { margin-bottom: 30px; }
        input, select, textarea { width: 100%; padding: 8px; margin: 6px 0 12px; }
        button { padding: 10px 16px; }
    </style>
</head>
<body>
    <h1>Training DB - Tickets CRUD</h1>

    <?php if ($errors): ?>
        <div class="error">
            <?php foreach ($errors as $error): ?>
                <p><?= htmlspecialchars($error) ?></p>
            <?php endforeach; ?>
        </div>
    <?php endif; ?>

    <?php if ($success): ?>
        <p class="success"><?= htmlspecialchars($success) ?></p>
    <?php endif; ?>

    <h2>Add Ticket</h2>
    <form method="post">
        <label>User</label>
        <select name="user_id" required>
            <option value="">Select user</option>
            <?php foreach ($users as $user): ?>
                <option value="<?= $user['id'] ?>">
                    <?= htmlspecialchars($user['name']) ?>
                </option>
            <?php endforeach; ?>
        </select>

        <label>Title</label>
        <input type="text" name="title" required>

        <label>Status</label>
        <select name="status" required>
            <option value="open">open</option>
            <option value="in_progress">in_progress</option>
            <option value="closed">closed</option>
        </select>

        <label>Description</label>
        <textarea name="description" required></textarea>

        <button type="submit">Add Ticket</button>
    </form>

    <h2>Seeded Tickets</h2>
    <table>
        <tr>
            <th>ID</th>
            <th>User</th>
            <th>Email</th>
            <th>Title</th>
            <th>Status</th>
            <th>Description</th>
            <th>Created At</th>
        </tr>
        <?php foreach ($tickets as $ticket): ?>
            <tr>
                <td><?= htmlspecialchars($ticket['id']) ?></td>
                <td><?= htmlspecialchars($ticket['user_name']) ?></td>
                <td><?= htmlspecialchars($ticket['email']) ?></td>
                <td><?= htmlspecialchars($ticket['title']) ?></td>
                <td><?= htmlspecialchars($ticket['status']) ?></td>
                <td><?= htmlspecialchars($ticket['description']) ?></td>
                <td><?= htmlspecialchars($ticket['created_at']) ?></td>
            </tr>
        <?php endforeach; ?>
    </table>
</body>
</html>
