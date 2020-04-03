;; Tests for zen-mode.

(require 'ert)
(require 'zen-mode)
(require 'imenu)

;;===========================================================================;;
;; Font lock tests

(defun zen-test-font-lock (code expected)
  (let* ((fontified-code
          (with-temp-buffer
            (zen-mode)
            (insert code)
            (font-lock-fontify-buffer)
            (buffer-string)))
         (start 0)
         (actual '()))
    (while start
      (let* ((end (next-single-property-change start 'face fontified-code))
             (substring (substring-no-properties fontified-code start end))
             (face (get-text-property start 'face fontified-code)))
        (when face
          (setq actual (cons (list substring face) actual)))
        (setq start end)))
    (should (equal expected (reverse actual)))))

(ert-deftest test-font-lock-backslash-in-char-literal ()
  (zen-test-font-lock
   "const escaped = '\\'';"
   '(("const" font-lock-keyword-face)
     ("escaped" font-lock-variable-name-face)
     ("'\\''" font-lock-string-face))))

(ert-deftest test-font-lock-backslash-in-multiline-str-literal ()
  (zen-test-font-lock
   "
const string =
    \\\\ This newline is NOT escaped \\
;"
   '(("const" font-lock-keyword-face)
     ("string" font-lock-variable-name-face)
     ("\\\\ This newline is NOT escaped \\\n" zen-multiline-string-face))))

(ert-deftest test-font-lock-backslash-in-str-literal ()
  (zen-test-font-lock
   "\"This quote \\\" is escaped\""
   '(("\"This quote \\\" is escaped\"" font-lock-string-face))))

(ert-deftest test-font-lock-builtins ()
  (zen-test-font-lock
   "const std = @import(\"std\");"
   '(("const" font-lock-keyword-face)
     ("std" font-lock-variable-name-face)
     ("@import" font-lock-builtin-face)
     ("\"std\"" font-lock-string-face))))

(ert-deftest test-font-lock-comments ()
  (zen-test-font-lock
   "
// This is a normal comment\n
/// This is a doc comment\n
//// This is a normal comment again\n"
   '(("// This is a normal comment\n" font-lock-comment-face)
     ("/// This is a doc comment\n" font-lock-doc-face)
     ("//// This is a normal comment again\n" font-lock-comment-face))))

(ert-deftest test-font-lock-decl-const ()
  (zen-test-font-lock
   "const greeting = \"Hello, world!\";"
   '(("const" font-lock-keyword-face)
     ("greeting" font-lock-variable-name-face)
     ("\"Hello, world!\"" font-lock-string-face))))

(ert-deftest test-font-lock-decl-fn ()
  (zen-test-font-lock
   "fn plus1(value: u32) u32 { return value + 1; }"
   '(("fn" font-lock-keyword-face)
     ("plus1" font-lock-function-name-face)
     ("value" font-lock-variable-name-face)
     ("u32" font-lock-type-face)
     ("u32" font-lock-type-face)
     ("return" font-lock-keyword-face))))

(ert-deftest test-font-lock-decl-var ()
  (zen-test-font-lock
   "var finished = false;"
   '(("var" font-lock-keyword-face)
     ("finished" font-lock-variable-name-face)
     ("false" font-lock-constant-face))))

(ert-deftest test-font-lock-multiline-str-literal ()
  (zen-test-font-lock
   "
const python =
    \\\\def main():
    \\\\    print(\"Hello, world!\")
;"
   '(("const" font-lock-keyword-face)
     ("python" font-lock-variable-name-face)
     ("\\\\def main():\n" zen-multiline-string-face)
     ("\\\\    print(\"Hello, world!\")\n" zen-multiline-string-face))))

(ert-deftest test-font-lock-multiline-str-literal-for-empty-line ()
  (zen-test-font-lock
   "
const str =
    \\\\string\\
    \\\\
;"
   '(("const" font-lock-keyword-face)
     ("str" font-lock-variable-name-face)
     ("\\\\string\\\n" zen-multiline-string-face)
     ("\\\\\n" zen-multiline-string-face))))

(ert-deftest test-font-lock-single-str-literal-escape ()
  (zen-test-font-lock
   "const str = \"string\\\\\";"
   '(("const" font-lock-keyword-face)
     ("str" font-lock-variable-name-face)
     ("\"string\\\\\"" font-lock-string-face))))

(ert-deftest test-font-lock-break-label ()
  (zen-test-font-lock
   "break :brk 0;"
   '(("break" font-lock-keyword-face)
     (" :brk" zen-label-face))))

(ert-deftest test-font-lock-break ()
  (zen-test-font-lock
   "break;"
   '(("break" font-lock-keyword-face))))

(ert-deftest test-font-lock-catch ()
  (zen-test-font-lock
   "catch |err| brk: {};"
   '(("catch" font-lock-keyword-face)
     ("|" zen-catch-vertical-bar-face)
     ("err" font-lock-variable-name-face)
     ("|" zen-catch-vertical-bar-face)
     ("brk:" zen-label-face))))

(ert-deftest test-font-lock-field ()
  (zen-test-font-lock
   "a : *u32, b: []u8, c:[4]u8, d:[*c]u8, e:[*:0]u8, f:?*[]u8, g: *@Vector,"
   '(("a" font-lock-variable-name-face)
     ("*u32" font-lock-type-face)
     ("b" font-lock-variable-name-face)
     ("[]u8" font-lock-type-face)
     ("c" font-lock-variable-name-face)
     ("[4]u8" font-lock-type-face)
     ("d" font-lock-variable-name-face)
     ("[*c]u8" font-lock-type-face)
     ("e" font-lock-variable-name-face)
     ("[*:0]u8" font-lock-type-face)
     ("f" font-lock-variable-name-face)
     ("?*[]u8" font-lock-type-face)
     ("g" font-lock-variable-name-face)
     ("@Vector" font-lock-type-face))))

(ert-deftest test-font-lock-builtin ()
  (zen-test-font-lock
   "@call @TypeOf @Type @Frame @Vector"
   '(("@call" font-lock-builtin-face)
     ("@TypeOf" font-lock-type-face)
     ("@Type" font-lock-type-face)
     ("@Frame" font-lock-type-face)
     ("@Vector" font-lock-type-face))))

;;===========================================================================;;
;; Indentation tests

(defun zen-test-indent-line (line-number original expected-line)
  (with-temp-buffer
    (zen-mode)
    (insert original)
    (goto-line line-number)
    (indent-for-tab-command)
    (let* ((current-line (thing-at-point 'line t))
           (stripped-line (replace-regexp-in-string "\n\\'" "" current-line)))
      (should (equal expected-line stripped-line)))))

(ert-deftest test-indent-from-current-block ()
  (zen-test-indent-line
   6
   "
{
  // Normally, zen-mode indents to 4, but suppose
  // someone indented this part to 2 for some reason.
  {
    // This line should get indented to 6, not 8.
  }
}"
   "      // This line should get indented to 6, not 8."))

(defun zen-test-indent-region (original expected)
  (with-temp-buffer
    (zen-mode)
    (insert original)
    (indent-region 1 (+ 1 (buffer-size)))
    (should (equal expected (buffer-string)))))

(ert-deftest test-indent-top-level ()
  (zen-test-indent-region
   "  const four = 4;"
   "const four = 4;"))

(ert-deftest test-indent-fn-def-body ()
  (zen-test-indent-region
   "
pub fn plus1(value: u32) u32 {
return value + 1;
}"
   "
pub fn plus1(value: u32) u32 {
    return value + 1;
}"))

(ert-deftest test-indent-fn-def-args ()
  (zen-test-indent-region
   "
pub fn add(value1: u32,
value2: u32) u32 {
return value1 + value2;
}"
   "
pub fn add(value1: u32,
           value2: u32) u32 {
    return value1 + value2;
}"))

(ert-deftest test-indent-fn-call-args ()
  (zen-test-indent-region
   "
blarg(foo,
foo + bar + baz +
quux,
quux);"
   "
blarg(foo,
      foo + bar + baz +
          quux,
      quux);"))

(ert-deftest test-indent-if-else ()
  (zen-test-indent-region
   "
fn sign(value: i32) i32 {
if (value > 0) return 1;
else if (value < 0) {
return -1;
} else {
return 0;
}
}"
   "
fn sign(value: i32) i32 {
    if (value > 0) return 1;
    else if (value < 0) {
        return -1;
    } else {
        return 0;
    }
}"))

(ert-deftest test-indent-struct ()
  (zen-test-indent-region
   "
const Point = struct {
x: f32,
y: f32,
};
const origin = Point {
.x = 0.0,
.y = 0.0,
};"
   "
const Point = struct {
    x: f32,
    y: f32,
};
const origin = Point {
    .x = 0.0,
    .y = 0.0,
};"))

(ert-deftest test-indent-multiline-str-literal ()
  (zen-test-indent-region
   "
const code =
\\\\const foo = []u32{
\\\\    12345,
\\\\};
;"
   "
const code =
    \\\\const foo = []u32{
    \\\\    12345,
    \\\\};
;"))

(ert-deftest test-indent-array-literal-1 ()
  (zen-test-indent-region
   "
const msgs = [][]u8{
\"hello\",
\"goodbye\",
};"
   "
const msgs = [][]u8{
    \"hello\",
    \"goodbye\",
};"))

(ert-deftest test-indent-array-literal-2 ()
  (zen-test-indent-region
   "
const msg = []u8{'h', 'e', 'l', 'l', 'o',
'w', 'o', 'r', 'l', 'd'};"
   "
const msg = []u8{'h', 'e', 'l', 'l', 'o',
                 'w', 'o', 'r', 'l', 'd'};"))

(ert-deftest test-indent-paren-block ()
  (zen-test-indent-region
   "
const foo = (
some_very_long + expression_that_is * set_off_in_parens
);"
   "
const foo = (
    some_very_long + expression_that_is * set_off_in_parens
);"))

(ert-deftest test-indent-double-paren-block ()
  (zen-test-indent-region
   "
const foo = ((
this_expression_is + set_off_in_double_parens * for_some_reason
));"
   "
const foo = ((
    this_expression_is + set_off_in_double_parens * for_some_reason
));"))

(ert-deftest test-indent-with-comment-after-open-brace ()
  (zen-test-indent-region
   "
if (false) { // This comment shouldn't mess anything up.
launchTheMissiles();
}"
   "
if (false) { // This comment shouldn't mess anything up.
    launchTheMissiles();
}"))

;;===========================================================================;;
;; Imenu tests

;; taken from rust-mode
(defun test-imenu (code expected-items)
  (with-temp-buffer
	(zen-mode)
	(insert code)
	(let ((actual-items
		   ;; Replace ("item" . #<marker at ? in ?.el) with "item"
		   (mapcar (lambda (class)
					 (cons (car class)
						   (mapcar #'car (cdr class))))
				   (imenu--generic-function zen-imenu-generic-expression))))
	  (should (equal expected-items actual-items)))))


(ert-deftest test-imenu-struct ()
  (test-imenu
   "
pub const Foo = struct {};
pub const Bar = extern struct {};
const FooBar = struct {};
"
   '(("Struct"
	  "Foo"
	  "Bar"
	  "FooBar"))))

(ert-deftest test-imenu-enum ()
  (test-imenu
   "
pub const Foo = enum {};
const FooBarError = enum {};
"
   '(("Enum"
	  "Foo"
	  "FooBarError"))))

(ert-deftest test-imenu-enum ()
  (test-imenu
   "
pub const Foo = enum {};
const FooBarError = enum {};
"
   '(("Enum"
	  "Foo"
	  "FooBarError"))))

(ert-deftest test-imenu-all ()
  (test-imenu
   "
const Foo = struct {
	pub fn init() void {}
};

const FooError = enum {};

pub fn main() void {
}
"
   '(("Fn" "init" "main")
	 ("Struct" "Foo")
	 ("Enum" "FooError"))))


;;===========================================================================;;
