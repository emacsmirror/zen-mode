# zen-mode

Syntax highlighting and automatic indentation for the
[Zen programming language](http://www.zen-lang.org) in Emacs. Requires Emacs 24 or later.

## Installation

[![MELPA](https://melpa.org/packages/zen-mode-badge.svg)](https://melpa.org/#/zen-mode)

Simply install the `zen-mode` package via [MELPA](https://melpa.org/#/getting-started).

Alternatively, you can `git clone` the `zen-mode` repository somewhere
(e.g. under your `~/.emacs.d/`), then add the following to your `.emacs` file:

```elisp
(unless (version< emacs-version "24")
  (add-to-list 'load-path "~/path/to/your/zen-mode/")
  (autoload 'zen-mode "zen-mode" nil t)
  (add-to-list 'auto-mode-alist '("\\.zen\\'" . zen-mode)))
```

## Testing

To run all unit tests with `emacs`, run:

```bash
./run_tests.sh
```

Note that Emacs 24 or later is required.  If you need to specify which Emacs
binary to use, you can do that by setting the `EMACS` environment variable,
e.g.:

```bash
EMACS=/usr/bin/emacs24 ./run_tests.sh
```

## License

`zen-mode` is distributed under the terms of the GNU General Public License as
published by the Free Software Foundation; either version 3, or (at your
option) any later version.

See the [LICENSE](LICENSE) file for details.
