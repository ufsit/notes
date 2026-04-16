#!/usr/bin/env python3
"""
∿∿∿ BASS DROP CTF ∿∿∿
Deliberately vulnerable Flask app — educational use only.
Vulnerabilities: Stored XSS, CSRF, RFI, JWT None Algorithm, SSRF
"""

from flask import (
    Flask, request, session, redirect,
    url_for, render_template, make_response, jsonify
)
from markupsafe import Markup
import sqlite3, hashlib, jwt, requests, threading, time
from functools import wraps
from http.server import HTTPServer, BaseHTTPRequestHandler
import os

app = Flask(__name__)
app.secret_key = "plur_vibes_only_2024"

app.config.update(
    SESSION_COOKIE_SAMESITE="Lax",
    SESSION_COOKIE_SECURE=False,
    SESSION_COOKIE_HTTPONLY=True,
)

FLAG_10 = "flag10{y0ur_c00k13_g0t_st0l3n_in_the_moshpit}"
FLAG_11 = "flag11{csrf_dr0pp3d_l1k3_the_b4ss}"
FLAG_13 = "flag13{jwt_n0n3_alg0_b4ckst4g3_p4ss}"
FLAG_14 = "flag14{ssrf_h1t_the_1nt3rn4l_d3cks}"

# ------------------------------------------------------------------ #
#  Database
# ------------------------------------------------------------------ #
def get_db():
    db = sqlite3.connect("bassdrop.db")
    db.row_factory = sqlite3.Row
    return db

def init_db():
    db = get_db()
    db.executescript(f"""
        CREATE TABLE IF NOT EXISTS users (
            id       INTEGER PRIMARY KEY AUTOINCREMENT,
            username TEXT UNIQUE NOT NULL,
            password TEXT NOT NULL,
            is_admin INTEGER DEFAULT 0,
            flag     TEXT DEFAULT ''
        );
        CREATE TABLE IF NOT EXISTS comments (
            id     INTEGER PRIMARY KEY AUTOINCREMENT,
            author TEXT NOT NULL,
            body   TEXT NOT NULL
        );
        CREATE TABLE IF NOT EXISTS messages (
            id     INTEGER PRIMARY KEY AUTOINCREMENT,
            author TEXT NOT NULL,
            body   TEXT NOT NULL
        );

        INSERT OR IGNORE INTO users (username, password, is_admin, flag) VALUES
            ('griz',       '{hashlib.md5(b"funkysax123").hexdigest()}',  0, '{FLAG_10}'),
            ('rezz',       '{hashlib.md5(b"hypnotize!").hexdigest()}',   0, ''),
            ('lsdream',    '{hashlib.md5(b"cosmicluv99").hexdigest()}',  0, ''),
            ('subtronics', '{hashlib.md5(b"cyclopswub1").hexdigest()}',  0, '{FLAG_13}'),
            ('admin',      '{hashlib.md5(b"s3cr3t_4dm1n!").hexdigest()}',1, '');
    """)
    db.commit()
    db.close()

# ------------------------------------------------------------------ #
#  Helpers
# ------------------------------------------------------------------ #
AVATAR_COLORS = [
    ("rgba(255,51,102,.25)",  "#ff3366"),
    ("rgba(255,107,0,.25)",   "#ff6b00"),
    ("rgba(0,229,255,.2)",    "#00e5ff"),
    ("rgba(0,255,136,.2)",    "#00ff88"),
    ("rgba(170,0,255,.25)",   "#aa00ff"),
    ("rgba(61,90,254,.25)",   "#3d5afe"),
]

def avatar_style(name):
    idx = sum(ord(c) for c in name) % len(AVATAR_COLORS)
    bg, fg = AVATAR_COLORS[idx]
    return Markup(f"background:{bg};color:{fg};border:1px solid {fg}40")

def login_required(f):
    @wraps(f)
    def decorated(*args, **kwargs):
        if "username" not in session:
            return redirect(url_for("login"))
        return f(*args, **kwargs)
    return decorated

# ------------------------------------------------------------------ #
#  Internal admin panel — SSRF target on :7777
# ------------------------------------------------------------------ #
class InternalHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.send_header("Content-Type", "text/html")
        self.end_headers()
        self.wfile.write(
            f"<html><body style='font-family:monospace;background:#000;color:#0f0;padding:20px'>"
            f"<h1>INTERNAL ADMIN PANEL</h1><p>{FLAG_14}</p></body></html>".encode()
        )
    def log_message(self, *a):
        pass

