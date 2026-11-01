<?php
header('Content-Type: application/json');

// Shared secret key matched identically with Flutter App (CPanelStorageClient) and Firebase Cloud Functions
$SECRET_KEY = getenv('CPANEL_HMAC_SECRET') ?: 'RENTALHUB_HMAC_SECURE_STORAGE_SECRET_2026';

// 1. Authorization Header Validation
$authHeader = $_SERVER['HTTP_AUTHORIZATION'] ?? '';
if (!preg_match('/^Bearer\s+(.+)$/i', $authHeader, $matches)) {
    http_response_code(401);
    echo json_encode(['error' => 'Missing or malformed Authorization header']);
    exit;
}

$token = $matches[1];
$tokenParts = explode(':', base64_decode($token));
if (count($tokenParts) !== 2) {
    http_response_code(401);
    echo json_encode(['error' => 'Invalid token structure']);
    exit;
}

list($timestamp, $receivedHash) = $tokenParts;

// 2. Replay Attack Window Check (300 seconds)
if (abs(time() - intval($timestamp)) > 300) {
    http_response_code(403);
    echo json_encode(['error' => 'Token expired']);
    exit;
}

// 3. HMAC-SHA256 Signature Verification
$expectedHash = hash_hmac('sha256', $timestamp, $SECRET_KEY);
if (!hash_equals($expectedHash, $receivedHash)) {
    http_response_code(403);
    echo json_encode(['error' => 'Invalid HMAC signature']);
    exit;
}

// 4. Validate Upload Category
$category = $_POST['category'] ?? 'kyc';
$allowedCategories = ['kyc', 'vehicles', 'payments', 'agreements'];
if (!in_array($category, $allowedCategories)) {
    http_response_code(400);
    echo json_encode(['error' => 'Invalid category specified. Allowed: ' . implode(', ', $allowedCategories)]);
    exit;
}

// 5. File Upload Verification
if (!isset($_FILES['file']) || $_FILES['file']['error'] !== UPLOAD_ERR_OK) {
    http_response_code(400);
    echo json_encode(['error' => 'File upload error or file missing']);
    exit;
}

$file = $_FILES['file'];

// Allowed MIME types
$allowedMimeTypes = ['image/jpeg', 'image/png', 'image/webp', 'application/pdf'];
$finfo = finfo_open(FILEINFO_MIME_TYPE);
$detectedMime = finfo_file($finfo, $file['tmp_name']);
finfo_close($finfo);

if (!in_array($detectedMime, $allowedMimeTypes)) {
    http_response_code(415);
    echo json_encode(['error' => 'Unsupported Media Type: ' . $detectedMime]);
    exit;
}

// 10MB Max File Size
if ($file['size'] > 10 * 1024 * 1024) {
    http_response_code(413);
    echo json_encode(['error' => 'Payload exceeds maximum allowed size (10MB)']);
    exit;
}

// 6. Cryptographically Secure File Name Generation
$extension = strtolower(pathinfo($file['name'], PATHINFO_EXTENSION));
if ($extension === 'jpeg') $extension = 'jpg';
$sanitizedName = bin2hex(random_bytes(16)) . '.' . $extension;
$targetDirectory = __DIR__ . '/' . $category . '/';
$targetPath = $targetDirectory . $sanitizedName;

if (!is_dir($targetDirectory)) {
    mkdir($targetDirectory, 0755, true);
}

if (move_uploaded_file($file['tmp_name'], $targetPath)) {
    $protocol = (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off') ? "https://" : "http://";
    $publicUrl = $protocol . $_SERVER['HTTP_HOST'] . '/storage/' . $category . '/' . $sanitizedName;
    http_response_code(200);
    echo json_encode([
        'success' => true,
        'url' => $publicUrl,
        'filename' => $sanitizedName,
        'category' => $category,
        'size' => $file['size']
    ]);
} else {
    http_response_code(500);
    echo json_encode(['error' => 'Failed to persist uploaded asset']);
}
