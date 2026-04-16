# sudobaron/Dockerfile
FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive
ENV PYENV_ROOT="/opt/pyenv"
ENV PATH="$PYENV_ROOT/bin:$PYENV_ROOT/shims:$PATH"
ENV EDITOR=/bin/nano

RUN apt-get update && apt-get install -y \
    gcc \
    wget \
    git \
    curl \
    build-essential \
    libssl-dev \
    zlib1g-dev \
    libffi-dev \
    libbz2-dev \
    libreadline-dev \
    libsqlite3-dev \
    php \
    php-cli \
    nano

RUN wget http://archive.ubuntu.com/ubuntu/pool/main/s/sudo/sudo_1.8.31-1ubuntu1_amd64.deb \
    && dpkg -i --force-all sudo_1.8.31-1ubuntu1_amd64.deb \
    && rm sudo_1.8.31-1ubuntu1_amd64.deb \
    && apt-mark hold sudo

RUN curl https://pyenv.run | bash \
    && pyenv install 3.13.0 \
    && pyenv global 3.13.0

RUN pyenv exec pip install waitress

RUN chmod -R 755 /opt/pyenv

RUN ln -s /opt/pyenv/shims/python3.13 /usr/local/bin/python3 \
    && ln -s /opt/pyenv/shims/python3.13 /usr/local/bin/python

RUN useradd -m griz \
    && echo "griz:password" | chpasswd \
    && chown -R griz:griz /home/griz \
    && chmod 755 /home/griz

RUN echo "griz ALL=(ALL) NOPASSWD: /usr/bin/sudoedit" >> /etc/sudoers

RUN mkdir /app && git clone https://github.com/rippy1849/raver-home-lab-penetration-testing /app

RUN rm -rf /app/app2
RUN rm -f /app/app1/write_flags.py

RUN pip install -r /app/app1/requirements.txt

# www-data readable/writable directories and files
RUN mkdir -p /app/app1/archive \
    && mkdir -p /app/app1/logs \
    && touch /app/app1/logs/app.log \
    && mkdir -p /app/app1/uploads \
    && chown -R www-data:www-data /app/app1/archive \
    && chown -R www-data:www-data /app/app1/logs \
    && chown -R www-data:www-data /app/app1/uploads \
    && chown www-data:www-data /app/app1/static/artists.txt \
    && chown -R www-data:www-data /app/app1/templates

# Move flags
RUN chmod -R 755 /app/app1/secret \
    && mkdir -p /secret /secret2 \
    && mv /app/app1/secret/flag4.txt /secret/flag4.txt \
    && mv /app/app1/secret/flag5.txt /secret2/flag5.txt \
    && mv /app/app1/secret/flag6.txt /home/griz/flag6.txt \
    && mv /app/app1/secret/flag16.txt /flag16.txt \
    && chown www-data:www-data /secret/flag4.txt \
    && chmod 644 /secret/flag4.txt \
    && chown www-data:www-data /secret2/flag5.txt \
    && chmod 644 /secret2/flag5.txt \
    && chown griz:griz /home/griz/flag6.txt \
    && chmod 600 /home/griz/flag6.txt \
    && chown root:root /flag16.txt \
    && chmod 400 /flag16.txt \
    && chown www-data:www-data /app/app1/secret/user_1_private.txt \
    && chmod 644 /app/app1/secret/user_1_private.txt

# Give www-data write access for sqlite db
RUN chown -R www-data:www-data /app/app1 \
    && chmod -R 755 /app/app1

# app.py only readable by root and www-data
RUN chown root:www-data /app/app1/app.py \
    && chmod 640 /app/app1/app.py

# /etc/shadow readable by www-data
RUN chmod 640 /etc/shadow \
    && chown root:www-data /etc/shadow

WORKDIR /app/app1

EXPOSE 5000

CMD ["su", "-s", "/bin/bash", "www-data", "-c", "/opt/pyenv/shims/python -m waitress --host=0.0.0.0 --port=5000 --threads=8 app:app"]