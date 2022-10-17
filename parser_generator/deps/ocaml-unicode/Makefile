PACKAGE:=unicode
LIB:=unicode
MODULE:=Unicode

# Include configuration variables.
include Makefile.config

INCLUDES:=-I src

DFLAGS:=$(INCLUDES)
CFLAGS:=$(INCLUDES)
XFLAGS:=$(INCLUDES)
LFLAGS:=
OFLAGS:=$(INCLUDES)

ML:=$(shell $(OCAMLDEP) $(DFLAGS) -sort $(wildcard src/*.ml))
MLI:=$(shell $(OCAMLDEP) $(DFLAGS) -sort $(wildcard src/*.mli))
CMO:=$(ML:.ml=.cmo)
CMX:=$(ML:.ml=.cmx)
OBJ:=$(ML:.ml=.o)
CMI:=$(MLI:.mli=.cmi)

CMTI:=$(MLI:.mli=.cmti)
DOC:=$(CMTI:.cmti=.odoc)
HTML:=$(subst src/,doc/html/$(PACKAGE)/,$(DOC:.odoc=.html))

DEP:=.dep

TARGETS:=$(LIB).cmi $(LIB).cma $(LIB).cmx $(LIB).cmxa $(LIB).a $(LIB).cmxs

ifdef DEBUG
	CFLAGS += -g
	LFLAGS += -g
endif

all: byte native

byte: $(LIB).cma

native: $(LIB).cmxa $(LIB).cmxs

dep: $(DEP)

# Includes the dependencies to build in the right order
-include $(DEP)

$(DEP): $(ML) $(MLI)
	$(OCAMLDEP) $(DFLAGS) $^ > $@

$(CMI):%.cmi:%.mli
	$(OCAMLC) $(CFLAGS) -c -o $@ $<

$(CMO):%.cmo:%.ml %.cmi
	$(OCAMLC) $(CFLAGS) -c -o $@ $<

$(CMX):%.cmx:%.ml %.cmi
	$(OCAMLOPT) $(XFLAGS) -for-pack $(MODULE) -c -o $@ $<

$(CMTI):%.cmti:%.mli
	$(OCAMLC) $(CFLAGS) -bin-annot -for-pack $(MODULE) -c -o $@ $<

$(DOC):%.odoc:%.cmti
	odoc compile --package $(PACKAGE) $<

doc/html/$(PACKAGE)/%.html: src/%.odoc
	odoc html $(OFLAGS) -o doc/html $<

$(LIB).cmo $(LIB).cmi: %: $(CMO)
	$(OCAMLC) -pack -o $@ $^

$(LIB).cmx: %: $(CMX)
	$(OCAMLOPT) -pack -o $@ $^

$(LIB).cma: $(LIB).cmo
	$(OCAMLC) $(LFLAGS) -a -o $@ $<

$(LIB).cmxa $(LIB).a: $(LIB).cmx
	$(OCAMLOPT) $(LFLAGS) -a -o $@ $<

$(LIB).cmxs: $(LIB).cmx
	$(OCAMLOPT) $(LFLAGS) -shared -o $@ $<

doc: $(DOC)
	@mkdir -p doc/html
	odoc compile --package $(PACKAGE) src/index.mld

html: doc $(HTML)
	odoc html $(OFLAGS) -o doc/html src/page-index.odoc

install: $(TARGETS) $(LIB).cmi
	@echo "installing to $(PREFIX)/lib/$(PACKAGE)/"
	@mkdir -p $(PREFIX)/lib/$(PACKAGE)
	@cat META | sed "s/%LIBRARY%/$(LIB)/g" | sed "s/%VERSION%/$(shell cat VERSION)/g" > $(PREFIX)/lib/$(PACKAGE)/META
	@cp $(PACKAGE).opam $(PREFIX)/lib/$(PACKAGE)/
	@cp $(LIB).cmi $(LIB).cma $(PREFIX)/lib/$(PACKAGE)/
	@cp $(LIB).cmx $(LIB).cmxa $(LIB).cmxs $(LIB).a $(PREFIX)/lib/$(PACKAGE)/
	@echo "done."

uninstall:
	@echo "installing from $(PREFIX)/lib/$(PACKAGE)/"
	@rm -rf $(PREFIX)/lib/$(PACKAGE)
	@echo "done."

# Clean the repo.
partialclean:
	rm -rf $(CMO) $(CMX) $(OBJ) $(CMTI) $(LIB).o $(LIB).cmo $(DEP)

# Clean the repo.
clean: partialclean
	rm -rf $(CMI)

# Clean and remove binairies.
mrproper: clean
	rm -rf $(TARGETS)

# Non-file targets.
.PHONY: all dep doc html partialclean clean mrproper
