#!/usr/bin/env python3
import time, sqlite3, hashlib
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC

BASE     = "http://127.0.0.1:5000"
DB_PATH  = "bassdrop.db"
USERNAME = "griz"
PASSWORD = "funkysax123"

def reset_griz_password():
    try:
        db = sqlite3.connect(DB_PATH)
        h  = hashlib.md5(PASSWORD.encode()).hexdigest()
        db.execute("UPDATE users SET password=? WHERE username=?", (h, USERNAME))
        db.commit()
        db.close()
        print("[bot] griz's password has been reset", flush=True)
    except Exception as e:
        print(f"[bot] failed to reset password: {e}", flush=True)

def make_driver():
    opts = Options()
    opts.add_argument("--headless")
    opts.add_argument("--no-sandbox")
    opts.add_argument("--disable-dev-shm-usage")
    opts.add_argument("--ignore-certificate-errors")
    opts.add_argument("--disable-web-security")
    opts.add_argument("--allow-running-insecure-content")
    opts.set_capability("goog:loggingPrefs", {"browser": "ALL"})
    return webdriver.Chrome(options=opts)

def bot_visits():
    while True:
        driver = None
        try:
            driver = make_driver()
            wait   = WebDriverWait(driver, 10)

            # Attempt login
            driver.get(f"{BASE}/login")
            wait.until(EC.presence_of_element_located((By.NAME, "username")))
            driver.execute_script(f"""
                document.querySelector('[name=username]').value = '{USERNAME}';
                document.querySelector('[name=password]').value = '{PASSWORD}';
                document.querySelector('form').submit();
            """)
            wait.until(EC.url_changes(f"{BASE}/login"))
            time.sleep(2)

            # Check if login succeeded
            if "/login" in driver.current_url:
                print("[bot] login failed — resetting griz's password", flush=True)
                driver.quit()
                driver = None
                reset_griz_password()
                time.sleep(2)

                # Retry login after reset
                driver = make_driver()
                wait   = WebDriverWait(driver, 10)
                driver.get(f"{BASE}/login")
                wait.until(EC.presence_of_element_located((By.NAME, "username")))
                driver.execute_script(f"""
                    document.querySelector('[name=username]').value = '{USERNAME}';
                    document.querySelector('[name=password]').value = '{PASSWORD}';
                    document.querySelector('form').submit();
                """)
                wait.until(EC.url_changes(f"{BASE}/login"))
                time.sleep(2)

            # Confirm cookies
            cookies = {c["name"]: c["value"] for c in driver.get_cookies()}
            print(f"[bot] logged in — cookies: {list(cookies.keys())}", flush=True)

            if "flag10" not in cookies:
                print("[bot] WARNING: flag10 cookie not set", flush=True)
            else:
                print("[bot] flag10 cookie present", flush=True)

            # Visit forum — triggers XSS cookie steal and CSRF payload if present
            driver.get(f"{BASE}/forum")
            time.sleep(5)

            for entry in driver.get_log("browser"):
                print(f"[bot:forum] {entry}", flush=True)

            # Visit messages — triggers XSS + CSRF payload if present
            driver.get(f"{BASE}/messages")
            time.sleep(5)

            for entry in driver.get_log("browser"):
                print(f"[bot:messages] {entry}", flush=True)

        except Exception as e:
            print(f"[bot] error: {e}", flush=True)
        finally:
            if driver:
                driver.quit()

        print("[bot] sleeping 30s...\n", flush=True)
        time.sleep(30)

if __name__ == "__main__":
    print("[bot] starting...", flush=True)

    bot_visits()