# Rundeck for Railway: the official image, pinned by version and digest,
# plus a small start script (secure admin login, Postgres, volume permissions).
FROM rundeck/rundeck:6.3.0@sha256:9b0477556ec3476afab498708b996cbd3373e87b3b3a1447790dadead21db521

USER root
COPY --chmod=0755 start.sh /usr/local/bin/railway-start.sh

EXPOSE 4440
# The start script runs as root only to fix volume ownership and write the
# login file, then drops to the rundeck user and runs the image's own entrypoint.
ENTRYPOINT ["/tini", "--", "/usr/local/bin/railway-start.sh"]
