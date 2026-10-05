sudo wget https://raw.githubusercontent.com/ShaheenHossain/installScript_01/odoo_ent1967/eagle1967_install.sh
```

#### 3. Make the script executable
```
sudo chmod +x eagle1967_install.sh

sudo ./eagle1967_install.sh






sudo rm -R /eagle1967	
sudo rm -f /etc/eagle1967-server.conf
sudo rm -f /var/log/eagle1967-server.log
sudo rm -R /var/log/eagle1967
update-rc.d -f eagle1967-server remove
sudo rm -f /etc/init.d/eagle1967-server