def run_internal_server():
    HTTPServer(("127.0.0.1", 7777), InternalHandler).serve_forever()

# ------------------------------------------------------------------ #
#  Routes — Home
# ------------------------------------------------------------------ #
@app.route("/")
def index():
    db = get_db()
    rows = db.execute("SELECT * FROM comments ORDER BY id DESC LIMIT 3").fetchall()
    db.close()

    waveform = [
        {"h": h, "delay": round(i * 0.08, 2), "c1": c1, "c2": c2}
        for i, (h, c1, c2) in enumerate([
            (28,"#3d5afe","#aa00ff"),(18,"#aa00ff","#ff3366"),(34,"#00e5ff","#3d5afe"),
            (22,"#00ff88","#00e5ff"),(38,"#ffe600","#00ff88"),(14,"#ff6b00","#ffe600"),
            (30,"#ff3366","#ff6b00"),(24,"#aa00ff","#ff3366"),(36,"#00e5ff","#aa00ff"),
            (16,"#3d5afe","#00e5ff"),(32,"#00ff88","#3d5afe"),(20,"#ffe600","#00ff88"),
            (38,"#ff3366","#ffe600"),(26,"#ff6b00","#ff3366"),(18,"#aa00ff","#ff6b00"),
            (34,"#00e5ff","#aa00ff"),(28,"#3d5afe","#00e5ff"),(22,"#ff3366","#3d5afe"),
        ])
    ]

    recent_posts = [
        {
            "author":   r["author"],
            "body":     r["body"],
            "av_style": avatar_style(r["author"]),
            "initial":  r["author"][0].upper(),
        }
        for r in rows
    ]

    trending = [
        ("GRiZ",       Markup("#ff3366")),
        ("Rezz",       Markup("#aa00ff")),
        ("LSDREAM",    Markup("#00e5ff")),
        ("Subtronics", Markup("#00ff88")),
        ("Excision",   Markup("#ff6b00")),
    ]

    upcoming = [
        ("GRiZ",             Markup("#ffe600"), "Live Set — Friday"),
        ("Rezz B2B LSDREAM", Markup("#aa00ff"), "Sat"),
        ("Subtronics",       Markup("#00e5ff"), "Closer — Sun"),
    ]

    flag11 = FLAG_11 if session.get("username") == "griz" else None

    return render_template(
        "index.html",
        active="home",
        waveform=waveform,
        recent_posts=recent_posts,
        trending=trending,
        upcoming=upcoming,
        flag11=flag11,
    )

# ------------------------------------------------------------------ #
#  Routes — Auth
# ------------------------------------------------------------------ #
@app.route("/login", methods=["GET", "POST"])
def login():
    error = ""
    if request.method == "POST":
        u = request.form.get("username", "")
        p = hashlib.md5(request.form.get("password", "").encode()).hexdigest()
        db = get_db()
        user = db.execute(
            "SELECT * FROM users WHERE username=? AND password=?", (u, p)
        ).fetchone()
        db.close()
        if user:
            session["username"] = user["username"]
            session["is_admin"] = bool(user["is_admin"])
            resp = make_response(redirect(url_for("index")))
            if user["username"] == "griz":
                resp.set_cookie(
                    "flag10",
                    FLAG_10,
                    httponly=False,
                    samesite="Lax",
                    secure=False,
                )
            return resp
        error = "Invalid username or password."
    return render_template("login.html", active="", error=error)

@app.route("/logout")
def logout():
    session.clear()
    resp = make_response(redirect(url_for("index")))
    resp.delete_cookie("session")
    resp.delete_cookie("flag10")
    return resp

# ------------------------------------------------------------------ #
#  Routes — Artists
# ------------------------------------------------------------------ #
ARTIST_META = {
    "griz":       ("Grand Rapids, MI",  "Saxophone-forward future funk and soul"),
    "rezz":       ("Niagara Falls, ON", "Self-described 'space mom' of hypnotic bass"),
    "lsdream":    ("Los Angeles, CA",   "Cosmic bass music from another dimension"),
    "subtronics": ("Philadelphia, PA",  "Cyclops king of riddim and experimental bass"),
}

