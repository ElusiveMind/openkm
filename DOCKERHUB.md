# OpenKM Community Edition with KEA

Last Updated: September 27, 2026

Unofficial Docker images of [OpenKM Community Edition](https://www.openkm.com/), an open-source document management system, with persistent data, Tesseract OCR, LibreOffice document conversion and the KEA keyword extraction service. Two OpenKM lines are published from this repository: the current **7.0** line and the maintained **6.3** line. Every current tag is a multi-architecture image, so it runs natively on Intel/AMD and ARM hosts, including Apple Silicon.

- Article and project page: [Community OpenKM Docker Container](https://flyingflip.com/projects/community-openkm) on FlyingFlip Studios
- OpenKM: [www.openkm.com](https://www.openkm.com/)
- OpenKM on GitHub: [github.com/openkm/document-management-system](https://github.com/openkm/document-management-system)
- Source for these images: [github.com/ElusiveMind/openkm](https://github.com/ElusiveMind/openkm) (branch `7.x` for the 7.0 images, branch `6.x` for the 6.3 images)
- Issues: [github.com/ElusiveMind/openkm/issues](https://github.com/ElusiveMind/openkm/issues)

---

## Supported Tags

Tags are named `<OpenKM version>-<database>`. Every tag below is built for `linux/amd64` and `linux/arm64`.

### OpenKM 7.0 (branch `7.x`)

| Tag                     | Database   |
| ----------------------- | ---------- |
| `7.0.3-mysql`, `latest` | MySQL      |
| `7.0.3-mariadb`         | MariaDB    |
| `7.0.3-postgresql`      | PostgreSQL |
| `7.0.3-oracle`          | Oracle     |
| `7.0.3-sqlserver`       | SQL Server |

### OpenKM 6.3 (branch `6.x`)

| Tag                 | Database   |
| ------------------- | ---------- |
| `6.3.13-mysql`      | MySQL      |
| `6.3.13-mariadb`    | MariaDB    |
| `6.3.13-postgresql` | PostgreSQL |
| `6.3.13-oracle`     | Oracle     |
| `6.3.13-sqlserver`  | SQL Server |

The MySQL tags are the ones this documentation covers and the ones that are run and tested. The other flavors are built from the same Dockerfile with the `DATABASE` build argument and bring their own database server.

### Legacy tags

These are the original OpenKM 6.3.12 images, built with the previous installer. They are kept so existing deployments keep working, but they are no longer updated and are single-architecture.

| Tag         | OpenKM | Database    | Architecture  | Last pushed    |
| ----------- | ------ | ----------- | ------------- | -------------- |
| `mysql`     | 6.3.12 | MySQL       | `linux/amd64` | September 2023 |
| `h2`        | 6.3.12 | Embedded H2 | `linux/amd64` | September 2023 |
| `mysql-arm` | 6.3.12 | MySQL       | `linux/arm64` | June 2025      |

The legacy images keep their repository at `/opt/tomcat-8.5.69/repository` rather than `/opt/tomcat/repository`. The embedded `h2` option is gone from the current OpenKM installer, so there is no `h2` flavor of 6.3.13 or 7.0.3, and OpenKM 7.0.3 does not initialize on H2 even when configured by hand.

---

## Which Line Should I Use?

- **New installations** should use the 7.0 line (`7.0.3-mysql`, also tagged `latest`).
- **Existing 6.3 repositories** should stay on the 6.3 line (`6.3.13-mysql`) until they have been migrated. OpenKM 7.0 cannot upgrade a 6.3 repository in place. Export from the 6.3 instance with the Repository Export tool, then import into a fresh 7.0 instance, following the [OpenKM migration guide](https://docs.openkm.com/okm-7.0/migrating-from-6-3-13-to-7-0/).
- A 6.3 repository and database cannot be shared with the 7.0 images. If one line has used a pair of `./data` and `./openkm-datastore` directories, point the other line at fresh directories.

| | 7.0 tags | 6.3 tags |
| --- | --- | --- |
| OpenKM release | 7.0.3 Community Edition | 6.3.13 Community Edition |
| Web context path | `/openkm` | `/OpenKM` |
| Java | OpenJDK 11 | OpenJDK 8 |
| KEA keyword extraction | Deployed, but cannot yet log in to OpenKM 7.0 | Working |
| Source branch | `7.x` | `6.x` |

---

## Running With MySQL

The quickest way to run OpenKM is Docker Compose, starting it together with MySQL. Save this as `docker-compose.yml` and run `docker compose up -d`. MySQL creates the `okmdb` database and the `openkm` user from its environment variables, with full rights on that database, so no manual grant step is needed.

```yml
services:
  # OPEN_KM_URL is used by KEA, inside the container, to call OpenKM's REST
  # API, so it always points at the container's own port 8080 and the
  # installed context path: /openkm for OpenKM 7.0, /OpenKM for OpenKM 6.3.
  # Leave it out to let the image pick the right one.
  #
  # OPEN_KM_BASE_URL is the address browsers use to reach OpenKM; KEA allows
  # it as a CORS origin. When hosting on a domain or behind a proxy, change
  # this one to that domain. The published port can be anything, but it must
  # map to port 8080 in the container.
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

For the 6.3 line, change the image to `mbagnall/openkm:6.3.13-mysql` and `OPEN_KM_URL` to `http://localhost:8080/OpenKM`, or leave `OPEN_KM_URL` out so the image picks its own context path.

Then go to:

`http://localhost:8080`

Tomcat redirects to the OpenKM context path. The first start creates the database schema and takes a little while; `docker compose logs -f openkm` shows Tomcat's log, and OpenKM is ready once it prints "Server startup in". The default administrative user and password is as follows:

**Username:** okmAdmin  
**Password:** admin

### Environment variables

| Variable           | Default                                  | Purpose                                                                                                   |
| ------------------ | ---------------------------------------- | --------------------------------------------------------------------------------------------------------- |
| `OPEN_KM_URL`      | `http://localhost:8080/<context path>`   | Address KEA uses inside the container to call OpenKM's REST API. Always the container's own port 8080.    |
| `OPEN_KM_BASE_URL` | `http://localhost:8080`                  | Address browsers use to reach OpenKM. KEA allows it as a CORS origin, so set it to your domain and port.  |

### Persistent data

Documents, the search index and caches live in `/opt/tomcat/repository` inside the container. The example mounts it at `./data`; keep that mount, or the installation re-initializes on every container rebuild or update. The MySQL data and the repository belong together: remove both or neither.

On a start with an existing repository the image switches OpenKM's schema setting to `none`. This matters most on 6.3, where the first-start setting drops and recreates every table. A first start that failed before the schema was created still leaves the datastore directory behind; to retry, remove the repository volume and the database together.

### Using your own database server

The connection details (host `db`, database `okmdb`, user `openkm`, password `OpenKM77`) are written into the image at build time. If you point the image at a database server you manage yourself, create the database and user like this before the first start:

```sql
CREATE DATABASE okmdb DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_bin;
CREATE USER 'openkm'@'%' IDENTIFIED BY 'OpenKM77';
GRANT ALL ON okmdb.* TO 'openkm'@'%' WITH GRANT OPTION;
```

To use different connection details, rebuild the image with the build arguments listed below. Connecting the image to an existing or shared MySQL server is not supported at this time; open an issue if you need it.

---

## KEA

The KEA keyword extraction service is deployed next to OpenKM at `/keas`, so with the example above it answers at `http://localhost:8080/keas`. A sample vocabulary ships with the image and is unpacked into `/opt/tomcat/kea` on every start.

- **On the 6.3 images** KEA logs in to OpenKM through the 6.x REST API at `OPEN_KM_URL` with the `okmAdmin` account, and browsers reach it through `OPEN_KM_BASE_URL`. KEA's copy of the administrator credentials is written to `/opt/tomcat/keas.properties` on every start from `/root/keas.properties` inside the image. If you change the `okmAdmin` password in OpenKM, update that file as well or KEA can no longer log in.
- **On the 7.0 images** KEA still uses the OpenKM 6.x SDK, which OpenKM 7.0 no longer serves, so it cannot yet log in to a 7.0 instance. It is included so the image is ready once a 7.0-compatible KEA is available.

---

## Building The Image

The image is built in a single step from the `image` folder of the source repository. Check out branch `7.x` for a 7.0 image or branch `6.x` for a 6.3 image. The OpenKM installer runs during the build (it downloads OpenKM and Tomcat from update.openkm.com and adds LibreOffice, ImageMagick and Xvfb with apt-get, so the build needs network access), and then the KEA service and the runtime entrypoint are layered on top.

Select the database backend with the `DATABASE` build argument. It defaults to `mysql`:

```bash
cd image
docker build . -t mbagnall/openkm:7.0.3-mysql
docker build . --build-arg DATABASE=postgresql --build-arg DATABASE_HOST=postgres -t mbagnall/openkm:7.0.3-postgresql
```

`DATABASE` accepts `mysql`, `mariadb`, `oracle`, `sqlserver` or `postgresql`. The connection details are written into the image at build time and can be set with these build arguments:

| Build argument      | Default                                | Purpose                              |
| ------------------- | -------------------------------------- | ------------------------------------ |
| `DATABASE_HOST`     | `db`                                   | Host name of the database server     |
| `DATABASE_NAME`     | `okmdb`                                | Database name (the SID for Oracle)   |
| `DATABASE_USER`     | `openkm`                               | User to connect as                   |
| `DATABASE_PASSWORD` | `OpenKM77`                             | Password for that user               |
| `OPENKM_VERSION`    | `7.0.3` on `7.x`, `6.3.13` on `6.x`    | OpenKM release the installer fetches |

To publish one tag that runs natively on both Intel and Apple Silicon hosts, build with buildx:

```bash
docker buildx build --platform linux/amd64,linux/arm64 \
  --build-arg DATABASE=mysql \
  --build-arg OPENKM_VERSION=7.0.3 \
  -t mbagnall/openkm:7.0.3-mysql \
  --push .
```

### Adjustments the images make

- **6.3 with MySQL 8:** the build adds `allowPublicKeyRetrieval=true` to the datasource URL in Tomcat's `server.xml`. Without it MySQL 8's default authentication rejects every connection from the 6.3 driver settings with "Public Key Retrieval is not allowed".
- **7.0 with MySQL:** the installer writes `serverTimezone=CET` into the JDBC URL while the JVM and the MySQL image run in UTC, which shifts stored times and makes document preview tokens expire on arrival. The build points the driver at UTC instead.
- **KEA on current Java 8:** the KEA web application bundled an old ICU4J that cannot parse recent Java 8 update numbers. The build swaps in a current ICU4J from Maven Central.

---

## Support

These images are maintained by [FlyingFlip Studios](https://flyingflip.com/). Read the accompanying article, [Community OpenKM Docker Container](https://flyingflip.com/projects/community-openkm), for background on the project. For bugs and questions, open an issue in the [issue queue](https://github.com/ElusiveMind/openkm/issues) or use the [contact form](https://flyingflip.com/contact-us). OpenKM itself is developed at [github.com/openkm/document-management-system](https://github.com/openkm/document-management-system) and documented at [www.openkm.com](https://www.openkm.com/).
