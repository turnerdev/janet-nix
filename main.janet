(defn resolve-bundle
  "Convert any bundle string/table to the normalized table form."
  [bundle]
  (var repo nil)
  (var tag nil)
  (var btype :git)
  (var shallow false)
  (if (dictionary? bundle)
    (do
      (set repo (or (get bundle :url) (get bundle :repo)))
      (set tag (or (get bundle :tag) (get bundle :sha) (get bundle :commit) (get bundle :ref)))
      (set btype (get bundle :type :git))
      (set shallow (get bundle :shallow false)))
    (let [parts (string/split "::" bundle)]
      (case (length parts)
        1 (set repo (get parts 0))
        2 (do (set repo (get parts 1)) (set btype (keyword (get parts 0))))
        3 (do
            (set btype (keyword (get parts 0)))
            (set repo (get parts 1))
            (set tag (get parts 2)))
        (errorf "unable to parse bundle string %v" bundle))))
  {:url repo :tag tag :type btype :shallow shallow})

(defn nix-source
  [{:url url :tag rev}]
  (string `  { url = "` url `"; rev = "` rev `"; submodules = true; }`))

(defn load-lockfile
  "Load packages from a lockfile."
  [&opt filename]
  (default filename "lockfile.jdn")
  (if (os/stat filename)
    (do
      (def lockarray (parse (slurp filename)))
      (print "[")
      (each bundle lockarray
	(print (nix-source (resolve-bundle bundle))))
      (print "]"))
    (file/write stderr "No lockfile.jdn found")))

(defn main
  [& args]
  (load-lockfile))
