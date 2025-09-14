package kubernetes.validating.requirelabels

violation[{"msg": msg}] {
    not input.metadata.labels
    msg := "Labels are required"
}

violation[{"msg": msg}] {
    not input.metadata.labels.app
    msg := "Label 'app' is required"
}

violation[{"msg": msg}] {
    not input.metadata.labels.version
    msg := "Label 'version' is required"
}

violation[{"msg": msg}] {
    not input.metadata.labels.managed_by
    msg := "Label 'managed-by' is required"
}
