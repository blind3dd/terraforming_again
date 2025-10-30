package main

# Deny privileged containers
deny[msg] {
    input.kind == "Pod"
    container := input.spec.containers[_]
    container.securityContext.privileged == true
    msg := sprintf("Container %s must not run in privileged mode", [container.name])
}

# Deny containers running as root
deny[msg] {
    input.kind == "Pod"
    container := input.spec.containers[_]
    container.securityContext.runAsUser == 0
    msg := sprintf("Container %s must not run as root user", [container.name])
}

# Require non-root security context
deny[msg] {
    input.kind == "Pod"
    not input.spec.securityContext.runAsNonRoot
    msg := "Pod must have runAsNonRoot=true in securityContext"
}

# Deny host network
deny[msg] {
    input.kind == "Pod"
    input.spec.hostNetwork == true
    msg := "Pod must not use host network"
}

# Deny host PID
deny[msg] {
    input.kind == "Pod"
    input.spec.hostPID == true
    msg := "Pod must not use host PID"
}

# Deny host IPC
deny[msg] {
    input.kind == "Pod"
    input.spec.hostIPC == true
    msg := "Pod must not use host IPC"
}

# Require resource limits
deny[msg] {
    input.kind == "Pod"
    container := input.spec.containers[_]
    not container.resources.limits
    msg := sprintf("Container %s must have resource limits", [container.name])
}

# Require resource requests
deny[msg] {
    input.kind == "Pod"
    container := input.spec.containers[_]
    not container.resources.requests
    msg := sprintf("Container %s must have resource requests", [container.name])
}

# Deny default namespace
deny[msg] {
    input.metadata.namespace == "default"
    msg := "Resources must not be created in default namespace"
}

# Require labels
deny[msg] {
    input.kind == "Pod"
    not input.metadata.labels.app
    msg := "Pod must have 'app' label"
}

deny[msg] {
    input.kind == "Pod"
    not input.metadata.labels.version
    msg := "Pod must have 'version' label"
}
