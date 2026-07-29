global:
  scrape_interval: 15s
  scrape_timeout: 10s
  evaluation_interval: 15s

alerting:
  alertmanagers:
    - static_configs:
        - targets: []

rule_files: []

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'nextcloud-node-exporter'
    static_configs:
      - targets: ['${nextcloud_ip}:9100']
    scrape_interval: 30s
    scrape_timeout: 10s
