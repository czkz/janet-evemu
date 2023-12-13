(import ./evemu/event :as evemu-event)
(use ./input-device)

(def- button->keycode
  {:left "BTN_LEFT"
   :right "BTN_RIGHT"
   :middle "BTN_MIDDLE"})

(var *delay*
  "Delay in seconds after each mouse click."
  0)

(defn to
  "Set mouse to position from 0 to 1."
  [x y]
  # Setting to the same position twice in a row
  # doesn't generate an event, so reset to zero or one.
  # Sync isn't called so the extra event is invisible.
  (evemu-event/emit (device) "EV_ABS" "ABS_X" (if (zero? x) "1" "0") false)
  (evemu-event/wait-for-unsynced (device))
  (def x (->> x (* 10000) math/round string))
  (def y (->> y (* 10000) math/round string))
  (evemu-event/emit (device) "EV_ABS" "ABS_X" x false)
  (evemu-event/emit (device) "EV_ABS" "ABS_Y" y true))
  # (ev/sleep *delay*))

(defn click
  "Do a mouse click, button is either :left or :right."
  [&opt button]
  (default button :left)
  (def keycode (button->keycode button))
  (evemu-event/emit (device) "EV_KEY" keycode "1" true)
  (evemu-event/emit (device) "EV_KEY" keycode "0" true)
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
  (evemu-event/emit (device) "EV_KEY" (button->keycode button) "1" true)
  (ev/sleep *delay*))
(defn up
  "Release the :left or :right mouse button."
  [&opt button]
  (default button :left)
  (evemu-event/emit (device) "EV_KEY" (button->keycode button) "0" true)
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
