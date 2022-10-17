.PHONY: dependencies default simple-parser-gen uninstall clean mrproper

default: simple-parser-gen

dependencies:
	$(MAKE) --directory deps install

simple-parser-gen: dependencies
	dune build @install --root=src
	dune install --root=src

clean:
	$(MAKE) --directory deps clean

uninstall:
	$(MAKE) --directory deps uninstall
	dune uninstall --root=src

mrproper: clean uninstall
	$(MAKE) --directory deps mrproper
