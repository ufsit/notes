#!/usr/bin/env python3
"""
RAVER'S PARADISE - Intentionally Vulnerable Web App
FOR EDUCATIONAL / CTF USE ONLY
"""

import sqlite3
import os
import base64
import time
import json
import requests
import hashlib
import subprocess
import logging
from datetime import datetime, timedelta
from functools import wraps
from flask import (
    Flask, render_template, request, redirect, url_for,
    session, make_response, send_file, jsonify, g, abort
)
from markupsafe import Markup

from waitress import serve

# ──────────────────────────────────────────────
# App Setup
# ──────────────────────────────────────────────
app = Flask(__name__)
app.secret_key = "rav3rs_g0nna_rav3_s3cr3t_k3y_2024"

BASE_DIR   = os.path.dirname(os.path.abspath(__file__))
DB_PATH    = os.path.join(BASE_DIR, "ravers.db")
UPLOAD_DIR = os.path.join(BASE_DIR, "uploads")
LOG_DIR    = os.path.join(BASE_DIR, "logs")
LOG_FILE   = os.path.join(LOG_DIR, "app.log")
SECRET_DIR = os.path.join(BASE_DIR, "secret")


os.makedirs(UPLOAD_DIR, exist_ok=True)
os.makedirs(LOG_DIR,    exist_ok=True)
os.makedirs(SECRET_DIR, exist_ok=True)

# ──────────────────────────────────────────────
# Write static secret files on startup
# ──────────────────────────────────────────────
import base64

def caesar_cipher(text, shift=13):
    result = ""
    for char in text:
        if char.isalpha():
            base = ord('A') if char.isupper() else ord('a')
            result += chr((ord(char) - base + shift) % 26 + base)
        else:
            result += char
    return result

def write_secret_files():
    
    # Easter egg hint
    archive_dir = os.path.join(BASE_DIR, "archive")
    os.makedirs(archive_dir, exist_ok=True)
    egg_file = os.path.join(archive_dir, "easteregg.txt")
    if not os.path.exists(egg_file):
        plaintext   = "You found it. The path is: /ravers/love/small/easter/egg/sidequests"
        caesar_text = caesar_cipher(plaintext, shift=13)
        encoded     = base64.b64encode(caesar_text.encode()).decode()
        with open(egg_file, "w") as f:
            f.write(encoded + "\n")

    # Default artists.txt
    artists_file = os.path.join(BASE_DIR, "static", "artists.txt")
    os.makedirs(os.path.join(BASE_DIR, "static"), exist_ok=True)
    if not os.path.exists(artists_file):
        with open(artists_file, "w") as f:
            f.write(
                "GRiZ, REZZ, LSDREAM, Dom Dolla, Porter Robinson, "
                "Kesha, Galantis, deadmau5, Excision, Illenium, Subtronics\n"
            )
# ──────────────────────────────────────────────
# Logging (vulnerable to log poisoning)
# ──────────────────────────────────────────────
logging.basicConfig(
    filename=LOG_FILE,
    level=logging.INFO,
    format="%(asctime)s - %(levelname)s - %(message)s"
)

def log_event(msg):
    """Logs raw user-controlled input — intentionally vulnerable."""
    logging.info(msg)
    with open(LOG_FILE, "a") as f:
        f.write(f"[{datetime.now()}] {msg}\n")

# ──────────────────────────────────────────────
# Database Setup
# ──────────────────────────────────────────────
def get_db():
    if "db" not in g:
        g.db = sqlite3.connect(DB_PATH)
        g.db.row_factory = sqlite3.Row
    return g.db

@app.teardown_appcontext
def close_db(e=None):
    db = g.pop("db", None)
    if db:
        db.close()

