#!/bin/bash

OE_USER="eagle1829"
OE_HOME="/$OE_USER"
OE_HOME_EXT="/$OE_USER/${OE_USER}-server"
OE_PORT="8029"
OE_VERSION="18.0"
IS_ENTERPRISE="False"
INSTALL_POSTGRESQL_FOURTEEN="False"
OE_SUPERADMIN="admin"
GENERATE_RANDOM_PASSWORD="False"
OE_CONFIG="${OE_USER}-server"
LONGPOLLING_PORT="8072"
ENABLE_SSL="False"
ADMIN_EMAIL="rapidgrps@gmail.com"
VENV_DIR="$OE_HOME/venv"

echo -e "\n---- Update Server ----"
sudo apt-get update
sudo apt-get upgrade -y

# Install necessary dependencies
echo -e "\n---- Installing required packages ----"
sudo apt-get install -y python3.10 python3.10-venv python3.10-dev python3-pip \
                        git libpq-dev build-essential wget libxslt-dev \
                        libzip-dev libldap2-dev libsasl2-dev nodejs npm \
                        libpng-dev libjpeg-dev gdebi

# Set Python 3.10 as the default
sudo update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.10 1
sudo update-alternatives --set python3 /usr/bin/python3.10

# PostgreSQL installation
echo -e "\n---- Install PostgreSQL Server ----"
if [ "$INSTALL_POSTGRESQL_FOURTEEN" = "True" ]; then
    echo -e "\n---- Installing PostgreSQL 14 ----"
    sudo curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/postgresql.gpg
    sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
    sudo apt-get update
    sudo apt-get install -y postgresql-14
else
    echo -e "\n---- Installing default PostgreSQL version ----"
    sudo apt-get install -y postgresql postgresql-server-dev-all
fi

echo -e "\n---- Creating PostgreSQL User ----"
sudo su - postgres -c "createuser -s $OE_USER" 2> /dev/null || true

# Create Odoo user and directories
echo -e "\n---- Creating Odoo system user and directories ----"
sudo adduser --system --quiet --shell=/bin/bash --home=$OE_HOME --gecos 'Odoo' --group $OE_USER
sudo mkdir -p /var/log/$OE_USER
sudo chown $OE_USER:$OE_USER /var/log/$OE_USER
sudo mkdir -p $OE_HOME/custom/addons

# Clone Odoo source code
echo -e "\n---- Cloning Odoo 18.0 ----"
sudo git clone --depth 1 --branch $OE_VERSION https://github.com/odoo/odoo $OE_HOME_EXT

# Set up virtual environment
echo -e "\n---- Creating Python Virtual Environment ----"
sudo -u $OE_USER python3 -m venv $VENV_DIR
source $VENV_DIR/bin/activate
pip install --upgrade pip

# Install Odoo dependencies
echo -e "\n---- Installing Odoo dependencies ----"
pip install -r $OE_HOME_EXT/requirements.txt

# Enterprise edition (if applicable)
if [ "$IS_ENTERPRISE" = "True" ]; then
    echo -e "\n---- Installing Enterprise dependencies ----"
    pip install psycopg2-binary pdfminer.six num2words ofxparse dbfread ebaysdk firebase_admin pyOpenSSL
    sudo npm install -g less less-plugin-clean-css rtlcss
fi

echo -e "\n---- Setting permissions ----"
sudo chown -R $OE_USER:$OE_USER $OE_HOME/*

# Create Odoo configuration file
echo -e "\n---- Creating Odoo configuration file ----"
sudo tee /etc/${OE_CONFIG}.conf > /dev/null <<EOF
[options]
admin_passwd = ${OE_SUPERADMIN}
db_host = False
db_port = False
db_user = $OE_USER
db_password = False
xmlrpc_port = $OE_PORT
longpolling_port = $LONGPOLLING_PORT
logfile = /var/log/$OE_USER/${OE_CONFIG}.log
addons_path = $OE_HOME_EXT/addons,$OE_HOME/custom/addons
EOF

sudo chown $OE_USER:$OE_USER /etc/${OE_CONFIG}.conf
sudo chmod 640 /etc/${OE_CONFIG}.conf

# Create systemd service file
echo -e "\n---- Creating systemd service file ----"
sudo tee /etc/systemd/system/odoo-${OE_USER}.service > /dev/null <<EOF
[Unit]
Description=Odoo ${OE_USER} Service
Documentation=http://www.odoo.com
After=network.target postgresql.service

[Service]
User=$OE_USER
Group=$OE_USER
WorkingDirectory=$OE_HOME_EXT

ExecStart=/bin/bash -c 'source $VENV_DIR/bin/activate && exec $OE_HOME_EXT/odoo-bin -c /etc/${OE_CONFIG}.conf'

Restart=always
TimeoutStartSec=20

[Install]
WantedBy=multi-user.target
EOF

sudo chmod 644 /etc/systemd/system/odoo-${OE_USER}.service
sudo systemctl daemon-reload
sudo systemctl enable odoo-${OE_USER}
sudo systemctl start odoo-${OE_USER}

echo -e "\n---- Odoo 18.0 Installation Complete! ----"
echo "-----------------------------------------------------------"
echo "Odoo Service: odoo-${OE_USER}"
echo "Port: $OE_PORT"
echo "User service: $OE_USER"
echo "Configuration file location: /etc/${OE_CONFIG}.conf"
echo "Logfile location: /var/log/$OE_USER"
echo "User PostgreSQL: $OE_USER"
echo "Code location: $OE_HOME_EXT"
echo "Virtual Environment: $VENV_DIR"
echo "Addons folder: $OE_HOME/custom/addons/"
echo "Database Superadmin Password: $OE_SUPERADMIN"
echo "Start Odoo: sudo systemctl start odoo-${OE_USER}"
echo "Stop Odoo: sudo systemctl stop odoo-${OE_USER}"
echo "Restart Odoo: sudo systemctl restart odoo-${OE_USER}"
echo "-----------------------------------------------------------"
