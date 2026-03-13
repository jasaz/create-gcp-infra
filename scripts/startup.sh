#!/bin/bash
set -e

# Install MongoDB 6.0
apt-get update
apt-get install -y gnupg curl
curl -fsSL https://www.mongodb.org/static/pgp/server-6.0.asc | gpg --dearmor -o /usr/share/keyrings/mongodb-server-6.0.gpg
echo "deb [ signed-by=/usr/share/keyrings/mongodb-server-6.0.gpg ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/6.0 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-6.0.list
apt-get update
apt-get install -y mongodb-org

# Configure MongoDB to listen on all interfaces (auth enabled later)
sed -i 's/bindIp: 127.0.0.1/bindIp: 0.0.0.0/' /etc/mongod.conf

systemctl enable mongod
systemctl start mongod

# Wait for MongoDB to be ready
for i in $(seq 1 30); do
  if mongosh --eval "db.runCommand({ ping: 1 })" &>/dev/null; then
    break
  fi
  sleep 2
done

# Create admin user
mongosh admin --eval '
  db.createUser({
    user: "admin",
    pwd: "${mongo_admin_pass}",
    roles: [{ role: "userAdminAnyDatabase", db: "admin" }]
  })
'

# Create application user for flaskdb
mongosh flaskdb --eval '
  db.createUser({
    user: "flaskapp",
    pwd: "${mongo_app_pass}",
    roles: [{ role: "readWrite", db: "flaskdb" }]
  })
'

# Enable authentication
cat >> /etc/mongod.conf <<EOF

security:
  authorization: enabled
EOF

systemctl restart mongod

# Install gsutil for backups
apt-get install -y google-cloud-sdk

# Create backup script with bucket name baked in by Terraform
cat > /usr/local/bin/mongodb-backup.sh << 'SCRIPT'
#!/bin/bash
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/tmp/mongodb-backup-$TIMESTAMP"
BUCKET="${backup_bucket}"

mongodump --username admin --password "${mongo_admin_pass}" --authenticationDatabase admin --out "$BACKUP_DIR"
tar -czf "$BACKUP_DIR.tar.gz" -C /tmp "mongodb-backup-$TIMESTAMP"
gsutil cp "$BACKUP_DIR.tar.gz" "gs://$BUCKET/backups/mongodb-backup-$TIMESTAMP.tar.gz"

rm -rf "$BACKUP_DIR" "$BACKUP_DIR.tar.gz"
SCRIPT

chmod +x /usr/local/bin/mongodb-backup.sh

# Schedule daily backup at 2 AM
echo "0 2 * * * root /usr/local/bin/mongodb-backup.sh" > /etc/cron.d/mongodb-backup
chmod 644 /etc/cron.d/mongodb-backup

# Ensure cron daemon is running
systemctl enable cron
systemctl start cron
