{{/* Use this to insert the docs version number. Get the directory path. */}}
{{- $pageSection := .Page.Section -}}
{{/* Set default version to latest release */}}
{{- $.Scratch.Set "release-version" .Site.Params.version -}}
{{/* Use the specified version override (not directory based) */}}
{{- if (.Get "override") -}}
{{- $.Scratch.Set "release-version" (.Get "override") -}}
{{- else -}}
{{/* Keep using the latest version for the "pre-release" content */}}
{{- if ne $pageSection "development" -}}
{{/* Use version based on the directory path (see .dirpath in config/_default/params.toml) */}}
{{- range .Site.Params.versions -}}
{{- if eq $pageSection .dirpath -}}
{{- $.Scratch.Set "release-version" .version -}}
{{- end -}}
{{- end -}}
{{- end -}}
{{/* If a patch value is specified then append that, otherwise use '.0' */}}
{{- if (.Get "patch") -}}
{{- $.Scratch.Add "release-version" (.Get "patch") -}}
{{- else -}}
{{- $.Scratch.Add "release-version" ".0" -}}
{{- end -}}
{{- end -}}
{{- $.Scratch.Get "release-version" -}}
