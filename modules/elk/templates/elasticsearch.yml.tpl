cluster.name: ${cluster_name}
node.name: ${node_name}
network.host: 0.0.0.0
discovery.seed_hosts: ["elasticsearch-0.elasticsearch.${var.namespace_name}.svc.cluster.local"]
cluster.initial_master_nodes: ["elasticsearch-0"]
bootstrap.memory_lock: true
xpack.security.enabled: false
xpack.monitoring.collection.enabled: true
