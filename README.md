
CREATE USER odoo_user WITH PASSWORD 'xxx';
CREATE DATABASE odoo_db OWNER odoo_user;
GRANT ALL PRIVILEGES ON DATABASE odoo_db TO odoo_user;


install libpq-dev before psycopq2


sudo vim /etc/postgresql/[version]/main/pg_hba.conf
local   all             odoo_user                               md5
sudo service postgresql restart


python3 odoo-bin -d odoo_db --db_user=odoo_user --db_password="xxx"

https://www.odoo.com/documentation/17.0/developer/reference/cli.html
https://www.odoo.com/documentation/17.0/administration/on_premise/source.html
