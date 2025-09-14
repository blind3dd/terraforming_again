package kubernetes.validating.resourcelimits

violation[{"msg": msg}] {
    input.kind == "Pod"
    container := input.spec.containers[_]
    not container.resources
    msg := sprintf("Container %s must have resource limits defined", [container.name])
}

violation[{"msg": msg}] {
    input.kind == "Pod"
    container := input.spec.containers[_]
    not container.resources.limits
    msg := sprintf("Container %s must have resource limits", [container.name])
}

violation[{"msg": msg}] {
    input.kind == "Pod"
    container := input.spec.containers[_]
    not container.resources.limits.cpu
    msg := sprintf("Container %s must have CPU limit", [container.name])
}

violation[{"msg": msg}] {
    input.kind == "Pod"
    container := input.spec.containers[_]
    not container.resources.limits.memory
    msg := sprintf("Container %s must have memory limit", [container.name])
}

violation[{"msg": msg}] {
    input.kind == "Pod"
    container := input.spec.containers[_]
    not container.resources.requests
    msg := sprintf("Container %s must have resource requests", [container.name])
}

violation[{"msg": msg}] {
    input.kind == "Pod"
    container := input.spec.containers[_]
    not container.resources.requests.cpu
    msg := sprintf("Container %s must have CPU request", [container.name])
}

violation[{"msg": msg}] {
    input.kind == "Pod"
    container := input.spec.containers[_]
    not container.resources.requests.memory
    msg := sprintf("Container %s must have memory request", [container.name])
}
