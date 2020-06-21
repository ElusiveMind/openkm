## OpenKM with KEA
Last Updated: June 21, 2019

This is an unofficial container that provides the OpenKM application with persistent data. It also provides Tesseract OCR support and the KEA and test environments.

To quickly pull and run the application, exectute the following:

`docker run -p 8080:8080 mbagnall/openkm`

To add document and account persistency, use the following. Note that you will need to use this command in order for the installation not to re-initializa on every container rebuild or update.

`docker run -p 8080:8080 -v./openkm-data:/opt/tomcat-8.5.34/repository mbagnall/openkm`

---

The default configuration above uses the default `h2` data storage method. OpenKM has the ability to additionally integrate with:
- MySQL
- MariaDB
- Oracle
- MSSQL
- PostgreSQL

As of this README, `h2` abd `mysql` are supported.

---

### Setting Up With MySQL
There is a sample repository with information regarding setting up your install with MySQL. You can view it [here](https://github.com/ElusiveMind/openkm_demo). It can be configured with Rancher or any other orchestration system you like. The example below comes from the demo and uses Docker Composer

```yml
version: '2'
services:

  # Our base OpenKM service is at the localhost. If hosting these on a domain,
  # change the "localhost:8080" to your domain and optionally change the ports.
  # if you are using ingress as a proxy, then you can make the exposed port anything
  # but it must map to 8080 on the container.
  openkm:
    image: mbagnall/openkm:mysql
    container_name: openkm
    environment:
      OPEN_KM_URL: http://localhost:8080/OpenKM
      OPEN_KM_BASE_URL: http://localhost:8080
    ports:
      - 8080:8080
    volumes:
      - ./data:/opt/tomcat-8.5.34/repository
    depends_on:
      - db
    restart: unless-stopped
  
  # We need to start our MySQL service without grant tables and with an init
  # file to create the user. This allows the magic process of "start service,
  # start using". If you need a more MySQL environment, be sure to check out
  # the information in the readme about a more secure mysql.
  db:
    image: mysql:5.7
    container_name: openkm-datastore
    command: --skip-grant-tables --init-file=/opt/init-file/init-file.sql
    environment:
      MYSQL_ROOT_PASSWORD: OpenKM77
      MYSQL_ALLOW_EMPTY_PASSWORD: 0
    expose:
      - 3306
    volumes:
      - ./openkm-datastore:/var/lib/mysql
      - ./openkm-init-file:/opt/init-file
    restart: unless-stopped
```

The init-file.sql looks like

```sql
CREATE DATABASE okmdb DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_bin;
CREATE USER 'openkm'@'%' IDENTIFIED BY 'OpenKM77';
```

---
### A More Secure MySQL

If you would like to lock down your MySQL you can remove the `command:` line from the MySQL service and re-add the environment variables to create the default user. **At this time it is not supported to connect this OpenKM docker-based service to an existing/shared MySQL server.** If you need support for this, please contact me [here](mailto:mbagnall@flyingflip.com).

Below is an example of the changes required. Note that the passwords must stay the same:

```yaml
  db:
    image: mysql:5.7
    container_name: openkm-datastore
    environment:
      MYSQL_DATABASE: okmdb
      MYSQL_USER: openkm
      MYSQL_PASSWORD: OpenKM77
      MYSQL_ROOT_PASSWORD: OpenKM77
      MYSQL_ALLOW_EMPTY_PASSWORD: 0
    expose:
      - 3306
    volumes:
      - ./openkm-datastore:/var/lib/mysql
    restart: unless-stopped
```

Once you have started the containers, **you must alter the grants on the mysql server manually. This must be done BEFORE going to OpenKM for the first time or your install will be broken.** To alter the grants, log into your mysql contaner as root:

`docker exec -ti openkm-datastore bash`

Then login to your MySQL server as root:

`mysql -uroot -pOpenKM77`

Finally, change the grants:

`GRANT ALL ON okmdb.* TO 'openkm'@'%' WITH GRANT OPTION;`

After these steps are completed, go to the URL of your OpenKM server and everything should work. The default administrative user and password is as follows:

**Username:** okmAdmin  
**Password:** admin

