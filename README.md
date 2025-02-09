# odooBundle-Codebase Installation Guide

## 1. Install WSL2
**Official Docs:**
[Windows Subsystem for Linux Installation Guide](https://learn.microsoft.com/windows/wsl/install)

1. Open PowerShell or Windows Terminal as Administrator.
2. Run:
   ```powershell
   wsl --install
   ```
   This installs WSL2 by default on Windows 10 (version 2004 and higher) or Windows 11.
3. Restart your computer if prompted.

---

## 2. Install a Linux Distribution from Microsoft Store
**Official Docs:**
[Installing Linux Distros from the Microsoft Store](https://learn.microsoft.com/windows/wsl/install#step-4---download-the-linux-kernel-update-package)

1. Open the **Microsoft Store** in Windows.
2. Search for **Ubuntu** (or your preferred distribution, e.g., Debian).
3. Click **Get** and then **Install**.
4. Launch the newly installed distribution from the Start menu.
5. Complete the initial setup steps (username, password, etc.).

---

## 3. Install Docker Desktop
**Official Docs:**
[Install Docker Desktop on Windows](https://docs.docker.com/desktop/windows/install/)

1. Download **Docker Desktop for Windows** from the link above.
2. Run the installer and follow the on-screen instructions.
3. When prompted, **enable** the option to use **WSL 2** instead of Hyper-V if it’s available.

---

## 4. Enable WSL Integration in Docker Desktop
**Official Docs:**
[Docker Desktop WSL Integration](https://docs.docker.com/desktop/windows/wsl/)

1. Open **Docker Desktop**.
2. Click on **Settings** (gear icon).
3. Go to **Resources** > **WSL Integration**.
4. Turn on **Enable integration with my default WSL distro** (and/or select the specific distro, e.g., Ubuntu).

![WSL Integration Screenshot](https://docs.docker.com/desktop/windows/images/wsl-docker-desktop-settings.png)

---

## 5. Add Your Linux User to the Docker Group
**Official Docs:**  
[Manage Docker as a non-root user](https://docs.docker.com/engine/install/linux-postinstall/)

1. In your **Ubuntu (WSL2)** terminal, run:
   ```bash
   sudo usermod -aG docker $(whoami)
   ```
2. Close the terminal (logout) and reopen it (login again) so that the group membership is re-evaluated.

---

## 6. Choose a Location for Your Project
You can place your project files anywhere accessible to WSL2. It’s generally recommended to keep your project **inside** the Linux filesystem (e.g., in `~/projects`) rather than on the Windows filesystem for better performance.

---

## 7. Clone the odooBundle-Codebase Repository
1. Make sure `git` is installed in your WSL environment:
   ```bash
   sudo apt-get update
   sudo apt-get install git
   ```
2. Clone the repository:
   ```bash
   git clone https://github.com/Hoschoc/odooBundle-Codebase.git
   ```
3. Enter the project directory:
   ```bash
   cd odooBundle-Codebase
   ```
4. Update the submodules:
   ```bash
   git submodule update --init --recursive --depth=1
   ```

---

## 8. Start the Docker Containers
**Official Docs:**
[Docker Compose Overview](https://docs.docker.com/compose/)

1. Run:
   ```bash
   docker compose up -d
   ```
   This command pulls the required images (if not already present) and starts the containers in the background.

2. Open **Docker Desktop** and verify that all containers are running without errors.

---

## 9. Access Odoo in Your Browser
1. In your web browser, go to:
   ```
   http://localhost:8069
   ```
2. If everything is running correctly, you will see the Odoo web interface.

---

## 10. Create an Odoo Database
Inside the running Odoo container, there is a helper script (`create-odoo-db.py`) to set up your initial Odoo database and user credentials.

1. To create the database with **default credentials** (`admin` / `admin`):
   ```bash
   docker compose exec odoo create-odoo-db.py
   ```
2. To override the default login and password, use:
   ```bash
   docker compose exec odoo create-odoo-db.py --login <YOUR_LOGIN> --password <YOUR_PASSWORD>
   ```
   Example:
   ```bash
   docker compose exec odoo create-odoo-db.py --login myuser --password mypass
   ```

---

## 11. Log In
- Default login credentials:
  **Login:** `admin`
  **Password:** `admin`
- If you changed the credentials in the previous step, use those instead.

---

## Summary
You now have Odoo running in Docker on WSL2! You can modify the project, pull updates, and manage everything through Docker Compose. If you need to bring the containers down, simply run:
```bash
docker compose down
```
And bring them back up again when needed:
```bash
docker compose up -d
```

---

### Additional Resources
- [Odoo Official Documentation](https://www.odoo.com/documentation/)
- [Git Official Documentation](https://git-scm.com/doc)
- [Docker Compose File Reference](https://docs.docker.com/compose/compose-file/)

