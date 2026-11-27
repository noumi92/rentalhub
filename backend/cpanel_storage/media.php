<?php
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Authorization, Content-Type, Origin, Accept');
header('X-Content-Type-Options: nosniff');

if (($_SERVER['REQUEST_METHOD'] ?? '') === 'OPTIONS') {
    http_response_code(204);
    exit;
}

$SECRET_KEY = getenv('CPANEL_HMAC_SECRET') ?: 'RENTALHUB_HMAC_SECURE_STORAGE_SECRET_2026';

// 1. Read HMAC token from ?auth= query param or Authorization: Bearer header
$token = $_GET['auth'] ?? '';
if ($token === '') {
    $authHeader = $_SERVER['HTTP_AUTHORIZATION']
        ?? $_SERVER['REDIRECT_HTTP_AUTHORIZATION']
        ?? '';
    if ($authHeader === '' && function_exists('apache_request_headers')) {
        $headers = apache_request_headers();
        $authHeader = $headers['Authorization'] ?? $headers['authorization'] ?? '';
    }
    if (preg_match('/^Bearer\s+(.+)$/i', $authHeader, $matches)) {
        $token = $matches[1];
    }
}

$decoded = base64_decode($token, true);
$tokenParts = $decoded !== false ? explode(':', $decoded) : [];
if (count($tokenParts) !== 2) {
    http_response_code(401);
    header('Content-Type: application/json');
    echo json_encode(['error' => 'Missing or invalid auth token']);
    exit;
}

list($timestamp, $receivedHash) = $tokenParts;
$expectedHash = hash_hmac('sha256', $timestamp, $SECRET_KEY);
if (!ctype_digit($timestamp) || !hash_equals($expectedHash, $receivedHash)) {
    http_response_code(403);
    header('Content-Type: application/json');
    echo json_encode(['error' => 'Invalid HMAC signature']);
    exit;
}

// 2. Validate key (<category>/<filename>) and prevent directory traversal
$key = trim($_GET['key'] ?? '');
$allowedCategories = [
    'kyc',
    'vehicles',
    'payments',
    'agreements',
    'handovers',
    'profile',
    'shops',
    'fleet',
];
if (!preg_match('/^([a-z]+)\/([a-zA-Z0-9._-]+)$/', $key, $keyMatches)) {
    http_response_code(400);
    header('Content-Type: application/json');
    echo json_encode(['error' => 'Invalid media key']);
    exit;
}

$category = $keyMatches[1];
$filename = $keyMatches[2];
if (!in_array($category, $allowedCategories, true) || str_contains($filename, '..')) {
    http_response_code(400);
    header('Content-Type: application/json');
    echo json_encode(['error' => 'Forbidden media path']);
    exit;
}

$baseDir = realpath(__DIR__ . '/' . $category);
$filePath = $baseDir !== false ? realpath($baseDir . '/' . $filename) : false;
if ($baseDir === false || $filePath === false || !str_starts_with($filePath, $baseDir . DIRECTORY_SEPARATOR) || !is_file($filePath)) {
    http_response_code(404);
    header('Content-Type: application/json');
    echo json_encode(['error' => 'Media file not found']);
    exit;
}

// 3. Stream file with verified Content-Type
$finfo = finfo_open(FILEINFO_MIME_TYPE);
$mime = finfo_file($finfo, $filePath) ?: 'application/octet-stream';
finfo_close($finfo);

header('Content-Type: ' . $mime);
header('Content-Length: ' . filesize($filePath));
header('Cache-Control: private, max-age=3600');
readfile($filePath);
exit;
