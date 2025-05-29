
# 🐳 WordPress Local Migration to Docker with GitHub Actions  
**Prepared by: Karan Urao**  
**Environment: Local development (MAMP → Docker)**

---

## 📁 Project Overview

This guide outlines the steps to:

- Migrate a WordPress site from MAMP to Docker
- Use GitHub to manage source control
- Use GitHub Actions (`ci.yml`) for automated Docker image builds
- Handle local testing via `http://localhost:8080`

---

## 🧰 Folder Structure

```
wordpress-migration/
├── .github/
│   └── workflows/
│       └── ci.yml
├── docker-compose.yaml
├── Dockerfile
├── Dockerfile.db
├── wp-content/
│   └── themes/
│   └── plugins/
│   └── uploads/
├── sql/
│   └── init.sql
│   └── init.zip
├── README.md
├── .gitignore
```

---

## ✅ Step-by-Step Migration Guide

### 1. Copy Your Site Files

- From your MAMP `htdocs`, copy the full `wp-content` folder.
- Export the WordPress database from phpMyAdmin:
  ```bash
  mysqldump -u root -p your_db_name > init.sql
  zip init.zip init.sql
  ```

Place `init.zip` inside a new `sql/` directory.

---

### 2. Update Site URL in SQL (Very Important)

Before zipping the SQL file, **update the site URL** to work locally:

```sql
UPDATE wp_options SET option_value = 'http://localhost:8080' WHERE option_name IN ('siteurl', 'home');
```

This ensures that image links, themes, and admin redirects work correctly.

---

### 3. Create Docker Configuration

#### Dockerfile
Sets up the WordPress container.
```Dockerfile
FROM wordpress:php8.1-apache
COPY wp-content /var/www/html/wp-content
RUN chown -R www-data:www-data /var/www/html/wp-content && \
    chmod -R 755 /var/www/html/wp-content
```

#### Dockerfile.db
Builds the MariaDB container with the initial DB dump.
```Dockerfile
FROM mariadb:10.6
RUN apt-get update && apt-get install -y unzip
COPY ./sql /docker-entrypoint-initdb.d
RUN cd /docker-entrypoint-initdb.d && unzip init.zip
CMD ["mysqld", "--character-set-server=utf8mb4", "--collation-server=utf8mb4_unicode_ci"]
```

#### docker-compose.yaml
Runs both containers.
```yaml
services:
  wordpress:
    build:
      context: .
      dockerfile: Dockerfile
    ports:
      - "8080:80"
    environment:
      - WORDPRESS_DB_HOST=db
      - WORDPRESS_DB_NAME=ctci
      - WORDPRESS_DB_USER=ctci
      - WORDPRESS_DB_PASSWORD=superStrongPassword
    depends_on:
      - db

  db:
    build:
      context: .
      dockerfile: Dockerfile.db
    environment:
      - MARIADB_DATABASE=ctci
      - MARIADB_USER=ctci
      - MARIADB_PASSWORD=superStrongPassword
      - MARIADB_ROOT_PASSWORD=superStrongPasswordforRoot
```

---

### 4. Run Locally with Docker

```bash
docker-compose up --build
```

Access your site at:  
**👉 http://localhost:8080**

---

## 🚨 Troubleshooting and Cleanup

### 📷 Images Not Showing?
- Make sure `wp-content/uploads/` exists and contains media files.
- Check that URLs are correct (`http://localhost:8080/wp-content/uploads/...`)
- Use incognito window to clear cache issues.

---

### ⚠️ File Not Found Errors During Build?
If Docker can’t find `sql/init.zip`, verify:
- You’re in the correct directory when running `docker-compose`
- Your `sql/` folder is at the root of the project
- File is named exactly `init.zip`

---

### 🔁 Reset/Rebuild Docker Containers

If you need to rebuild everything:

```bash
docker-compose down -v
docker-compose up --build
```

---

## ⚙️ GitHub Actions for CI/CD

### 📄 `.github/workflows/ci.yml`

This file tells GitHub to:
- Build Docker images for WordPress and MariaDB
- Push them to GitHub Container Registry (GHCR)

#### Sample Config:

```yaml
name: Build & Push Docker Images

on:
  push:
    branches: [ "main" ]

jobs:
  build-and-push:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write

    steps:
      - name: Checkout code
        uses: actions/checkout@v3

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3

      - name: Log in to GitHub Container Registry
        uses: docker/login-action@v2
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - name: Build & push WordPress image
        uses: docker/build-push-action@v4
        with:
          context: .
          file: ./Dockerfile
          push: true
          tags: ghcr.io/karanurao/govtech_ctci_wp:latest

      - name: Build & push DB image
        uses: docker/build-push-action@v4
        with:
          context: .
          file: ./Dockerfile.db
          push: true
          tags: ghcr.io/karanurao/govtech_ctci_db:latest
```

> After pushing to GitHub, check the **Actions** tab for build status and the **Packages** tab for your Docker images.

---

## 📝 Final Notes

- Deployment to a live server (e.g. via WONS) is possible later by pointing a domain and sharing your repo.
- For now, everything runs cleanly and safely on your local machine via Docker.
- You can reuse this workflow for any future WordPress projects.
