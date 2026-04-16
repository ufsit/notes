# Installing and Running Planka
1. Change the `DEFAULT_ADMIN_PASSWORD` value in the `.env` file.
2. Change the `BASE_URL` and `SECRET_KEY` values in the `.env` file.
3. Set the password in `.env` to whatever the `planka` user's password will be set to in step 5.
4. Edit the password for the `planka` user under `DATABASE_URL` in the `.env` file.
5. Run `01-root.sh` as the `root` user.
6. If on Kali, run `sudo apt install npm`.
7. If PostgreSQL needs to be manually started, run `pg_ctlcluster 17 main start`.
8. Run `02-postgres.sh` as the `postgres` user.
9. Copy `03-planka.sh` to `/tmp` and run `cd /tmp`.
10. Run `03-planka.sh` as the `planka` user.
11. Run `sudo -u planka bash`
12. Run `cd /var/www/planka`
13. Run `npm run db:init`
14. Run `npm start --prod` to start Planka.
