systemctl daemon-reload \
&& systemctl enable manager-api.service \
&& chown -R nobody: /usr/local/apisix/dashboard/logs