def init_db():
    con = sqlite3.connect(DB_PATH)
    cur = con.cursor()
    cur.executescript("""
        CREATE TABLE IF NOT EXISTS users (
            id       INTEGER PRIMARY KEY AUTOINCREMENT,
            username TEXT UNIQUE NOT NULL,
            password TEXT NOT NULL,
            email    TEXT,
            role     TEXT DEFAULT 'user',
            bio      TEXT
        );
        CREATE TABLE IF NOT EXISTS notes (
            id      INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL,
            title   TEXT,
            content TEXT
        );
        CREATE TABLE IF NOT EXISTS sessions (
            id         INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id    INTEGER,
            token      TEXT,
            created_at TEXT
        );
        CREATE TABLE IF NOT EXISTS secrets (
            id      INTEGER PRIMARY KEY AUTOINCREMENT,
            name    TEXT,
            value   TEXT
        );
    """)

    users = [
        (1, "admin",         "plur4life!",   "admin@raversparadise.com",   "admin", "The head raver. I know all the flags."),
        (2, "griz_fan",      "funkysax99",   "griz@raversparadise.com",    "user",  "Live music is life 🎷"),
        (3, "rezz_devotee",  "hypnotized88", "rezz@raversparadise.com",    "user",  "Two red eyes in the dark 👁️👁️"),
        (4, "porter_head",   "nurture2021",  "porter@raversparadise.com",  "user",  "Worlds inside worlds 🌸"),
        (5, "lsdream_rider", "cosm1cluv",    "lsdream@raversparadise.com", "user",  "Surrender to the vibe 🌌"),
    ]
    cur.executemany(
        "INSERT OR IGNORE INTO users (id,username,password,email,role,bio) VALUES (?,?,?,?,?,?)",
        users
    )

    notes = [
    (1, 1, "VIP Guest List",         "Griz, Rezz, LSDREAM, Dom Dolla, Porter Robinson, Kesha, Galantis"),
    (2, 2, "Setlist Wishes",         "I hope Griz plays Infinite tonight!"),
    (3, 3, "Hypnotic Thoughts",      "The bass hypnotizes me every single time."),
    (4, 4, "Porter Robinson Lyrics", "I will always be here for you."),
    (5, 5, "Cosmic Notes",           "LSDREAM's Cosmic Love Tour was transcendental."),
    (6, 1, "PRIVATE — DO NOT READ",  "flag3{1d0r_4dm1n_pr1v4t3_n0t3_exf1ltr4t3d}"),
    ]
    cur.executemany(
        "INSERT OR IGNORE INTO notes (id,user_id,title,content) VALUES (?,?,?,?)",
        notes
    )

    secrets = [
    (1, "sqli_flag",  "flag2{plur_and_p0wn_th3_d4nc3fl00r}"),
    (2, "vip_token",  "PLUR4EVER"),
    ]
    cur.executemany(
        "INSERT OR IGNORE INTO secrets (id,name,value) VALUES (?,?,?)",
        secrets
    )

    con.commit()
    con.close()



# ──────────────────────────────────────────────
# Auth helpers
# ──────────────────────────────────────────────
def login_required(f):
    @wraps(f)
    def decorated(*args, **kwargs):
        # Only the signed Flask session is valid — flag10 cookie grants nothing
        if "username" not in session:
            return redirect(url_for("login"))
        return f(*args, **kwargs)
    return decorated

def admin_required(f):
    @wraps(f)
    def decorated(*args, **kwargs):
        if session.get("role") != "admin":
            return "Access Denied — Admins Only 🚫", 403
        return f(*args, **kwargs)
    return decorated

def bot_visits():
    import urllib.request, urllib.parse
    time.sleep(5)
    while True:
        try:
            opener = urllib.request.build_opener(urllib.request.HTTPCookieProcessor())
            opener.open(
                "http://127.0.0.1:5000/login",
                urllib.parse.urlencode({"username": "griz", "password": "funkysax123"}).encode(),
            )
            opener.open("http://127.0.0.1:5000/forum")
            opener.open("http://127.0.0.1:5000/messages")
        except Exception:
            pass
        time.sleep(30)

# ══════════════════════════════════════════════
# ROUTES
# ══════════════════════════════════════════════

