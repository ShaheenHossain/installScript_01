# [Odoo](https://www.odoo.com "Odoo's Homepage") Install Script

This script is based on the install script from André Schenkels (https://github.com/aschenkels-ictstudio/openerp-install-scripts)
but goes a bit further and has been improved. This script will also give you the ability to define an xmlrpc_port in the .conf file that is generated under /etc/
This script can be safely used in a multi-odoo code base server because the default Odoo port is changed BEFORE the Odoo is started.

## Installing Nginx
If you set the parameter ```INSTALL_NGINX``` to ```True``` you should also configure workers. Without workers you will probably get connection loss issues. Look at [the deployment guide from Odoo](https://www.odoo.com/documentation/16.0/administration/install/deploy.html) on how to configure workers.

## Installation procedure

##### 1. Download the script:

sudo wget https://raw.githubusercontent.com/ShaheenHossain/installScript_01/swisscrm1660/eagle1660_install.sh

sudo chmod +x eagle1660_install.sh

sudo ./eagle1660_install.sh
