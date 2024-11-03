!/bin/bash
# Install nginx on the bastion host
sudo apt update
sudo apt install -y nginx

# Configure nginx to proxy requests to the FastAPI app
sudo tee /etc/nginx/sites-available/default > /dev/null << 'EOL'
server {
    listen 80;
    server_name _; # Replace with your public IP or domain

    location / {
        proxy_pass http://10.0.0.2:8000;  # Replace with the private IP of the FastAPI instance
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOL

# Restart nginx to apply the changes
sudo systemctl restart nginx
