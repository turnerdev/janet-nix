(declare-project
  :name "my-new-program"
  :description ```A simple Janet program```
  :version "0.0.0"
  :dependencies ["spork"])

(declare-executable
  :name "my-new-program"
  :entry "init.janet"
  :install true)
