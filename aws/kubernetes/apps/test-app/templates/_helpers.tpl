{{- define "test-app.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "test-app.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- include "test-app.name" . -}}
{{- end -}}
{{- end -}}

{{- define "test-app.frontendFullname" -}}
{{- printf "%s-frontend" (include "test-app.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "test-app.backendFullname" -}}
{{- printf "%s-backend" (include "test-app.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "test-app.labels" -}}
app.kubernetes.io/name: {{ include "test-app.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" }}
{{- end -}}

{{- define "test-app.selectorLabels" -}}
app.kubernetes.io/name: {{ include "test-app.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{- define "test-app.frontendSelectorLabels" -}}
{{ include "test-app.selectorLabels" . }}
app.kubernetes.io/component: frontend
{{- end -}}

{{- define "test-app.backendSelectorLabels" -}}
{{ include "test-app.selectorLabels" . }}
app.kubernetes.io/component: backend
{{- end -}}

{{- define "test-app.frontendLabels" -}}
{{ include "test-app.labels" . }}
app.kubernetes.io/component: frontend
{{- end -}}

{{- define "test-app.backendLabels" -}}
{{ include "test-app.labels" . }}
app.kubernetes.io/component: backend
{{- end -}}

{{- define "test-app.gatewayNamespace" -}}
{{- default .Release.Namespace .Values.istio.gateway.namespace -}}
{{- end -}}

{{- define "test-app.createdGatewayRef" -}}
{{- if eq (include "test-app.gatewayNamespace" .) .Release.Namespace -}}
{{- .Values.istio.gateway.name -}}
{{- else -}}
{{- printf "%s/%s" (include "test-app.gatewayNamespace" .) .Values.istio.gateway.name -}}
{{- end -}}
{{- end -}}
