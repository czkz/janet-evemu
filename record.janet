(import ./mouse)
(import ./kb)
(import ./evemu/record :as evemu-record)
(import ./evemu/keyconv)

(defn- get-cursor-pos []
  "Returns normalized mouse coords as per XWayland."
  (defn get-lines [& args]
    (->> (with [p (os/spawn args :px {:out :pipe :err :pipe})]
           (:read (p :out) :all))
         (string/trimr)
         (string/split "\n")
         (map string/trim)))
  (def resolution
    (->>
      (get-lines "xrandr")
      first
      (string/split ", ")
      (keep |(peg/match '(* "current " ':d+ " x " ':d+ -1) $))
      (mapcat identity)
      (map scan-number)))
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
  (map / pos resolution))

(defn- find-sym [v]
  (find |(-> $ dyn (get :value) (= v)) (all-bindings)))

(defn mouse-pos []
  "Set mouse position to where it is right now."
  [(find-sym mouse/to) ;(get-cursor-pos)])

(def- code->kw
  {"BTN_LEFT" :left
   "BTN_RIGHT" :right
   "BTN_MIDDLE" :middle})

(defn mouse-click []
  "Repeat the next mouse click."
  (def key
    (code->kw (evemu-record/wait-for :down "BTN_LEFT" "BTN_RIGHT")))
  [(find-sym mouse/at) ;(get-cursor-pos) ;(if (= key "BTN_RIGHT") [:right] [])])

(defn mouse-events []
  "Record mouse clicks until :esc is pressed."
  (def ev-filter-keys
    {"BTN_LEFT" 1
     "BTN_RIGHT" 1
     "KEY_ESC" 1})
  (defn ev-filter [t c v]
    (and (= t "EV_KEY")
         (ev-filter-keys c)
         (= v "1")))
  (def func (find-sym mouse/at))
  (with [mon (evemu-record/make-listener ev-filter)]
    (def cmds @[])
    (forever
      (def ev (:read mon))
      (def kw (code->kw (ev 1)))
      (when (= (ev 1) "KEY_ESC") (break))
      (def cmd
        (tuple func ;(get-cursor-pos) ;(if (= kw :left) [] [kw])))
      (array/push cmds cmd))
    (tuple 'do ;cmds)))

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
  (mouse-pos)
  (mouse-click)
  (mouse-events))
