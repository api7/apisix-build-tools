systemctl daemon-reload \
&& systemctl enable apisix-dashboard.service \
&& chown -R nobody: /usr/local/apisix/dashboard/logs
