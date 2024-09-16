

OE_USER="eagle1702"
OE_HOME="/$OE_USER"
OE_HOME_EXT="/$OE_USER/${OE_USER}-server"
OE_VERSION="master"
OE_PORT="8002"
OE_SUPERADMIN="admin"
OE_CONFIG="${OE_USER}-server"
VENV_PATH="$OE_HOME/venv"
LONGPOLLING_PORT="8072"
INSTALL_WKHTMLTOPDF="False"
ADMIN_EMAIL="rapidgrps@gmail.com"

# Update and install dependencies
echo -e "\n---- Update Server and Install Dependencies ----"
sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get install -y python3.10 python3.10-venv python3.10-dev build-essential libxml2-dev libxslt1-dev zlib1g-dev libldap2-dev libsasl2-dev libssl-dev nodejs npm

# Create PostgreSQL user
echo -e "\n---- Create PostgreSQL User ----"
sudo su - postgres -c "createuser --superuser $OE_USER"

# Create Odoo system user
echo -e "\n---- Create Eagle system user ----"
sudo adduser --system --quiet --shell=/bin/bash --home=$OE_HOME --gecos 'EAGLE1702' --group $OE_USER
#The user should also be added to the sudo'ers group.
sudo adduser $OE_USER sudo

# Create directories
echo -e "\n---- Create Directories ----"
sudo mkdir -p /var/log/$OE_USER
sudo chown $OE_USER:$OE_USER /var/log/$OE_USER

# Download and Install Odoo 17.0
echo -e "\n---- Download and Install Odoo 17.0 ----"
cd $OE_HOME
git clone --depth 1 --branch $OE_VERSION https://github.com/ShaheenHossain/odoo17ent_6kyr_010724_01 $OE_HOME_EXT

# Create Python virtual environment
echo -e "\n---- Create Python Virtual Environment ----"
python3.10 -m venv $VENV_PATH

# Activate virtual environment and install Python dependencies
echo -e "\n---- Install Python Dependencies ----"
source $VENV_PATH/bin/activate
pip install wheel
pip install -r $OE_HOME_EXT/requirements.txt
deactivate

# Create Odoo config file
echo -e "\n---- Create Odoo Config File ----"
sudo tee /etc/$OE_CONFIG.conf <<EOF
[options]
admin_passwd = $OE_SUPERADMIN
http_port = $OE_PORT
logfile = /var/log/$OE_USER/$OE_CONFIG.log
addons_path = $OE_HOME_EXT/addons,$OE_HOME/custom/addons
EOF
sudo chown $OE_USER:$OE_USER /etc/$OE_CONFIG.conf
sudo chmod 640 /etc/$OE_CONFIG.conf

# Create Odoo service file
echo -e "\n---- Create Odoo Service File ----"
sudo tee /etc/systemd/system/$OE_CONFIG.service <<EOF
[Unit]
Description=Odoo $OE_VERSION
Documentation=http://www.odoo.com

[Service]
Type=simple
User=$OE_USER
ExecStart=$VENV_PATH/bin/python3 $OE_HOME_EXT/odoo-bin -c /etc/$OE_CONFIG.conf
WorkingDirectory=$OE_HOME_EXT
StandardOutput=journal+console

[Install]
WantedBy=multi-user.target
EOF

# Enable and start Odoo service
echo -e "\n---- Enable and Start Odoo Service ----"
sudo systemctl enable $OE_CONFIG
sudo systemctl start $OE_CONFIG

echo "Odoo 17.0 setup complete. Service is running."