# ── Index ──────────────────────────────────────────────────────────────────────
@app.route("/")
def index():
    return render_template("index.html")

# ──────────────────────────────────────────────
# VULN 1 — SQL Injection Login
# ──────────────────────────────────────────────
@app.route("/login", methods=["GET", "POST"])
def login():
    error = None
    if request.method == "POST":
        username = request.form.get("username", "")
        password = request.form.get("password", "")

        log_event(f"Login attempt for user: {username}")

        # ⚠️  VULNERABLE — no parameterisation, plaintext passwords
        query = f"SELECT * FROM users WHERE username='{username}' AND password='{password}'"
        try:
            db   = get_db()
            cur  = db.execute(query)
            user = cur.fetchone()
        except Exception as e:
            error = f"DB Error: {e}"
            return render_template("login.html", error=error)

        if user:
            session["user_id"]  = user["id"]
            session["username"] = user["username"]
            session["role"]     = user["role"]
            return redirect(url_for("dashboard"))
        else:
            error = "Invalid credentials. The vibe check failed 💀"

    return render_template("login.html", error=error)

@app.route("/logout")
def logout():
    session.clear()
    return redirect(url_for("index"))

# ──────────────────────────────────────────────
# Dashboard
# ──────────────────────────────────────────────
@app.route("/dashboard")
@login_required
def dashboard():
    db    = get_db()
    # ⚠️  IDOR still exists — admin is hidden from UI but user_id=1 still works
    # Filter out admin from the community members list
    users = db.execute(
        "SELECT id, username, role FROM users WHERE role != 'admin'"
    ).fetchall()
    return render_template("dashboard.html", users=users)

# ──────────────────────────────────────────────
# VULN 2 — IDOR + VULN 3 — SQL Injection (notes)
# ──────────────────────────────────────────────
@app.route("/notes")
@login_required
def notes():
    # If no user_id param, redirect to default so ?user_id= is always in the URL
    if "user_id" not in request.args:
        return redirect(url_for("notes", user_id=session["user_id"]))

    requested_id = request.args.get("user_id", session["user_id"])
    search       = request.args.get("search", "")
    user_id      = requested_id

    db = get_db()

    if search:
        query = f"SELECT * FROM notes WHERE user_id={user_id} AND title='{search}'"
    else:
        query = f"SELECT * FROM notes WHERE user_id={user_id}"

    try:
        notes_rows = db.execute(query).fetchall()
        error      = None
    except Exception as e:
        notes_rows = []
        error      = str(e)

    return render_template("notes.html", notes=notes_rows,
                           user_id=user_id, search=search, error=error)


@app.route("/archive")
@login_required
def archive():
    archive_dir = os.path.join(BASE_DIR, "archive")
    try:
        files = os.listdir(archive_dir)
    except Exception:
        files = []
    return render_template("archive.html", files=files)


@app.route("/archive/<filename>")
@login_required
def archive_file(filename):
    filepath = os.path.join(BASE_DIR, "archive", filename)
    try:
        with open(filepath, "r") as f:
            content = f.read()
    except Exception:
        content = "File not found."
    return render_template("archive_file.html", filename=filename, content=content)

@app.errorhandler(500)
def internal_error(e):
    return render_template("500.html"), 500

@app.errorhandler(404)
def not_found(e):
    return render_template("404.html"), 404

@app.errorhandler(403)
def forbidden(e):
    return render_template("403.html"), 403

