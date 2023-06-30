#!/usr/bin/env janet
# (use sh)
# (os/cd "proj/libhook")

(defn make-device
  "Start evemu-device. Returns a struct containing
  the process handle and device path."
  [description]
  (def p (os/spawn ["evemu-device" "/dev/stdin"] :p {:in :pipe :out :pipe}))
  (:write (p :in) description)
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

(defn- spawn-evemu-event
  [device-path sync? type code value]
  (os/spawn
    ["evemu-event" device-path
     ;(if sync? ["--sync"] [])
     "--type" type
     "--code" code
     "--value" value]
    :px))

(defn wait-events
  "Wait for any unsynced events, but don't sync."
  [device]
  (def events (device :pending-events))
  (map :wait events)
  (array/clear events))

(defn event [device type code value sync]
  "Spawn evemu-event asynchronously. Wait for any unsynced events if sync is true."
  (if sync
    (do
      (wait-events device)
      (:wait (spawn-evemu-event (device :path) true type code value)))
    (array/push
      (device :pending-events)
      (spawn-evemu-event (device :path) false type code value))))

# Worse than when the last event has --sync
(comment
  (defn- sync [device]
    (def events (device :pending-events))
    (unless (empty? events)
      (each process events (:wait process))
      (:wait (spawn-evemu-event (device :path) true "0" "0" "0"))
      (array/clear events))))

