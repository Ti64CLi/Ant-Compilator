### Définitions de variables ###

# Le fichier contenant la grammaire du langage.
GRAMMAR=src/lang.grammar
# Les sources.
SRC=$(wildcard src/*)

# Les fichiers du parser sont générés automatiquement avec l'outil
# `simple-parser-gen`.
PARSER_GEN=simple-parser-gen
PARSER_FILES=src/ast.mli src/ast.ml src/lexer.mli src/lexer.ml src/parser.mli src/parser.ml

### Règles de constructions ###

antsc: $(PARSER_FILES) $(SRC) $(GRAMMAR)
	dune build @install
	@cp _build/install/default/bin/antsc $@

# Interface du module Ast contenant la définition de l'arbre de syntaxe abstraite.
src/ast.mli: $(GRAMMAR)
	$(PARSER_GEN) -a -i $^ | ocp-indent > $@

# Module Ast.
src/ast.ml: $(GRAMMAR)
	$(PARSER_GEN) -a $^ | ocp-indent > $@

# Interface du module Lexer.
src/lexer.mli: $(GRAMMAR)
	$(PARSER_GEN) -l -i $^ | ocp-indent > $@

# Le module Lexer.
src/lexer.ml: $(GRAMMAR)
	$(PARSER_GEN) -l $^ | ocp-indent > $@

# Interface du parser.
src/parser.mli: $(GRAMMAR)
	$(PARSER_GEN) -p -i $^ | ocp-indent > $@

# Le parser.
src/parser.ml: $(GRAMMAR)
	$(PARSER_GEN) -p $^ | ocp-indent > $@

# Génération de tous les fichiers du parser.
parser: $(PARSER_FILES)

deps:
	$(MAKE) --directory parser_generator

clean:
	rm -f $(PARSER_FILES)
	$(MAKE) --directory parser_generator clean

uninstall_deps:
	$(MAKE) --directory parser_generator uninstall

mrproper: clean
	rm -rf _build
	rm -f antsc antsc.install
	$(MAKE) --directory parser_generator mrproper

.PHONY: parser clean mrproper deps uninstall_deps
