package main

import (
  "fmt"
  "net/http"
  "strings"
)

func handler(w http.ResponseWriter, r *http.Request) {
  proc := sh("/usr/local/letsencrypt/letsencrypt.sh %s 2>&1", strings.Split(r.Header["Host"][0], ":")[0])
  fmt.Fprintln(w,proc.stdout)
}

func main() {
  http.HandleFunc("/.well-known/letsencrypt", handler)
  http.Handle("/", http.FileServer(http.Dir("/srv")))
  http.ListenAndServe(":8080", nil)
}
