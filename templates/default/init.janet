(import spork/http)

(defn main
  [& args]
  (def response (http/request "GET" "http://www.example.com"))
  (def body (http/read-body response))
  (print body))
