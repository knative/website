{{/*

Use this shortcode to include the contents a file into the location from
where this shortcode is called. You can use %% (to send to markdown processor) or < >

Syntax:
    * For Markdown: Use %, {{%...%}} to send the file to the Markdown processor and enable in-page TOC.
      Example:
      * {{% readfile file="README.md" relative="true" %}}

    * For HTML: Use < >, {{<...>}} to copy in the HTML as is.
      Example:
      * {{< readfile file="HTML.html" relative="true" >}}

    * For code: Use < >, {{<...>}} See the code and lang parameters below for syntax highlighting.
      Example:
      * {{< readfile file="code-written-in.go" relative="true" code="true" lang="go" >}}

Parameters:
    * relative="true": Required if you specify a relative filepath in `file`. This is recommend for all content that is
      versioned so that nothing breaks if or when a folder moves or changes name.
    * file="filename.here": Required. Specifies either the relative filepath or the full filepath from the `baseURL` (basically start with /docs/):
      * Relative filepath: {{% readfile file="README.md" relative="true" %}}
      * Full filepath: {{% readfile file="/docs/anysubdirectories/README.md" %}}
    * code="true": Use to include a file and add syntax highlighting (the file is not processed, just copied as is).
      * lang="programming-language": The programming language syntax highlighting. List of supported values: https://gohugo.io/content-management/syntax-highlighting/#list-of-chroma-highlighting-languages

*/}}

{{/* Get the filepath */}}
{{ if eq (.Get "relative") "true" }}
  {{ $.Scratch.Set "filepath" $.Page.Dir }}
  {{ $.Scratch.Add "filepath" ( .Get "file" ) }}
{{ else }}
  {{ $.Scratch.Set "filepath" ( .Get "file" ) }}
{{ end }}

{{/* Check if the specified file exists */}}
{{ if fileExists ($.Scratch.Get "filepath") }}

  {{/*If Code, then highlight with the specified language. */}}
  {{ if eq (.Get "code") "true" }}
    {{ highlight ($.Scratch.Get "filepath" | readFile | safeHTML ) (.Get "lang") "" }}
  {{ else }}

    {{/* If HTML or Markdown. For Markdown, don't send content to processor again (use safeHTML). */}}
    {{ $.Scratch.Get "filepath" | readFile | safeHTML }}
  {{ end }}

{{/* Say something if the file is not found */}}
{{ else }}
  <p style="color: #D74848"><b><i>Something's not right. The <code>{{ .Get "file" }}</code> file was not found.</i></b></p>
{{ end }}
