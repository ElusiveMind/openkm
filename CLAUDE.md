# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Docker image build repository for **OpenKM 6.3.x** — an open-source document management system. It packages OpenKM with Tesseract OCR support, the KEA keyword extraction service, and persistent data volumes into Docker images published as `mbagnall/openkm` on DockerHub.

This is **not** the OpenKM application source code itself. The repo contains a Dockerfile, shell scripts, and expect scripts that automate OpenKM installation and configuration inside the image.

## Repository Structure

Everything lives in **`image/`**, which is the Docker build context:

- `Dockerfile` — Single-step build on Ubuntu 24.04 with Java 8, Tesseract OCR, and expect. Runs the OpenKM installer during the build, then adds KEA and the runtime entrypoint.
- `OKMInstaller.jar` — The interactive OpenKM Community Edition installer. It downloads OpenKM from update.openkm.com, so builds need network access.
- `setup.sh` — Build-time driver. Picks the expect script for the selected `DATABASE`, runs it, and fails the build if `/opt/tomcat-8.5.69/OpenKM.cfg` was not produced.
- `setup-expect-h2.exp` — Answers the installer prompts for the embedded h2 database.
- `setup-expect-server.exp` — Answers the installer prompts for mysql, mariadb, oracle, sqlserver, and postgresql. Reads connection details from `$env(...)` inside expect, so no templating is involved.
- `run.sh` — Runtime entrypoint (`/run.sh` in the image). Handles first-run vs. existing-data detection, deploys KEA, and starts Tomcat.
- `keas.war`, `keas.properties`, `vocabulary-sample.zip`, `md5sum.txt` — KEA keyword extraction service and its sample vocabulary.

## Build Process

One `docker build` produces the final image. The database backend is a build argument:

```bash
cd image
docker build . -t mbagnall/openkm:h2                                # DATABASE defaults to h2
docker build . --build-arg DATABASE=mysql -t mbagnall/openkm:mysql
docker push mbagnall/openkm:mysql
```

Inside the build, `setup.sh` runs the matching expect script against `OKMInstaller.jar`, which installs OpenKM into `/opt/tomcat-8.5.69/`. The KEA files and `run.sh` are then copied in, `/opt/tomcat-8.5.69/repository` is declared as a volume, and `/run.sh` is set as the CMD.

There is no longer a `docker run` + `docker commit` step and no separate `latest/` build.

## Build Arguments

- `DATABASE` — `h2` (default), `mysql`, `mariadb`, `oracle`, `sqlserver`, `postgresql`. Also exported as an `ENV` in the image so it is visible at runtime.
- `DATABASE_HOST` — Database server host (default: `db`)
- `DATABASE_NAME` — Database name, or SID for Oracle (default: `okmdb`)
- `DATABASE_USER` — Database user (default: `openkm`)
- `DATABASE_PASSWORD` — Database password (default: `OpenKM77`)

The connection details are baked into the image by the installer (Tomcat's `server.xml` datasource), so they cannot be changed at runtime without rebuilding.

- `ICU4J_VERSION` / `ICU4J_SHA256` — The ICU4J release swapped into `keas.war` during the build (default 74.2, checksum pinned). See Key Details.

## Runtime Environment Variables

- `OPEN_KM_URL` — Full OpenKM URL (default: `http://localhost:8080/OpenKM`)
- `OPEN_KM_BASE_URL` — Base URL (default: `http://localhost:8080`)

## Key Details

- OpenKM runs on Tomcat 8.5.69 at `/opt/tomcat-8.5.69/`
- First-run detection in `image/run.sh` checks for `okmdb.mv.db` (h2) or `datastore/` dir; if found, it flips Hibernate from `create` to `none` mode
- Default credentials: username `okmAdmin`, password `admin`
- `run.sh` uses `envsubst` to render `keas.properties` with `OPEN_KM_URL` / `OPEN_KM_BASE_URL`
- `keas.war` is patched during the build: its bundled ICU4J 3.4.4 (a Jena/IRI dependency) is replaced with a current ICU4J from Maven Central. The old ICU4J cannot parse a Java version with an update number above 255, and Ubuntu 24.04 ships Java 8u504, so without the swap KEA fails to start. The war checked into git is left unmodified; `md5sum.txt` describes that original.
