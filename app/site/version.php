<?php
header('Content-Type: application/json');

echo json_encode([
    'app'     => 'training-site',
    'version' => '2.0.0',
    'release' => 'v2',
    'date'    => date('Y-m-d'),
    'features' => [
        'users_created_at_column' => true,
        'email_index'             => true,
        'schema_version_tracking' => true,
    ]
]);
?>
