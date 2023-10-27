(import ./mouse)
(import ./kb)
(import ./evemu/record :as evemu-record)
(import ./evemu/keyconv)
(import ./event-monitor)
(import ./input-device)

(defn- find-sym [v]
  (find |(-> $ dyn (get :value) (= v)) (all-bindings)))

(defn mouse-pos []
  "Set mouse position to where it is right now."
  [(find-sym mouse/to) ;(event-monitor/get-cursor-pos)])

(defn mouse-click []
  "Repeat the next mouse click."
  (def [key _]
    (event-monitor/wait-for :down :lmb :rmb))
  (tuple (find-sym mouse/at) ;(event-monitor/get-cursor-pos) ;(if (= key :rmb) [:rmb] [])))

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
  (with [mon (evemu-record/make-listener input-device/exclude-filter ev-filter)]
    (def cmds @[])
    (forever
      (def ev (:read mon))
      (def key (keyconv/code->kw (ev 1)))
      (when (= key :esc) (break))
      (def cmd
        (tuple func ;(event-monitor/get-cursor-pos) ;(if (= key :rmb) [:rmb] [])))
      (array/push cmds cmd))
    (tuple 'do ;cmds)))

(comment
  (mouse-pos)
  (mouse-click)
  (mouse-events))
