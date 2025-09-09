input {
  beats {
    port => 5044
  }
}

filter {
  if [fields][service] == "nginx" {
    grok {
      match => { "message" => "%{COMBINEDAPACHELOG}" }
    }
  }
}

output {
  elasticsearch {
    hosts => ["${elasticsearch_host}"]
    index => "logstash-%{+YYYY.MM.dd}"
  }
}
