# syntax=docker/dockerfile:1.20
FROM ghcr.io/ben-ranford/paperclip:latest

USER root

# Install pi CLI non-interactively
RUN npm install -g --ignore-scripts @earendil-works/pi-coding-agent

# Add a paperclip user with UID/GID 1000 if it doesn't exist already
RUN id -u paperclip >/dev/null 2>&1 || \
    (groupadd --gid 1000 paperclip && \
     useradd --uid 1000 --gid 1000 --home-dir /paperclip --no-create-home paperclip)

# The upstream entrypoint and CMD will run the Paperclip server
USER node
