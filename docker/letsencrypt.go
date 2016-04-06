package main

import (
  "fmt"
  "net/http"
)

func handler(w http.ResponseWriter, r *http.Request) {
  fmt.Fprintf(w, sh("ls -l /tmp").stdout)
//  fmt.Fprintf(w, "Hi there, I love %s!\n", r.URL.Path[1:])
}

func main() {
  http.HandleFunc("/.well-known/letsencrypt", handler)
  http.Handle("/", http.FileServer(http.Dir("./tmp")))
  http.ListenAndServe(":8080", nil)
}
