# OpenKM with KEA

Last Updated: September 27, 2026

Unofficial Docker images of [OpenKM 6.3 Community Edition](https://www.openkm.com/), an open-source document management system, with persistent data, Tesseract OCR, LibreOffice document conversion and the KEA keyword extraction service. Every tag is a multi-architecture image, so it runs natively on Intel/AMD and ARM hosts, including Apple Silicon.

- Images: [hub.docker.com/r/mbagnall/openkm](https://hub.docker.com/r/mbagnall/openkm)
- Source: [github.com/ElusiveMind/openkm](https://github.com/ElusiveMind/openkm) (branch `6.x`)
- Project page: [flyingflip.com/projects/community-openkm](https://flyingflip.com/projects/community-openkm)

### Supported Tags

| Tag            | Database |
| -------------- | -------- |
| `6.3.13-mysql` | MySQL    |

Tags are named `<OpenKM version>-<database>`. The 6.3.13 images are built with the current OpenKM installer, which only offers database servers: MySQL, MariaDB, PostgreSQL, Oracle and SQL Server. Images for the other four can be built from this repository with the `DATABASE` build argument described below. As of this README, `6.3.13-mysql` is the tag covered in this document.

The older `mysql` and `h2` tags are the OpenKM 6.3.12 line, built with the previous installer. The embedded `h2` option is gone from the current installer, so there is no `h2` flavor of 6.3.13.

**Moving to OpenKM 7.0?** The 7.0.3 tags are documented on the `master` branch. OpenKM 7.0 cannot upgrade a 6.3 repository in place. Export from this instance with the Repository Export tool, then import into a fresh 7.0 instance, following the [OpenKM migration guide](https://docs.openkm.com/kcenter/view/okm-7.0/migrating-from-6313-to-70.html). Keep using the 6.3 tags until that is done.

---

### Running With MySQL

The quickest way to run OpenKM is Docker Compose, starting it together with MySQL. Save this as `docker-compose.yml` and run `docker compose up -d`. MySQL creates the `okmdb` database and the `openkm` user from its environment variables, with full rights on that database, so no manual grant step is needed.

```yml
services:
  # OPEN_KM_URL is used by KEA, inside the container, to call OpenKM's REST
  # API, so it always points at the container's own port 8080 and the
  # /OpenKM context path. Leave it out to let the image pick it.
  #
  # OPEN_KM_BASE_URL is the address browsers use to reach OpenKM; KEA allows
  # it as a CORS origin. When hosting on a domain or behind a proxy, change
  # this one to that domain. The published port can be anything, but it must
  # map to port 8080 in the container.
  openkm:
    image: mbagnall/openkm:6.3.13-mysql
    container_name: openkm
    environment:
      OPEN_KM_URL: http://localhost:8080/OpenKM
      OPEN_KM_BASE_URL: http://localhost:8080
    ports:
      - 8080:8080
    volumes:
      - ./data:/opt/tomcat/repository
    depends_on:
      - db
    restart: unless-stopped

  # The database name, user and password must match the DATABASE_* values
  # the image was built with (the defaults are shown here). OpenKM expects a
  # utf8 / utf8_bin database.
  db:
    image: mysql:8.0
    container_name: openkm-datastore
    command: --character-set-server=utf8mb3 --collation-server=utf8mb3_bin
    environment:
      MYSQL_DATABASE: okmdb
      MYSQL_USER: openkm
      MYSQL_PASSWORD: OpenKM77
      MYSQL_ROOT_PASSWORD: OpenKM77
    expose:
      - 3306
    volumes:
      - ./openkm-datastore:/var/lib/mysql
    restart: unless-stopped
```

Then go to:

`http://localhost:8080`

Tomcat redirects to `http://localhost:8080/OpenKM`, the context path OpenKM 6.3 installs under. The first start creates the database schema and takes a little while; `docker compose logs -f openkm` shows Tomcat's log, and OpenKM is ready once it prints "Server startup in". The default administrative user and password is as follows:

**Username:** okmAdmin  
**Password:** admin

Documents, the search index and caches live in `/opt/tomcat/repository` inside the container. The example mounts it at `./data`; keep that mount, or the installation re-initializes on every container rebuild or update. The MySQL data and the repository belong together: remove both or neither. On a start with an existing repository the image switches OpenKM's schema setting to `none`, which matters on 6.3 because its first-start setting drops and recreates every table.

A 6.3 repository and database cannot be shared with the 7.0 images. If a 7.0 instance has used the same `./data` and `./openkm-datastore` directories, point the 6.3 stack at fresh directories.

If you point the image at a database server you manage yourself, create the database and user like this before the first start:

```sql
CREATE DATABASE okmdb DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_bin;
CREATE USER 'openkm'@'%' IDENTIFIED BY 'OpenKM77';
GRANT ALL ON okmdb.* TO 'openkm'@'%' WITH GRANT OPTION;
```

### KEA

The KEA keyword extraction service is deployed next to OpenKM at `/keas`, so with the example above it answers at `http://localhost:8080/keas`. It logs in to OpenKM through the 6.x REST API at `OPEN_KM_URL` with the `okmAdmin` account, and browsers reach it through `OPEN_KM_BASE_URL`, which it allows as a CORS origin. A sample vocabulary ships with the image and is unpacked into `/opt/tomcat/kea` on every start.

KEA's copy of the administrator credentials lives in `/root/keas.properties` inside the image and is written to `/opt/tomcat/keas.properties` on every start. If you change the `okmAdmin` password in OpenKM, update that file as well or KEA can no longer log in.

---

### Building The Image

The image is built in a single step from the `image` folder. The OpenKM installer runs during the build (it downloads OpenKM 6.3.13 and Tomcat 8.5.100 from update.openkm.com and adds LibreOffice, ImageMagick and Xvfb with apt-get, so the build needs network access), and then the KEA service and the runtime entrypoint are layered on top. Tomcat lands in `/opt/tomcat-8.5.100` with `/opt/tomcat` linked to it, and OpenKM 6.3 runs on the Java 8 the image installs.

Select the database backend with the `DATABASE` build argument. It defaults to `mysql`:

```bash
cd image
docker build . -t mbagnall/openkm:6.3.13-mysql
docker build . --build-arg DATABASE=postgresql --build-arg DATABASE_HOST=postgres -t mbagnall/openkm:6.3.13-postgresql
```

`DATABASE` accepts `mysql`, `mariadb`, `oracle`, `sqlserver` or `postgresql`. The connection details are written into the image at build time and can be set with these build arguments:

| Build argument      | Default   | Purpose                                  |
| ------------------- | --------- | ---------------------------------------- |
| `DATABASE_HOST`     | `db`      | Host name of the database server         |
| `DATABASE_NAME`     | `okmdb`   | Database name (the SID for Oracle)       |
| `DATABASE_USER`     | `openkm`  | User to connect as                       |
| `DATABASE_PASSWORD` | `OpenKM77`| Password for that user                   |
| `OPENKM_VERSION`    | `6.3.13`  | OpenKM release the installer fetches     |

For MySQL the build also adds `allowPublicKeyRetrieval=true` to the datasource URL in Tomcat's `server.xml`. Without it MySQL 8's default authentication rejects every connection from the 6.3 driver settings with "Public Key Retrieval is not allowed".

To publish one tag that runs natively on both Intel and Apple Silicon hosts, build with buildx:

```bash
docker buildx build --platform linux/amd64,linux/arm64 -t mbagnall/openkm:6.3.13-mysql --push .
```

---

### Support

These images are maintained by [FlyingFlip Studios](https://flyingflip.com/). For bugs and questions, open an issue in the [issue queue](https://github.com/ElusiveMind/openkm/issues) or use the [contact form](https://flyingflip.com/contact-us). Connecting the image to an existing or shared MySQL server is not supported at this time; open an issue if you need it.