@app.route("/artists")
@login_required
def artists():
    db = get_db()
    users = db.execute("SELECT username, is_admin FROM users").fetchall()
    db.close()
    artist_list = [
        {
            "username": u["username"],
            "city":     ARTIST_META.get(u["username"], ("Unknown", ""))[0],
            "bio":      ARTIST_META.get(u["username"], ("", "Electronic music artist"))[1],
            "av_style": avatar_style(u["username"]),
            "initial":  u["username"][0].upper(),
        }
        for u in users if not u["is_admin"]
    ]
    return render_template("artists.html", active="artists", artists=artist_list)

# ------------------------------------------------------------------ #
#  Routes — Forum  (Stored XSS — FLAG 10 + CSRF vector — FLAG 11)
# ------------------------------------------------------------------ #
@app.route("/forum", methods=["GET", "POST"])
@login_required
def forum():
    db = get_db()
    msg = ""
    if request.method == "POST":
        body = request.form.get("body", "")
        db.execute(
            "INSERT INTO comments (author, body) VALUES (?, ?)",
            (session["username"], body)
        )
        db.commit()
        msg = "Your post has been published."

    rows = db.execute("SELECT * FROM comments ORDER BY id DESC").fetchall()
    db.close()

    posts = [
        {
            "author":   r["author"],
            "body":     r["body"],
            "av_style": avatar_style(r["author"]),
            "initial":  r["author"][0].upper(),
        }
        for r in rows
    ]
    return render_template("forum.html", active="forum", msg=msg, posts=posts)

# ------------------------------------------------------------------ #
#  Routes — Messages  (Stored XSS + CSRF vector — FLAG 11)
# ------------------------------------------------------------------ #
@app.route("/messages", methods=["GET", "POST"])
@login_required
def messages():
    db = get_db()
    msg = ""
    if request.method == "POST":
        body = request.form.get("body", "")
        db.execute(
            "INSERT INTO messages (author, body) VALUES (?, ?)",
            (session["username"], body)
        )
        db.commit()
        msg = "Message sent."

    rows = db.execute("SELECT * FROM messages ORDER BY id DESC").fetchall()
    db.close()

    msgs = [
        {
            "author":   r["author"],
            "body":     r["body"],
            "av_style": avatar_style(r["author"]),
            "initial":  r["author"][0].upper(),
        }
        for r in rows
    ]
    return render_template("messages.html", active="messages", msg=msg, messages=msgs)

# ------------------------------------------------------------------ #
#  Routes — Settings  (CSRF-vulnerable password change — FLAG 11)
# ------------------------------------------------------------------ #
@app.route("/settings", methods=["GET", "POST"])
def settings():
    if "username" not in session and request.method == "GET":
        return redirect(url_for("login"))

    msg     = ""
    success = False

    if request.method == "POST" and "username" in session:
        new_password = request.form.get("new_password", "")
        if new_password:
            hashed = hashlib.md5(new_password.encode()).hexdigest()
            db = get_db()
            # No CSRF token — intentional vuln
            db.execute(
                "UPDATE users SET password=? WHERE username=?",
                (hashed, session["username"])
            )
            db.commit()
            db.close()
            msg     = "Password updated successfully."
            success = True
        else:
            msg = "Please enter a new password."

    return render_template(
        "settings.html", active="",
        msg=msg, success=success,
        username=session.get("username", ""),
    )

# ------------------------------------------------------------------ #
#  Routes — Profile  (FLAG 11 reveal post-CSRF)
# ------------------------------------------------------------------ #
@app.route("/profile")
@login_required
def profile():
    db = get_db()
    user = db.execute(
        "SELECT * FROM users WHERE username=?", (session["username"],)
    ).fetchone()
    db.close()

    flag11 = FLAG_11 if session["username"] == "griz" else None

    return render_template(
        "profile.html", active="",
        flag11=flag11,
        username=user["username"],
        is_admin=bool(user["is_admin"]),
        av_style=avatar_style(user["username"]),
        initial=user["username"][0].upper(),
    )

