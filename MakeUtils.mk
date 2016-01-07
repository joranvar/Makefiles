ifndef MAKE_clean
 MAKE_clean = if [ "$(dir $(wildcard $(1)))x" != "x" ]; then rm -fr $(wildcard $(1)); fi; if [ "$(dir $(wildcard $(1)))x" != "x" ]; then rmdir -p --ignore-fail-on-non-empty $(dir $(wildcard $(1))); fi
endif
