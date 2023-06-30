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

(def- az (range (chr "a") (inc (chr "z"))))
(def- AZ (range (chr "A") (inc (chr "Z"))))
(def- az-codes (map |(string "KEY_" (string/from-bytes $)) AZ))

(def kw->code
  (merge
    (zipcoll
      (->> all-keycode-names
           (map string/ascii-lower)
           (map keyword))
      (->> all-keycode-names
           (map |(string "KEY_" $))))
    {:ctrl "KEY_LEFTCTRL"
     :alt "KEY_LEFTALT"
     :shift "KEY_LEFTSHIFT"
     :meta "KEY_LEFTMETA"
     :win "KEY_LEFTMETA"
     :del "KEY_DELETE"
     :ins "KEY_INSERT"
     :bs "KEY_BACKSPACE"
     :pgup "KEY_PAGEUP"
     :pgdown "KEY_PAGEDOWN"
     :lmb "BTN_LEFT"
     :rmb "BTN_RIGHT"}))

(def code->kw
  (->> kw->code
       pairs
       (map reverse)
       from-pairs))

(def char->code
  "Convert (chr) code to keycode."
  (merge
    (zipcoll az az-codes)
    (zipcoll AZ az-codes)
    (zipcoll
      (string/bytes
        "1234567890`-=\t[]\\;'\n,./ \x08")
      (map |(string "KEY_" $)
           ["1" "2" "3" "4" "5" "6" "7" "8" "9" "0"
            "GRAVE"
            "MINUS"
            "EQUAL"
            "TAB"
            "LEFTBRACE"
            "RIGHTBRACE"
            "BACKSLASH"
            "SEMICOLON"
            "APOSTROPHE"
            "ENTER"
            "COMMA"
            "DOT"
            "SLASH"
            "SPACE"
            "BACKSPACE"]))
    (zipcoll
      (string/bytes
        "!@#$%^&*()~_+{}|:\"<>?")
      (map |(string "KEY_" $)
           ["1" "2" "3" "4" "5" "6" "7" "8" "9" "0"
            "GRAVE"
            "MINUS"
            "EQUAL"
            "LEFTBRACE"
            "RIGHTBRACE"
            "BACKSLASH"
            "SEMICOLON"
            "APOSTROPHE"
            "COMMA"
            "DOT"
            "SLASH"]))))

(def shift-chars
  "String of characters that require shift to type."
  (string
    (string/from-bytes ;AZ)
    "!@#$%^&*()~_+{}|:\"<>?"))

(def- shift-chars-set
  (zipcoll
    (string/bytes shift-chars)
    (string/bytes shift-chars)))

(defn needs-shift?
  "Return true if holding shift is required to type char."
  [char]
  (truthy? (get shift-chars-set char)))
