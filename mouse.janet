(import ./evemu)
# (import spork/rawterm)

# Get a similar description with evemu-describe
(def- abs-device-desc
  (->>
    ["# EVEMU 1.3"
     "N: janet absolute pointer"
     "I: 0003 4711 0817 0001"
     "P: 00 00 00 00 00 00 00 00"
     "B: 00 0b 00 00 00 00 00 00 00"
     "B: 01 00 00 00 00 00 00 00 00"
     "B: 01 00 00 00 00 00 00 00 00"
     "B: 01 00 00 00 00 00 00 00 00"
     "B: 01 00 00 00 00 00 00 00 00"
     "B: 01 00 00 03 00 00 00 00 00"
     "B: 01 00 04 00 00 00 00 00 00"
     "B: 01 00 00 00 00 00 00 00 00"
     "B: 01 00 00 00 00 00 00 00 00"
     "B: 01 00 00 00 00 00 00 00 00"
     "B: 01 00 00 00 00 00 00 00 00"
     "B: 01 00 00 00 00 00 00 00 00"
     "B: 01 00 00 00 00 00 00 00 00"
     "B: 02 00 00 00 00 00 00 00 00"
     "B: 03 03 00 00 00 00 00 00 00"
     "B: 04 00 00 00 00 00 00 00 00"
     "B: 05 00 00 00 00 00 00 00 00"
     "B: 11 00 00 00 00 00 00 00 00"
     "B: 12 00 00 00 00 00 00 00 00"
     "B: 14 00 00 00 00 00 00 00 00"
     "B: 15 00 00 00 00 00 00 00 00"
     "B: 15 00 00 00 00 00 00 00 00"
     "A: 00 0 10000 0 0 0"
     "A: 01 0 10000 0 0 0"]
    (mapcat |[$ "\n"])
    string/join))

(def- button->keycode
  {:left "BTN_LEFT"
   :right "BTN_RIGHT"
   :touch "BTN_TOUCH"})

(def- abs-device (evemu/make-device abs-device-desc))

(comment
  (-> (abs-device :process) :kill :wait))

(var *delay*
  "Delay in seconds after each mouse click."
  0.00)

(defn to
  "Set mouse to position from 0 to 1."
  [x y]
  # Setting to the same position twice in a row
  # doesn't generate an event, so reset to zero or one.
  # Sync isn't called so the extra event is invisible.
  (evemu/event abs-device "EV_ABS" "ABS_X" (if (zero? x) "1" "0") false)
  (evemu/wait-events abs-device)
  (def x (->> x (* 10000) math/round string))
  (def y (->> y (* 10000) math/round string))
  (evemu/event abs-device "EV_ABS" "ABS_X" x false)
  (evemu/event abs-device "EV_ABS" "ABS_Y" y true))
  # (ev/sleep *delay*))

(defn click
  "Do a mouse click, button is either :left or :right."
  [&opt button]
  (default button :left)
  (def keycode (button->keycode button))
  (evemu/event abs-device "EV_KEY" keycode "1" true)
  (evemu/event abs-device "EV_KEY" keycode "0" true)
  (ev/sleep *delay*))

(defn at
  "Click mouse at position from 0 to 1."
  [x y &opt button]
  (to x y)
  (click button))

# These don't always work as expected
(defn down
  "Press and hold the :left or :right mouse button."
  [&opt button]
  (default button :left)
  (evemu/event abs-device "EV_KEY" (button->keycode button) "1" true)
  (ev/sleep *delay*))
(defn up
  "Release the :left or :right mouse button."
  [&opt button]
  (default button :left)
  (evemu/event abs-device "EV_KEY" (button->keycode button) "0" true)
  (ev/sleep *delay*))
(defn drag
  ``Drag mouse from p0 to p1.
  Can be janky in gnome-shell, but works fine inside applications.``
  [x0 y0 x1 y1 &opt button]
  (to x0 y0)
  (down button)
  (to x1 y1)
  (up button))

# For delay finetuning
(comment
  (do
    (set *delay* 0.00)
    (ev/sleep 0)
    (to 0.4 0.5)
    (to 0.5 0.5)
    (to 0.4 0.5)
    (to 0.5 0.5)
    (to 0.4 0.5)
    (to 0.5 0.5)
    (to 0.4 0.5)
    (to 0.5 0.5)
    (to 0.4 0.5)
    (to 0.5 0.5)
    (to 0.4 0.5)
    (to 0.5 0.5)
    (click) # Should click on [0.5 0.5]
    (to 0.4 0.5)
    (to 0.4 0.5)
    (to 0.4 0.5)
    (to 0.4 0.5)
    (to 0.4 0.5)
    (to 0.4 0.5))

  (do
    (ev/sleep 0.75)
    (set *delay* 0.0)
    (drag 0.5 0.5 0.4 0.5)))


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

(defn pick-x11 []
  "Returns normalized mouse coors as per XWayland."
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

(defn pick []
  "Interactively find mouse coords for a point on screen."
  [(find-sym at) ;(pick-x11)])
