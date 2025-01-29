(import ./evemu/record :as evemu-record)
(import ./evemu/keyconv)
(import ./input-device)

(defn- get-lines [& args]
  (->> (with [p (os/spawn args :px {:out :pipe :err :pipe})]
         (:read (p :out) :all))
       (string/trimr)
       (string/split "\n")
       (map string/trim)))

(defn- get-cursor-pos-xdotool []
  "Works on both X11 and XWayland, but needs xdotool."
  (->>
    (get-lines "xdotool" "getmouselocation")
    first
    (peg/match '(* "x:" ':d+ " y:" ':d+))
    (map scan-number)))

(defn- get-cursor-pos-xinput []
  "Only works on XWayland."
  (def pointer-id
    (->>
      (get-lines "xinput" "list" "--name-only")
      (filter |(string/has-prefix? "xwayland-relative-pointer" $))
      first))
  (def pos
    (->>
      (get-lines "xinput" "--query-state" pointer-id)
      (keep |(peg/match '(* "valuator[" (set "01") "]=" ':d+ -1) $))
      (mapcat identity)
      (map scan-number)))
  pos)

(defn get-cursor-pos []
  "Returns normalized mouse coords."
  (def resolution
    (->>
      (get-lines "xrandr")
      first
      (string/split ", ")
      (keep |(peg/match '(* "current " ':d+ " x " ':d+ -1) $))
      (mapcat identity)
      (map scan-number)))
  (def pos
    (try (get-cursor-pos-xdotool)
      ([err fib] (get-cursor-pos-xinput))))
  (map / pos resolution))

(defn make-waiter
  "Wait for a key :down or :up or :any on any device."
  [state & keys]
  (assert ({:down 1 :up 1 :any 1} state))
  (def keycodes
    (map keyconv/kw->code keys))
  (defn ev-filter
    [t c v]
    (and (= t "EV_KEY")
         (find |(= c $) keycodes)
         (or (= state :any)
             (= v (if (= state :down) "1" "0")))))
  (def l (evemu-record/make-listener input-device/exclude-filter ev-filter))
  (defn wait [_]
    (let [e (:read l)]
      [(keyconv/code->kw (e 1))
       (case (e 2) "0" :down "1" :up)]))
  (defn close [_]
    (:close l))
  {:wait wait
   :close close})

(defn wait-for
  "Wait for a key event on any device. Much slower than make-waiter if used multiple times."
  [state & keys]
  (with [waiter (make-waiter state ;keys)]
    (:wait waiter)))

(comment
  (defn pick-rawterm
    "Select mouse position with WASD on tty."
    []
    (var x 0.5)
    (var y 0.5)
    (var dx 0.25)
    (var dy 0.25)
    (def min-d 0.001)
    (def getch rawterm/getch)
    (rawterm/begin)
    (defer (rawterm/end)
      (to x y)
      (spit "/dev/stdout" "Move with WASD. Enter to stop.\n")
      (forever
        (case ((getch) 0)
          (chr "a") (do (-= x dx) (/= dx 2))
          (chr "d") (do (+= x dx) (/= dx 2))
          (chr "w") (do (-= y dy) (/= dy 2))
          (chr "s") (do (+= y dy) (/= dy 2))
          (break))
        (if (< dx min-d) (set dx min-d))
        (if (< dy min-d) (set dy min-d))
        (to x y))
      [x y])))

(comment
  (wait-for :down :lmb :rmb))

(comment
  (import ./kb)
  (when-clicked :0
    (kb/type "abc")))
