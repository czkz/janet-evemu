(def- all-keycode-names
  ["1" "2" "3" "4" "5" "6" "7" "8" "9" "0"
   "ESC" "TAB"
   "MINUS" "EQUAL" "BACKSPACE"
   "ENTER" "SPACE"
   "Q" "W" "E" "R" "T" "Y" "U" "I" "O" "P"
   "A" "S" "D" "F" "G" "H" "J" "K" "L"
   "Z" "X" "C" "V" "B" "N" "M"
   "LEFTBRACE" "RIGHTBRACE"
   "LEFTCTRL" "RIGHTCTRL"
   "LEFTSHIFT" "RIGHTSHIFT"
   "LEFTALT" "RIGHTALT"
   "LEFTMETA" "RIGHTMETA"
   "SEMICOLON" "APOSTROPHE"
   "GRAVE"
   "BACKSLASH"
   "COMMA" "DOT" "SLASH"
   "F1" "F2" "F3" "F4" "F5" "F6" "F7" "F8" "F9" "F10" "F11" "F12"
   "F13" "F14" "F15" "F16" "F17" "F18" "F19" "F20" "F21" "F22" "F23" "F24"
   "CAPSLOCK" "NUMLOCK" "SCROLLLOCK"
   "KP0" "KP1" "KP2" "KP3" "KP4" "KP5" "KP6" "KP7" "KP8" "KP9"
   "KPMINUS" "KPPLUS" "KPDOT" "KPJPCOMMA" "KPENTER" "KPSLASH" "KPASTERISK" "KPEQUAL" "KPCOMMA" "KPPLUSMINUS" "KPLEFTPAREN" "KPRIGHTPAREN"
   "LINEFEED"
   "HOME" "END"
   "PAGEUP" "PAGEDOWN"
   "INSERT" "DELETE"
   "UP" "DOWN" "LEFT" "RIGHT"
   "MUTE" "MICMUTE"
   "VOLUMEUP" "VOLUMEDOWN"
   "SCROLLUP" "SCROLLDOWN"
   "SYSRQ" "PRINT"
   "BRIGHTNESSDOWN" "BRIGHTNESSUP"])

(def kw->code
  (merge
    (zipcoll
      (->> all-keycode-names
           (map string/ascii-lower)
           (map keyword))
      (->> all-keycode-names
           (map |(string "KEY_" $))))
    {:ctrl "KEY_LEFTCTRL"
     :lctrl "KEY_LEFTCTRL"
     :rctrl "KEY_RIGHTCTRL"
     :alt "KEY_LEFTALT"
     :lalt "KEY_LEFTALT"
     :ralt "KEY_RIGHTALT"
     :shift "KEY_LEFTSHIFT"
     :lshift "KEY_LEFTSHIFT"
     :rshift "KEY_RIGHTSHIFT"
     :meta "KEY_LEFTMETA"
     :win "KEY_LEFTMETA"
     :del "KEY_DELETE"
     :ins "KEY_INSERT"
     :bs "KEY_BACKSPACE"
     :pgup "KEY_PAGEUP"
     :pgdown "KEY_PAGEDOWN"
     :lmb "BTN_LEFT"
     :rmb "BTN_RIGHT"
     :mmb "BTN_MIDDLE"
     :mouse1 "BTN_LEFT"
     :mouse2 "BTN_RIGHT"
     :mouse3 "BTN_MIDDLE"
     :mouse4 "BTN_SIDE"
     :mouse5 "BTN_EXTRA"}))

(def code->kw
  (->> kw->code
       pairs
       (map reverse)
       from-pairs))
