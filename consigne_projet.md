# Avant de commencer

Il faut que vous ayez installé sur votre ordinateur:

  - OCaml, version 4.08 ou plus
  - Le système de construction `dune` version 1.11 ou plus  (`opam install dune`)
  - `ocp-indent` et `ocamlfind` (`opam install ocp-indent ocamlfind`)

Avant de commencer le projet, exécutez la commande
```
make deps
```
dans ce dossier dans un terminal. Cela installera sur votre ordinateur le programme
`simple-parser-gen` qui vous servira à générer automatiquement des parseurs
à partir d'une description simple du langage à parser (voir plus bas).

Vous pouvez tester la bonne installation de `simple-parser-gen` avec la commande
```
$ simple-parser-gen --help
```

# Dans ce dossier vous trouverez:

  - Un fichier `sujet.pdf` qui décrit le sujet de ce projet.
  - Un fichier `criteres_notation.md` récapitulant certains critères de notation.
  - Un dossier `worlds` contenant des descriptions de terrains sur
    lesquels des colonies de fourmis peuvent s'affronter.
  - Un dossier `brains` contenant des exemples très simples de codes
    neuronaux pour des colonies de fourmis.
  - Un dossier `simulator` permettant de faire s'affronter des colonies
    de fourmis (`firefox simulator/simulator.html` pour l'exécuter, par exemple).
    Il faut lui passer un terrain (exemples dans `worlds`) et deux codes neuronaux
    (exemples dans `brains`).
  - Un dossier `src` dans lequel vous pourrez placer votre code. Voir plus d'explications plus bas.
  - Des fichiers `Makefile` et `dune-project`. N'y touchez pas.
  - Un dossier `parser_generator`. N'y touchez pas. Ne le regardez pas.

# Principe du projet
L'idée de ce projet est que vous construisiez votre propre langage pour programmer
des colonies de fourmis, et que vous programmiez un compilateur de votre langage
vers le format `.brain` attendu par le simulateur.

Pour vous simplifier la tache, une partie du travail a été faite pour vous:
si vous exécutez la commande
```bash
make
```
dans le dossier où ce trouve ce README, cela aura deux effets:

  - Générer automatiquement un lexeur, un parseur et une définition de grammaire abstraite pour votre langage,
    à partir du fichier `lang.grammar` (voir section `Fichiers générés automatiquement`).
  - Compiler votre compilateur, comme décrit dans la section `Compiler votre compilateur`

## Fichiers générés automatiquement

3 modules sont générés automatiquement à partir du fichier `src/lang.grammar` :

  - Le module `Ast` (fichiers `ast.ml`, `ast.mli`) contient la définition
    de l'arbre de syntaxe abstraite (la structure d'un programme) du langage,
    et des fonctions d'affichage.

  - Le module `Lexer` (fichiers `lexer.ml`, `lexer.mli`) contient le *lexer*
    du langage, qui s'occupe de découper les mots du langage.

  - Le module `Parser` (fichiers `parser.ml`, `parser.mli`) contient le *parser*
    du langage, qui s'occupe de générer un arbre de syntaxe abstraite à partir
    du résultat renvoyé par le *lexer*.

## Format du fichier `lang.grammar`
The parser is generated from a grammar file that consists in a list of non-terminal definitions of the form:

```
type non_terminal_name =
  | Constructor1        syntax1
  ...
  | Constructorn        syntaxn
```

It is inspired of the OCaml's sum type definition syntax.
Each rule is described by an OCaml constructor name,
followed by a syntax definition.
The syntax definition is a list of *tokens*, where a token is either
a *terminal* or a non-terminal of the form `<name>`.

Here is an exemple of a grammar definition :

```
type expression =
  | Var             <ident>
  | IfThenElse      if <condition> then <expression> else <expression>
  | Do              do <action>
  | Repeat          repeat <expression>

type condition =
  | Is              is <state>
  | HaveFood        have food
  | Not             not <condition>

type state =
  | Hungry          hungry
  | Sleepy          sleepy

type action =
  | Eat             eat
  | Sleep           sleep
```

The definition is then expanded into the following OCaml code :

```ocaml
open CodeMap

type expression =
  | Var of string Span.located
  | IfThenElse of condition Span.located * expression Span.located * expression Span.located
  | Do of action Span.located
  | Repeat of expression Span.located

and condition =
  | Is of state Span.located
  | HaveFood
  | Not of condition Span.located

and state =
  | Hungry
  | Sleepy

and action =
  | Eat
  | Sleep
```

Each non-terminal becomes an OCaml type.
The `'a Span.located` type hold the information about the location of the
abstract syntax tree in the parsed file.
It can be used to display useful error messages using `Span.print`.
It is just a pair `'a * Span.t` and can be deconstructed as such using a pattern matching.

### Predefined non-terminals

Note that in the previous example,
the `<ident>` non-terminal has been replaced by the type `string` during the
code generation. It is a predefined non-terminal recognizing identifiers
of the form `[a-zA-Z][a-zA-Z0-9]*`.

The predefined non-terminals are :

  - `<int>` : recognizes integers, is expanded into the type `int`.
  - `<ident>` : recognizes identifiers, is expanded into the type `string`.
  - `<name*sep>` : list of `<name>` separated by the token `sep`.
  Is expanded into the type `name Span.located list`.
  - `<name+sep>` : non-empty list of `<name>` separated by the terminal `sep`.
  Is expanded into the type `name Span.located list`.
  - `<name?>` : optional `<name>`. Is expanded into the type `name option`.

### Limitations

The grammar must be (almost) LL1 :

  - No two rules can start with the same terminal.
  - The priority goes to the deepest non-terminal :
  if you define a non-terminal of the form
  ```
  type expression =
  | Int   <int>
  | A     a <expression+;>
  | B     b <expression+;>
  ```
  then the input `a b 0; 1; 2` is recognized as `A [B [0; 1; 2]]` and **not** as
  `A [B [0]; 1; 2]`.

## Compiler votre compilateur
Quand vous faites
```
make
```
dans ce dossier, cela utilise l'outil `dune` pour créer un exécutable `antsc` qui exécute le code
de `src/antsc.ml`. Notez que `dune` s'occupe tout seul de faire des modules pour tous les fichiers
`.ml` et `.mli` présents dans le dossier `src/` (y compris les fichiers générés automatiquement
décrits dans les sections précédentes).
Par exemple, si vous avez un fichier `src/myCompilo.ml` qui définit une fonction `magic_function`,
vous pouvez l'utiliser dans vous autres fichiers `.ml` de `src/` sous la forme
```ocaml
... MyCompilo.magic_function ...
```
ou
```ocaml
open MyCompilo;;

... magic_function ...
```

## Concrètement vous devez

  - Modifier le fichier `src/lang.grammar` pour qu'il décrive votre langage.
  - Modifier le fichier `src/antsc.ml` pour qu'au lieu de juste afficher le code parsé il le compile
    et l'écrive dans un fichier au format `.brain`
  - Écrire une stratégie pour une colonie de fourmis dans votre langage et la compiler
    en utilisant l'exécutable `antsc`
