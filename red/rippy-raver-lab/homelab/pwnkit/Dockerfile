# pwnkit/Dockerfile
FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive
ENV PYENV_ROOT="/opt/pyenv"
ENV PATH="$PYENV_ROOT/bin:$PYENV_ROOT/shims:$PATH"
ENV SE_DRIVER_LOCATION=/usr/bin/chromedriver
ENV SE_MANAGER_ENABLED=false

RUN apt-get update && apt-get install -y \
    sudo \
    gcc \
    wget \
    git \
    curl \
    unzip \
    build-essential \
    libssl-dev \
    zlib1g-dev \
    libffi-dev \
    libbz2-dev \
    libreadline-dev \
    libsqlite3-dev \
    libnss3 \
    libatk1.0-0 \
    libatk-bridge2.0-0 \
    libcups2 \
    libdrm2 \
    libxkbcommon0 \
    libxcomposite1 \
    libxdamage1 \
    libxfixes3 \
    libxrandr2 \
    libgbm1 \
    libasound2 \
    libpango-1.0-0 \
    libcairo2 \
    php \
    php-cli \
    software-properties-common \
    dbus \
    dbus-x11 \
    nano \
    system-config-printer

RUN wget http://archive.ubuntu.com/ubuntu/pool/main/p/policykit-1/policykit-1_0.105-26ubuntu1_amd64.deb \
    && wget http://archive.ubuntu.com/ubuntu/pool/main/p/policykit-1/libpolkit-agent-1-0_0.105-26ubuntu1_amd64.deb \
    && wget http://archive.ubuntu.com/ubuntu/pool/main/p/policykit-1/libpolkit-gobject-1-0_0.105-26ubuntu1_amd64.deb \
    && wget http://archive.ubuntu.com/ubuntu/pool/main/p/policykit-1/gir1.2-polkit-1.0_0.105-26ubuntu1_amd64.deb \
    && dpkg -i libpolkit-gobject-1-0_0.105-26ubuntu1_amd64.deb \
    && dpkg -i libpolkit-agent-1-0_0.105-26ubuntu1_amd64.deb \
    && dpkg -i gir1.2-polkit-1.0_0.105-26ubuntu1_amd64.deb \
    && dpkg -i policykit-1_0.105-26ubuntu1_amd64.deb \
    && rm *.deb \
    && apt-mark hold policykit-1 libpolkit-agent-1-0 libpolkit-gobject-1-0 gir1.2-polkit-1.0

RUN apt-get install -y accountsservice

RUN apt-get install -y --no-install-recommends gnome-control-center

RUN mkdir -p /var/run/dbus

RUN wget https://mirror.cs.uchicago.edu/google-chrome/pool/main/g/google-chrome-stable/google-chrome-stable_114.0.5735.90-1_amd64.deb \
    && apt-get install -y ./google-chrome-stable_114.0.5735.90-1_amd64.deb \
    && rm google-chrome-stable_114.0.5735.90-1_amd64.deb \
    && wget https://chromedriver.storage.googleapis.com/114.0.5735.90/chromedriver_linux64.zip \
    && unzip chromedriver_linux64.zip \
    && mv chromedriver /usr/bin/chromedriver \
    && rm chromedriver_linux64.zip

RUN curl https://pyenv.run | bash \
    && pyenv install 3.13.0 \
    && pyenv global 3.13.0

RUN pyenv exec pip install waitress

RUN chmod -R 755 /opt/pyenv

RUN ln -s /opt/pyenv/shims/python3.13 /usr/local/bin/python3 \
    && ln -s /opt/pyenv/shims/python3.13 /usr/local/bin/python

RUN useradd -m griz \
    && echo "griz:passwordispassword" | chpasswd

RUN mkdir /app && git clone https://github.com/rippy1849/raver-home-lab-penetration-testing /app

RUN rm -rf /app/app1
RUN rm -f /app/app2/write_flags.py

RUN pip install -r /app/app2/requirements.txt

# www-data readable directories and files
RUN chown -R www-data:www-data /app/app2/templates \
    && chmod -R 755 /app/app2/templates

# www-data needs to write the sqlite db in the app2 directory
RUN chown -R www-data:www-data /app/app2 \
    && chmod -R 755 /app/app2

# app.py only readable by root and www-data
RUN chown root:www-data /app/app2/app.py \
    && chmod 640 /app/app2/app.py

# Move flags
RUN mkdir -p /secret \
    && mv /app/app2/flag12.txt /secret/flag12.txt \
    && mv /app/app2/flag15.txt /flag15.txt \
    && chown www-data:www-data /secret/flag12.txt \
    && chmod 644 /secret/flag12.txt \
    && chown root:root /flag15.txt \
    && chmod 400 /flag15.txt

# Selenium cache
RUN mkdir -p /var/www/.cache/selenium \
    && chown -R www-data:www-data /var/www/.cache

# /etc/shadow readable by www-data
RUN chmod 640 /etc/shadow \
    && chown root:www-data /etc/shadow

RUN printf '#!/bin/bash\ndbus-daemon --system --fork\n/opt/pyenv/shims/python /app/app2/bot.py &\nsu -s /bin/bash www-data -c "/opt/pyenv/shims/python -m waitress --host=0.0.0.0 --port=5000 --threads=8 app:app"\n' > /start.sh \
    && chmod +x /start.sh

WORKDIR /app/app2

EXPOSE 5000

CMD ["/bin/bash", "/start.sh"]