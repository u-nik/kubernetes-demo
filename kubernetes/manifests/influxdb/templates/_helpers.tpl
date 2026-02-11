{{- define "influxdb3.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "influxdb3.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s" $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{- define "influxdb3.labels" -}}
app.kubernetes.io/name: {{ include "influxdb3.name" . | quote }}
app.kubernetes.io/instance: {{ .Release.Name | quote }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service | quote }}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name (.Chart.Version | replace "+" "_") | quote }}
{{- end -}}

{{- define "influxdb3.selectorLabels" -}}
app.kubernetes.io/name: {{ include "influxdb3.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{- define "influxdb3.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
{{- default (include "influxdb3.fullname" .) .Values.serviceAccount.name -}}
{{- else -}}
{{- default "default" .Values.serviceAccount.name -}}
{{- end -}}
{{- end -}}

{{- define "influxdb3.namespace" -}}
{{- coalesce .Values.namespaceOverride (dig "namespaces" "influxdb" "" .Values.global) .Release.Namespace -}}
{{- end -}}
