package kubernetes.validating.securitycontext

violation[{"msg": msg}] {
    input.kind == "Pod"
    not input.spec.securityContext
    msg := "Pod must have securityContext defined"
}

violation[{"msg": msg}] {
    input.kind == "Pod"
    input.spec.securityContext.runAsNonRoot != true
    msg := "Pod must run as non-root user"
}

violation[{"msg": msg}] {
    input.kind == "Pod"
    not input.spec.securityContext.runAsUser
    msg := "Pod must specify runAsUser"
}

violation[{"msg": msg}] {
    input.kind == "Pod"
    not input.spec.securityContext.fsGroup
    msg := "Pod must specify fsGroup"
}

violation[{"msg": msg}] {
    input.kind == "Pod"
    container := input.spec.containers[_]
    not container.securityContext
    msg := sprintf("Container %s must have securityContext defined", [container.name])
}

violation[{"msg": msg}] {
    input.kind == "Pod"
    container := input.spec.containers[_]
    container.securityContext.allowPrivilegeEscalation != false
    msg := sprintf("Container %s must not allow privilege escalation", [container.name])
}

violation[{"msg": msg}] {
    input.kind == "Pod"
    container := input.spec.containers[_]
    container.securityContext.readOnlyRootFilesystem != true
    msg := sprintf("Container %s must have read-only root filesystem", [container.name])
}

violation[{"msg": msg}] {
    input.kind == "Pod"
    container := input.spec.containers[_]
    not container.securityContext.runAsNonRoot
    msg := sprintf("Container %s must run as non-root", [container.name])
}