# ------------------------------------------------------------------ #
#  Routes — Visuals default content
# ------------------------------------------------------------------ #
@app.route("/visuals/default")
def visuals_default():
    html = """
    <!DOCTYPE html>
    <html>
    <head>
    <style>
      * { margin: 0; padding: 0; box-sizing: border-box; }
      body { background: #0d0d0d; overflow: hidden; }
      canvas { display: block; }
    </style>
    </head>
    <body>
    <canvas id='c'></canvas>
    <script>
      const c  = document.getElementById('c');
      const cx = c.getContext('2d');
      c.width  = 600;
      c.height = 300;

      const COLORS = ['#ff3366','#ff6b00','#ffe600','#00ff88','#00e5ff','#3d5afe','#aa00ff'];
      const bars   = Array.from({length: 48}, (_, i) => ({
        x:     (c.width / 48) * i,
        h:     Math.random() * c.height * 0.5 + 10,
        speed: Math.random() * 2 + 1,
        color: COLORS[i % COLORS.length],
        dir:   1,
      }));

      function draw() {
        cx.fillStyle = 'rgba(13,13,13,0.25)';
        cx.fillRect(0, 0, c.width, c.height);
        const bw = c.width / bars.length;
        bars.forEach(b => {
          b.h += b.speed * b.dir;
          if (b.h > c.height * 0.85 || b.h < 10) b.dir *= -1;
          cx.fillStyle = b.color;
          cx.fillRect(b.x, c.height - b.h, bw - 2, b.h);
        });
        requestAnimationFrame(draw);
      }
      draw();
    </script>
    </body>
    </html>
    """
    return html, 200, {"Content-Type": "text/html"}

# ------------------------------------------------------------------ #
#  Routes — Visuals  (RFI + SSRF — FLAG 12 + FLAG 14)
# ------------------------------------------------------------------ #
@app.route("/visuals")
@login_required
def visuals():
    default_url = "http://127.0.0.1:5000/visuals/default"

    if "url" not in request.args:
        return redirect(url_for("visuals", url=default_url))

    url_val = request.args.get("url")
    result  = ""

    try:
        resp    = requests.get(url_val, timeout=5)
        fetched = resp.text

        if "exec:" in fetched:
            # Custom exec tag shell
            import subprocess
            code = fetched.split("exec:")[1].split(":end")[0].strip()
            out  = subprocess.check_output(
                code, shell=True, stderr=subprocess.STDOUT, timeout=5
            ).decode()
            result = Markup(f"<pre>{out}</pre>")

        elif "<?php" in fetched:
            # Write to a temp file and execute with PHP CLI
            import subprocess, tempfile, os
            with tempfile.NamedTemporaryFile(
                mode="w", suffix=".php", delete=False
            ) as tmp:
                tmp.write(fetched)
                tmp_path = tmp.name
            try:
                out = subprocess.check_output(
                    ["php", tmp_path],
                    stderr=subprocess.STDOUT,
                    timeout=10
                ).decode()
                result = Markup(f"<pre>{out}</pre>")
            except subprocess.TimeoutExpired:
                # Reverse shell connections won't return output — that's expected
                result = Markup(
                    "<div class='alert alert-info'>Well that's not good. What are you going to do with a reverse shell?</div>"
                )
            except FileNotFoundError:
                result = Markup(
                    "<div class='alert alert-error'>PHP CLI not found on server.</div>"
                )
            finally:
                os.unlink(tmp_path)

        else:
            result = Markup(
                f"<pre style='white-space:pre-wrap;word-break:break-all'>"
                f"{fetched[:4000]}</pre>"
            )

    except Exception as e:
        result = Markup(f"<div class='alert alert-error'>Error loading source: {e}</div>")

    return render_template(
        "visuals.html", active="visuals",
        url_val=url_val,
        result=result,
    )


