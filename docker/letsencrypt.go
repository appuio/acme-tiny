package main

import (
  "fmt"
  "net/http"
  "strings"
)

func handler(w http.ResponseWriter, r *http.Request) {
  fmt.Fprintln(w, sh("/usr/local/letsencrypt/letsencrypt.sh %s", strings.Split(r.Host, ":")[0]).stdout)
}

func main() {
  http.HandleFunc("/.well-known/letsencrypt", handler)
  http.Handle("/", http.FileServer(http.Dir("/srv")))
  http.ListenAndServe(":8080", nil)
}
