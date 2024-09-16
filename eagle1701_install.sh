
#!/bin/bash

# Odoo 17 installation script with Python 3.10 in a virtual environment

OE_USER="odoo1701"
OE_HOME="/$OE_USER"
OE_HOME_EXT="$OE_HOME/${OE_USER}-server"
OE_VERSION="17.0"
OE_PORT="8001"
IS_ENTERPRISE="False"
OE_SUPERADMIN="admin"
OE_CONFIG="${OE_USER}-server"
VENV_PATH="$OE_HOME/venv"

# Update Server
echo -e "\n---- Update Server ----"
sudo apt-get update
sudo apt-get upgrade -y

# Install PostgreSQL 14
# echo -e "\n---- Install PostgreSQL Server ----"
# sudo apt-get install postgresql-14 -y

echo -e "\n---- Creating PostgreSQL User ----"
sudo su - postgres -c "createuser -s $OE_USER" 2> /dev/null || true

# Install Python 3.10 and required dependencies
echo -e "\n---- Install Python 3.10 and dependencies ----"
sudo apt-get install python3.10 python3.10-venv python3.10-dev -y

# Install other dependencies
echo -e "\n---- Install other required packages ----"
sudo apt-get install git build-essential wget libxslt-dev libzip-dev libldap2-dev libsasl2-dev nodejs npm libpq-dev -y

# Create Odoo system user
echo -e "\n---- Create Odoo system user ----"
sudo adduser --system --home=$OE_HOME --group $OE_USER

# Create Log directory
echo -e "\n---- Create Log directory ----"
sudo mkdir /var/log/$OE_USER
sudo chown $OE_USER:$OE_USER /var/log/$OE_USER

# Download Odoo 17 source
echo -e "\n---- Download Odoo 17 source ----"
sudo git clone --depth 1 --branch $OE_VERSION https://github.com/ShaheenHossain/odoo17ent_6kyr_010724_01 $OE_HOME_EXT/

# Create a virtual environment for Odoo 17 using Python 3.10
echo -e "\n---- Creating Python virtual environment with Python 3.10 ----"
python3.10 -m venv $VENV_PATH

# Activate virtual environment and install Python dependencies
echo -e "\n---- Activating virtual environment and installing Python dependencies ----"
source $VENV_PATH/bin/activate
pip install wheel
pip install -r $OE_HOME_EXT/requirements.txt
deactivate

# Install Node.js and rtlcss for RTL support
#echo -e "\n---- Install Node.js and rtlcss ----"
#sudo npm install -g rtlcss

# Create custom addons directory
echo -e "\n---- Create custom module directory ----"
sudo su $OE_USER -c "mkdir $OE_HOME/custom"
sudo su $OE_USER -c "mkdir $OE_HOME/custom/addons"

# Set permissions on home folder
echo -e "\n---- Setting permissions on home folder ----"
sudo chown -R $OE_USER:$OE_USER $OE_HOME/*

# Create Odoo config file
echo -e "\n---- Create server config file ----"
sudo touch /etc/${OE_CONFIG}.conf
sudo su root -c "printf '[options] \n' > /etc/${OE_CONFIG}.conf"
sudo su root -c "printf 'admin_passwd = ${OE_SUPERADMIN}\n' >> /etc/${OE_CONFIG}.conf"
sudo su root -c "printf 'http_port = ${OE_PORT}\n' >> /etc/${OE_CONFIG}.conf"
sudo su root -c "printf 'logfile = /var/log/${OE_USER}/${OE_CONFIG}.log\n' >> /etc/${OE_CONFIG}.conf"
sudo su root -c "printf 'addons_path=${OE_HOME_EXT}/addons,${OE_HOME}/custom/addons\n' >> /etc/${OE_CONFIG}.conf"
sudo chown $OE_USER:$OE_USER /etc/${OE_CONFIG}.conf
sudo chmod 640 /etc/${OE_CONFIG}.conf

# Create systemd service file for Odoo 17
echo -e "\n---- Create systemd service file for Odoo 17 ----"
cat <<EOF > /etc/systemd/system/$OE_CONFIG.service
[Unit]
Description=Odoo 17
Documentation=http://www.odoo.com

[Service]
# Ubuntu/Debian convention:
Type=simple
User=$OE_USER
ExecStart=$VENV_PATH/bin/python3 $OE_HOME_EXT/odoo-bin -c /etc/$OE_CONFIG.conf
WorkingDirectory=$OE_HOME_EXT
StandardOutput=journal+console

[Install]
WantedBy=multi-user.target
EOF

# Enable and start Odoo service
echo -e "\n---- Starting Odoo Service ----"
sudo systemctl enable $OE_CONFIG
sudo systemctl start $OE_CONFIG

echo "-----------------------------------------------------------"
echo "Done! Odoo 17 is up and running with Python 3.10."
echo "Service: $OE_CONFIG"
echo "Port: $OE_PORT"
echo "User PostgreSQL: $OE_USER"
echo "Password superadmin: $OE_SUPERADMIN"
echo "Start Odoo service: sudo systemctl start $OE_CONFIG"
echo "Stop Odoo service: sudo systemctl stop $OE_CONFIG"
echo "Restart Odoo service: sudo systemctl restart $OE_CONFIG"
echo "-----------------------------------------------------------"