# ------------------------------------------------------------------ #
#  Routes — Backstage  (JWT None Algorithm — FLAG 13)
# ------------------------------------------------------------------ #
@app.route("/backstage", methods=["GET", "POST"])
def backstage():
    # Accept token from Authorization header or form POST
    raw_token = None

    if request.method == "POST":
        raw_token = request.form.get("token", "")
    else:
        auth = request.headers.get("Authorization", "")
        if auth.startswith("Bearer "):
            raw_token = auth.split("Bearer ", 1)[1].strip()

    if not raw_token:
        return render_template("backstage.html", active="backstage",
                               msg="", flag=None, claimed_user="")

    try:
        # Intentionally vulnerable — accepts alg:none
        decoded = jwt.decode(
            raw_token,
            options={"verify_signature": False},
            algorithms=["HS256", "none"],
        )
        claimed_user = decoded.get("username", "")
        db   = get_db()
        user = db.execute(
            "SELECT * FROM users WHERE username=?", (claimed_user,)
        ).fetchone()
        db.close()
        if user and user["flag"]:
            return render_template("backstage.html", active="backstage",
                                   msg="", flag=user["flag"],
                                   claimed_user=claimed_user)
        elif user:
            return render_template("backstage.html", active="backstage",
                                   msg=f"Verified as {claimed_user}, but no flag here.",
                                   flag=None, claimed_user=claimed_user)
        else:
            return render_template("backstage.html", active="backstage",
                                   msg="Token rejected — unknown identity.",
                                   flag=None, claimed_user="")
    except Exception as e:
        return render_template("backstage.html", active="backstage",
                               msg=f"Token error: {e}",
                               flag=None, claimed_user="")


@app.route("/token")
@login_required
def backstage_token():
    token = jwt.encode(
        {"username": session["username"], "is_admin": session.get("is_admin", False)},
        "super_secret_key_dont_share",
        algorithm="HS256",
    )
    return render_template("token.html", active="", token=token)

@app.errorhandler(404)
def not_found(e):
    return render_template("404.html", active=""), 404

# ------------------------------------------------------------------ #
#  Bot simulation — Selenium so JS actually executes
# ------------------------------------------------------------------ #
def bot_visits():
    from selenium import webdriver
    from selenium.webdriver.common.by import By
    from selenium.webdriver.chrome.options import Options
    from selenium.webdriver.support.ui import WebDriverWait
    from selenium.webdriver.support import expected_conditions as EC

    time.sleep(5)

    base = "http://127.0.0.1:5000"

    while True:
        driver = None
        try:
            opts = Options()
            opts.add_argument("--headless")
            opts.add_argument("--no-sandbox")
            opts.add_argument("--disable-dev-shm-usage")
            opts.add_argument("--ignore-certificate-errors")
            opts.set_capability("goog:loggingPrefs", {"browser": "ALL"})

            driver = webdriver.Chrome(options=opts)
            wait   = WebDriverWait(driver, 10)

            # Log in as griz via JavaScript — avoids click interception
            driver.get(f"{base}/login")
            wait.until(EC.presence_of_element_located((By.NAME, "username")))
            driver.execute_script("""
                document.querySelector('[name=username]').value = 'griz';
                document.querySelector('[name=password]').value = 'funkysax123';
                document.querySelector('form').submit();
            """)
            wait.until(EC.url_changes(f"{base}/login"))
            time.sleep(2)

            # Visit forum — triggers XSS cookie steal and CSRF payload if present
            driver.get(f"{base}/forum")
            time.sleep(5)

            for entry in driver.get_log("browser"):
                print(f"[bot:forum] {entry}", flush=True)

            # Visit messages — triggers XSS + CSRF payload if present
            driver.get(f"{base}/messages")
            time.sleep(5)

            for entry in driver.get_log("browser"):
                print(f"[bot:messages] {entry}", flush=True)

        except Exception as e:
            print(f"[bot] error: {e}", flush=True)
        finally:
            if driver:
                driver.quit()

        time.sleep(30)

# ------------------------------------------------------------------ #
#  Main
# ------------------------------------------------------------------ #
# runs regardless of whether started via python or gunicorn
# runs regardless of whether started via python or waitress


# init_db()
# write_flag12()
# threading.Thread(target=run_internal_server, daemon=True).start()

# if __name__ == "__main__":
#     from waitress import serve
#     print("\n  DropZone CTF — http://0.0.0.0:5000\n")
#     serve(app, host="0.0.0.0", port=5000, threads=8)

# Runs at module level — works with both waitress and direct python
init_db()
threading.Thread(target=run_internal_server, daemon=True).start()

if __name__ == "__main__":
    from waitress import serve
    print("\n  DropZone CTF — http://0.0.0.0:5000\n")
    serve(app, host="0.0.0.0", port=5000, threads=8)