# ──────────────────────────────────────────────
# VULN 4 — LFI  (Local File Inclusion)
# /artists?file=../../../../secret/flag.txt  → LFI flag
# /artists?file=../logs/app.log              → log poison step 2
# ──────────────────────────────────────────────
# ──────────────────────────────────────────────
# VULN 4 — LFI  (Local File Inclusion)
# /artists?file=../../../../secret/flag.txt
# ──────────────────────────────────────────────
@app.route("/artists")
def artists():
    if "file" not in request.args:
        return redirect(url_for("artists", file="artists.txt"))

    filename = request.args.get("file", "artists.txt")

    if filename.startswith("/"):
        filepath = filename
    else:
        filepath = os.path.join(BASE_DIR, "static", filename)

    content = ""
    try:
        with open(filepath, "r") as fh:
            content = fh.read()
        log_event(f"File read: {filepath}")
    except Exception as e:
        content = f"Could not load file: {e}"

    if "app.log" in filename:
        cmd = request.args.get("cmd", "")
        if cmd:
            try:
                # ⚠️  RCE — flag is in secret/flag5.txt, not shown in browser
                rce_out = subprocess.check_output(
                    cmd, shell=True, stderr=subprocess.STDOUT
                ).decode()
                content += f"\n\n[RCE OUTPUT — cmd={cmd}]\n{rce_out}"
            except Exception as ex:
                content += f"\n[RCE Error: {ex}]"

    return render_template("artists.html", content=content, filename=filename)



# ──────────────────────────────────────────────
# VULN 7 — Log Poisoning landing page  (the "viewer")
# Step 1: poison at /login  with  <?php system($_GET['cmd']); ?>
# Step 2: include log via   /artists?file=../logs/app.log&cmd=id
# This page explains the chain and shows current log content.
# ──────────────────────────────────────────────
@app.route("/logs")
@login_required
def view_logs():
    logs = ""
    try:
        with open(LOG_FILE, "r") as fh:
            logs = fh.read()
    except Exception:
        logs = "No activity found."

    return render_template("logs.html", logs=logs)

# ──────────────────────────────────────────────
# VULN 8 — Unrestricted File Upload + PHP Shell sim
# ──────────────────────────────────────────────
@app.route("/upload", methods=["GET", "POST"])
@login_required
def upload():
    message  = ""
    ALLOWED  = {".png", ".jpg", ".jpeg", ".gif", ".phtml"}
    BLOCKED  = {".php", ".php3", ".php4", ".php5", ".phar"}

    if request.method == "POST":
        f = request.files.get("file")
        if f:
            filename  = f.filename
            ext       = os.path.splitext(filename)[1].lower()

            if ext in BLOCKED:
                message = "❌ File type not allowed. Please upload a .png, .jpg, or .gif file."
            else:
                save_path = os.path.join(UPLOAD_DIR, filename)
                f.save(save_path)
                log_event(f"File uploaded: {filename} by {session.get('username')}")
                message = f"✅ '{filename}' uploaded successfully!"
        else:
            message = "No file selected."

    return render_template("upload.html", message=message)


@app.route("/uploads/<path:filename>")
def serve_upload(filename):
    filepath = os.path.join(UPLOAD_DIR, filename)
    if not os.path.exists(filepath):
        return "File not found", 404

    if filename.endswith(".phtml"):
        try:
            # Execute the PHP file directly with php-cli
            # Pass any GET params as environment variables so $_GET works
            env = os.environ.copy()
            env["QUERY_STRING"] = request.query_string.decode()

            # Build $_GET superglobal from query string
            for key, value in request.args.items():
                env[f"PHP_VAR_{key}"] = value

            # Write a small wrapper that sets $_GET and includes the file
            wrapper = f"""<?php
$parts = array();
parse_str(getenv('QUERY_STRING'), $_GET);
include('{filepath}');
?>"""
            wrapper_path = os.path.join(UPLOAD_DIR, f"_wrapper_{filename}")
            with open(wrapper_path, "w") as f:
                f.write(wrapper)

            proc = subprocess.Popen(
                ["php", wrapper_path],
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                env=env
            )

            try:
                stdout, stderr = proc.communicate(timeout=35)
                output = stdout.decode(errors="replace")
                if stderr:
                    output += stderr.decode(errors="replace")
                return f"<pre>{output}</pre>" if output else ("", 200)
            except subprocess.TimeoutExpired:
                # Shell connected — let it hang
                proc.wait()
                return "", 200

        except FileNotFoundError:
            return "<pre>Error: php-cli is not installed on this server.</pre>", 500
        except Exception as e:
            return f"<pre>Error: {e}</pre>", 500
        finally:
            # Clean up wrapper file
            try:
                os.remove(wrapper_path)
            except Exception:
                pass

    return send_file(filepath)


