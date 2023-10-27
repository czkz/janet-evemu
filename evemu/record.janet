(defn- make-line-reader [stream]
  (var buf @"")
  (var start 0)
  (defn reloc-buf []
    (when (> start 0)
      (set buf (buffer/slice buf start))
      (set start 0)))
  (fn []
    (var ret nil)
    (forever
      (if-let [line-end (string/find "\n" buf start)]
        (do
          (set ret (buffer/slice buf start line-end))
          (set start (inc line-end))
          (break))
        (do
          (reloc-buf)
          (or
            (:read stream 64 buf)
            (break)))))
    ret))

(def- event-peg
  ~{:main (*
           "E:" :s+ :num :s+
           :num :s+ :num :s+ :num :s+
           "#" :s+
           :str :s+
           "/" :s+
           :str :s+
           :num -1)
    :num (/ ':S+ ,string)
    :str (/ ':S+ ,string)
    :S+ (some :S)})

(defn make-device-listener
  [device-path &opt ev-filter]
  (default ev-filter (fn [&] true))
  (def p (os/spawn ["evemu-record" device-path] :p {:out :pipe}))
  (def read (make-line-reader (p :out)))
  (defn event-read []
    (var ret nil)
    (while (def line (read))
      (when-let [match (peg/match event-peg line)
                 ev (drop 4 match)
                 passed-filter (ev-filter ;ev)]
        (set ret ev)
        (break)))
    ret)
  {:close (fn [self] (:kill p true))
   :read (fn [self] (event-read))})

(defn make-listener
  "Listen for events on all devices."
  [dev-filter ev-filter]
  (default ev-filter (fn [&] true))
  (default dev-filter (fn [path] true))
  (def devices
    (let [dir "/dev/input/"
          names (filter
                  |(peg/match '(* "event" :d+ -1) $)
                  (os/dir dir))
          paths (map |(string dir $) names)]
      (filter dev-filter paths)))
  (def listeners
    (map |(make-device-listener $ ev-filter) devices))
  (def ch (ev/chan))
  (defn read [&]
    (ev/take ch))
  (def fibs
    (map
      |(ev/spawn
         (protect
           (forever
             (ev/give ch (:read $)))))
      listeners))
  (defn close [&]
    (each l listeners (:close l))
    (each fib fibs (ev/cancel fib "close")))
  {:close close
   :read read})
