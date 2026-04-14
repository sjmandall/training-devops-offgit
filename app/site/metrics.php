<?php
header('Content-Type: text/plain');

echo "# HELP app_requests_total Total HTTP requests\n";
echo "# TYPE app_requests_total counter\n";
echo "app_requests_total 1\n";

echo "# HELP app_info Application info\n";
echo "# TYPE app_info gauge\n";
echo "app_info{version=\"1.0\",env=\"dev\"} 1\n";
?>
