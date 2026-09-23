# OpenKM with KEA

Last Updated: September 23, 2026

Unofficial Docker images of [OpenKM 7.0 Community Edition](https://www.openkm.com/), an open-source document management system, with persistent data, Tesseract OCR, LibreOffice document conversion and the KEA keyword extraction service. Every tag is a multi-architecture image, so it runs natively on Intel/AMD and ARM hosts, including Apple Silicon.

- Images: [hub.docker.com/r/mbagnall/openkm](https://hub.docker.com/r/mbagnall/openkm)
- Source: [github.com/ElusiveMind/openkm](https://github.com/ElusiveMind/openkm)

### Supported Tags

| Tag                       | Database   |
| ------------------------- | ---------- |
| `7.0.3-mysql`, `latest`   | MySQL      |
| `7.0.3-mariadb`           | MariaDB    |
| `7.0.3-postgresql`        | PostgreSQL |

Tags are named `<OpenKM version>-<database>`. OpenKM 7.0 needs a database server; it also supports Oracle and SQL Server, and images for those can be built from this repository with the `DATABASE` build argument described below. As of this README, `7.0.3-mysql` is the tag covered in this document.

The older `mysql` and `h2` tags are the OpenKM 6.3.12 line. The embedded `h2` option is gone in 7.0: the installer no longer offers it, and OpenKM 7.0.3 does not initialize on H2 even when configured by hand.

**Coming from the 6.3 images?** OpenKM 7.0 cannot upgrade a 6.3 repository in place. Export from the old instance with the Repository Export tool, then import into a fresh 7.0 instance, following the [OpenKM migration guide](https://docs.openkm.com/kcenter/view/okm-7.0/migrating-from-6313-to-70.html). Keep using the 6.3 tags until that is done.

---

### Running With MySQL

The quickest way to run OpenKM is Docker Compose, starting it together with MySQL. Save this as `docker-compose.yml` and run `docker compose up -d`. MySQL creates the `okmdb` database and the `openkm` user from its environment variables, with full rights on that database, so no manual grant step is needed.

```yml
services:
  # If hosting on a domain, change "localhost:8080" in the two URLs to your
  # domain and optionally change the published port. Behind an ingress or
  # reverse proxy the published port can be anything, but it must map to
  # port 8080 in the container.
  openkm:
    image: mbagnall/openkm:7.0.3-mysql
    container_name: openkm
    environment:
      OPEN_KM_URL: http://localhost:8080/openkm
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

The first start creates the database schema and takes a little while; `docker compose logs -f openkm` shows Tomcat's log, and OpenKM is ready once it prints "Server startup in". The default administrative user and password is as follows:

**Username:** okmAdmin  
**Password:** admin

Documents, the search index and caches live in `/opt/tomcat/repository` inside the container. The example mounts it at `./data`; keep that mount, or the installation re-initializes on every container rebuild or update. The MySQL data and the repository belong together: remove both or neither.

If you point the image at a database server you manage yourself, create the database and user like this before the first start:

```sql
CREATE DATABASE okmdb DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_bin;
CREATE USER 'openkm'@'%' IDENTIFIED BY 'OpenKM77';
GRANT ALL ON okmdb.* TO 'openkm'@'%' WITH GRANT OPTION;
```

### KEA

The KEA keyword extraction service is deployed next to OpenKM at `/keas`. It still uses the OpenKM 6.x SDK, which OpenKM 7.0 no longer serves, so it cannot yet log in to a 7.0 instance. It is included so the image is ready once a 7.0-compatible KEA is available.

---

### Building The Image

The image is built in a single step from the `image` folder. The OpenKM installer runs during the build (it downloads OpenKM and Tomcat from update.openkm.com, so the build needs network access), and then the KEA service and the runtime entrypoint are layered on top.

Select the database backend with the `DATABASE` build argument. It defaults to `mysql`:

```bash
cd image
docker build . -t mbagnall/openkm:7.0.3-mysql
docker build . --build-arg DATABASE=postgresql --build-arg DATABASE_HOST=postgres -t mbagnall/openkm:7.0.3-postgresql
```

`DATABASE` accepts `mysql`, `mariadb`, `oracle`, `sqlserver` or `postgresql`. The connection details are written into the image at build time and can be set with these build arguments:

| Build argument      | Default   | Purpose                                  |
| ------------------- | --------- | ---------------------------------------- |
| `DATABASE_HOST`     | `db`      | Host name of the database server         |
| `DATABASE_NAME`     | `okmdb`   | Database name (the SID for Oracle)       |
| `DATABASE_USER`     | `openkm`  | User to connect as                       |
| `DATABASE_PASSWORD` | `OpenKM77`| Password for that user                   |
| `OPENKM_VERSION`    | `7.0.3`   | OpenKM release the installer fetches     |

To publish one tag that runs natively on both Intel and Apple Silicon hosts, build with buildx:

```bash
docker buildx build --platform linux/amd64,linux/arm64 -t mbagnall/openkm:7.0.3-mysql --push .
```

---

### Support

These images are maintained by [FlyingFlip Studios](https://flyingflip.com/). For bugs and questions, open an issue in the [issue queue](https://github.com/ElusiveMind/openkm/issues) or use the [contact form](https://flyingflip.com/contact-us). Connecting the image to an existing or shared MySQL server is not supported at this time; open an issue if you need it.
