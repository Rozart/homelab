FROM python:3.12-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    ffmpeg cron inotify-tools git && \
    rm -rf /var/lib/apt/lists/* && \
    pip install --no-cache-dir git+https://github.com/Googolplexed0/zotify.git

COPY download.sh /usr/local/bin/download.sh
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/download.sh /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
