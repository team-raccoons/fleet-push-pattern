{{/* vim: set filetype=mustache: */}}

{{/*
Expand the name of the chart.
*/}}
{{- define "nginx-web.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "nginx-web.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "nginx-web.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "nginx-web.labels" -}}
helm.sh/chart: {{ include "nginx-web.chart" . }}
{{ include "nginx-web.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
raccoons: present
{{- end }}

{{/*
Selector labels
*/}}
{{- define "nginx-web.selectorLabels" -}}
app.kubernetes.io/name: {{ include "nginx-web.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{- define "nginx-web.tag" -}}
{{- default .Chart.AppVersion .Values.deploy.imageTag -}}
{{- end -}}

{{/*
Expand image name.
*/}}
{{- define "nginx-web.image" -}}
{{- if .Values.deploy.imageDigest -}}
{{- printf "%s@%s" .Values.deploy.imageRepo .Values.deploy.imageDigest -}}
{{- else -}}
{{- printf "%s:%s" .Values.deploy.imageRepo (include "nginx-web.tag" .) -}}
{{- end -}}
{{- end -}}