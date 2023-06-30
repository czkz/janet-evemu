(defn new
  ``Start evemu-device. Returns a struct containing
  the process handle and device path.
  Use evemu-describe to get device-description.
  ``
  [device-description]
  (def p (os/spawn ["evemu-device" "/dev/stdin"] :p {:in :pipe :out :pipe}))
  (:write (p :in) device-description)
  (:close (p :in))
  (def buf (buffer/new 64))
  (while (not (string/has-suffix? "\n" buf))
    (assert (:read (p :out) 64 buf 1)))
  (def [name path]
    (peg/match '(* '(to ": ") ": " '(to "\n") "\n" -1) buf))
  {:process p
   :name name
   :path path
   :pending-events (array/new 4)})

