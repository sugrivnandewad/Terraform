#!/bin/bash
yum update -y
yum install -y httpd
systemctl start httpd
systemctl enable httpd

cat <<EOT > /var/www/html/index.html
<!DOCTYPE html>
<html>
<head>
  <title>Welcome to the Dev Private Instance</title>
  <style>
    body { background: #f0f4f8; font-family: Arial, sans-serif; color: #222; }
    .container { margin: 100px auto; width: 60%; background: #fff; border-radius: 10px; box-shadow: 0 0 20px #ccc; padding: 40px; text-align: center; }
    h1 { color: #0078d7; font-size: 2.5em; }
    p { font-size: 1.2em; margin-top: 20px; }
    .footer { margin-top: 40px; color: #888; font-size: 0.9em; }
  </style>
</head>
<body>
  <div class="container">
    <h1>🚀 Welcome to the Dev Private Instance!</h1>
    <p>This web server was provisioned using <strong>Terraform</strong> and <strong>Amazon EC2</strong>.</p>
    <div class="footer">Environment: <b>Development</b> &mdash; Project: <b>TerraformDemo</b></div>
  </div>
</body>
</html>
EOT
