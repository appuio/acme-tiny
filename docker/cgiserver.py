import os
import BaseHTTPServer, CGIHTTPServer

os.chdir("/srv")

CGIHTTPServer.CGIHTTPRequestHandler.cgi_directories = ['./well-known/cgi-bin']

serv = BaseHTTPServer.HTTPServer(("", 8080), CGIHTTPServer.CGIHTTPRequestHandler)

serv.serve_forever()
