{{ if eq (.Get "relative") "true" }}
  {{ $.Scratch.Set "filepath" $.Page.Dir }}
  {{ $.Scratch.Add "filepath" ( .Get "file" ) }}
{{ else }}
  {{ $.Scratch.Set "filepath" ( .Get "file" ) }}
{{ end }}
{{ if eq (.Get "markdown") "true" }}
  {{ $.Scratch.Get "filepath" | readFile | markdownify }}
{{ else }}
  {{ $.Scratch.Get "filepath" | readFile | safeHTML }}
{{ end }}
