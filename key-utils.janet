(def- az (range (chr "a") (inc (chr "z"))))
(def- AZ (range (chr "A") (inc (chr "Z"))))
(def- az-kws (map |(keyword (string/from-bytes $)) az))

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

(def char->kw
  "Convert (chr) code to key keyword."
  (merge
    (zipcoll az az-kws)
    (zipcoll AZ az-kws)
    (zipcoll
      (string/bytes "1234567890`-=\t[]\\;'\n,./ \x08")
      [:1 :2 :3 :4 :5 :6 :7 :8 :9 :0
       :grave
       :minus
       :equal
       :tab
       :leftbrace
       :rightbrace
       :backslash
       :semicolon
       :apostrophe
       :enter
       :comma
       :dot
       :slash
       :space
       :backspace])
    (zipcoll
      (string/bytes "!@#$%^&*()~_+{}|:\"<>?")
      [:1 :2 :3 :4 :5 :6 :7 :8 :9 :0
       :grave
       :minus
       :equal
       :leftbrace
       :rightbrace
       :backslash
       :semicolon
       :apostrophe
       :comma
       :dot
       :slash])))
