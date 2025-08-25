<?php
// Hugo Contact Form Server-Side Status Page
// This runs on the server and can check localhost:8080 internally

header('Content-Type: text/html; charset=UTF-8');

function checkEndpoint($url) {
    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL, $url);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_TIMEOUT, 5);
    curl_setopt($ch, CURLOPT_CONNECTTIMEOUT, 3);
    curl_setopt($ch, CURLOPT_FOLLOWLOCATION, false);
    
    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    $error = curl_error($ch);
    curl_close($ch);
    
    return [
        'success' => $response !== false && $httpCode == 200,
        'http_code' => $httpCode,
        'response' => $response,
        'error' => $error
    ];
}

// Check health endpoint
$healthCheck = checkEndpoint('http://localhost:8080/health');
$tokenCheck = checkEndpoint('http://localhost:8080/form-token.js');

// Check CORS
$ch = curl_init();
curl_setopt($ch, CURLOPT_URL, 'http://localhost:8080/f/contact');
curl_setopt($ch, CURLOPT_CUSTOMREQUEST, 'OPTIONS');
curl_setopt($ch, CURLOPT_HTTPHEADER, ['Origin: https://connexxo.com']);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_TIMEOUT, 5);
$corsResponse = curl_exec($ch);
$corsCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
curl_close($ch);

$corsCheck = [
    'success' => $corsCode == 204 || $corsCode == 200,
    'http_code' => $corsCode
];
?>

<!DOCTYPE html>
<html>
<head>
    <title>Contact Form Status</title>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <style>
        body {
            font-family: system-ui, -apple-system, sans-serif;
            max-width: 600px;
            margin: 50px auto;
            padding: 20px;
            background: #f5f5f5;
        }
        .status-card {
            background: white;
            padding: 30px;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        h1 {
            color: #333;
            margin-bottom: 30px;
        }
        .status-item {
            margin: 20px 0;
            padding: 15px;
            border-radius: 5px;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        .status-healthy {
            background: #d4edda;
            color: #155724;
        }
        .status-error {
            background: #f8d7da;
            color: #721c24;
        }
        .timestamp {
            font-size: 0.9em;
            color: #666;
            margin-top: 20px;
        }
        button {
            background: #007bff;
            color: white;
            border: none;
            padding: 10px 20px;
            border-radius: 5px;
            cursor: pointer;
            font-size: 16px;
        }
        button:hover {
            background: #0056b3;
        }
        .details {
            margin-top: 20px;
            padding: 15px;
            background: #f8f9fa;
            border-radius: 5px;
            font-size: 0.9em;
        }
    </style>
</head>
<body>
    <div class="status-card">
        <h1>🔍 Contact Form Status</h1>
        
        <div class="status-item <?php echo $healthCheck['success'] ? 'status-healthy' : 'status-error'; ?>">
            <span>Health Check</span>
            <span><?php echo $healthCheck['success'] ? '✅ Healthy' : '❌ Error: ' . $healthCheck['http_code']; ?></span>
        </div>
        
        <div class="status-item <?php echo $tokenCheck['success'] ? 'status-healthy' : 'status-error'; ?>">
            <span>Token Endpoint</span>
            <span><?php echo $tokenCheck['success'] ? '✅ Working' : '❌ Error: ' . $tokenCheck['http_code']; ?></span>
        </div>
        
        <div class="status-item <?php echo $corsCheck['success'] ? 'status-healthy' : 'status-error'; ?>">
            <span>CORS Configuration</span>
            <span><?php echo $corsCheck['success'] ? '✅ Configured' : '❌ Error: ' . $corsCheck['http_code']; ?></span>
        </div>
        
        <div class="timestamp">
            Last checked: <?php echo date('Y-m-d H:i:s T'); ?>
        </div>
        
        <button onclick="location.reload()">Refresh Status</button>
        
        <div class="details">
            <strong>Service Details:</strong><br>
            <?php if ($healthCheck['success']): ?>
                Health Response: <code><?php echo htmlspecialchars($healthCheck['response']); ?></code><br>
            <?php endif; ?>
            
            <strong>Service URLs:</strong><br>
            <code>http://contact.connexxo.com:8080/health</code><br>
            <code>http://contact.connexxo.com:8080/form-token.js</code><br>
            <code>http://contact.connexxo.com:8080/f/contact</code>
        </div>
    </div>
</body>
</html>