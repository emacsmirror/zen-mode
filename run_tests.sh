#!/bin/sh

if [ -z "${EMACS}" ]; then
    EMACS="emacs"
else
    echo "Running with EMACS=${EMACS}"
fi

${EMACS} --batch -l zen-mode.el -l tests.el -f ert-run-tests-batch-and-exit
