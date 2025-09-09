filebeat.inputs:
- type: log
  enabled: true
  paths:
    - /var/log/*.log
    - /var/log/containers/*.log

output.logstash:
  hosts: ["${logstash_host}"]

processors:
  - add_host_metadata:
      when.not.contains.tags: forwarded
