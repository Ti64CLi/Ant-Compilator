# Simple parser generator

This is an easy-to-use parser generator for OCaml.
It transformes a very basic LL1 grammar definition into a fully featured parser
in OCaml.

## Grammar syntax

The parser is generated from a grammar file that consists in a list of
non-terminal definitions of the form:

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
It is just a pair `'a * Span.t` and can be deconstructed as such using a
pattern matching.

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