@app.route("/admin")
@login_required
def admin_panel():
    if session.get("role") != "admin":
        abort(403)
    db    = get_db()
    users = db.execute("SELECT * FROM users").fetchall()
    return render_template("admin.html", users=users)

@app.route("/admin/notes")
@login_required
def admin_notes():
    if session.get("role") != "admin":
        abort(403)
    db         = get_db()
    all_notes  = db.execute(
        "SELECT notes.id, notes.title, notes.content, users.username "
        "FROM notes JOIN users ON notes.user_id = users.id"
    ).fetchall()
    return render_template("admin_notes.html", notes=all_notes)


@app.route("/admin/uploads")
@login_required
def admin_uploads():
    if session.get("role") != "admin":
        abort(403)
    try:
        files = os.listdir(UPLOAD_DIR)
    except Exception:
        files = []
    return render_template("admin_uploads.html", files=files)


@app.route("/admin/uploads/delete/<filename>", methods=["POST"])
@login_required
def admin_delete_upload(filename):
    if session.get("role") != "admin":
        abort(403)
    filepath = os.path.join(UPLOAD_DIR, filename)
    try:
        os.remove(filepath)
        message = f"✅ '{filename}' deleted successfully."
    except Exception as e:
        message = f"❌ Could not delete '{filename}': {e}"
    files = os.listdir(UPLOAD_DIR)
    return render_template("admin_uploads.html", files=files, message=message)


@app.route("/admin/logs")
@login_required
def admin_logs():
    if session.get("role") != "admin":
        abort(403)
    logs = ""
    try:
        with open(LOG_FILE, "r") as fh:
            logs = fh.read()
    except Exception:
        logs = "No logs found."
    return render_template("admin_logs.html", logs=logs)

@app.route("/backstage", methods=["GET"])
@login_required
def verb_tamper_get():
    abort(403)

@app.route("/backstage", methods=["POST"])
@login_required
def verb_tamper_post():
    token = request.form.get("token", "")
    if token == "PLUR4EVER":
        return "flag7{v3rb_t4mp3r_b4cks74g3_p4ss}", 200
    return "Invalid token.", 403

# ──────────────────────────────────────────────
# Profile (IDOR)
# ──────────────────────────────────────────────
@app.route("/profile/<int:user_id>")
@login_required
def profile(user_id):
    # ⚠️  IDOR — no check that user_id == session user
    db   = get_db()
    user = db.execute("SELECT * FROM users WHERE id=?", (user_id,)).fetchone()
    if not user:
        return "User not found", 404
    return render_template("profile.html", user=user)


# ──────────────────────────────────────────────
# Easter Egg
# ──────────────────────────────────────────────
@app.route("/ravers/love/small/easter/egg/sidequests")
def easter_egg():
    return render_template("easter_egg.html")

# ──────────────────────────────────────────────
# Entry Point
# ──────────────────────────────────────────────
# if __name__ == "__main__":
#     write_secret_files()
#     init_db()
#     print("""
#     ╔══════════════════════════════════════════════════╗
#     ║   🎵  RAVER'S PARADISE  — Vuln Lab Started  🎵   ║
#     ║   http://localhost:5000                          ║
#     ║   FOR EDUCATIONAL / CTF USE ONLY                ║
#     ╚══════════════════════════════════════════════════╝
#     """)
#     app.run(debug=True, host="0.0.0.0", port=5000)

write_secret_files()
init_db()
print("""
╔══════════════════════════════════════════════════╗
║   🎵  RAVER'S PARADISE  — Vuln Lab Started  🎵   ║
║   http://localhost:5000                          ║
║   FOR EDUCATIONAL / CTF USE ONLY                ║
╚══════════════════════════════════════════════════╝
""")
serve(app, host="0.0.0.0", port=5000)