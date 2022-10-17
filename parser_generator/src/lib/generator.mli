(* open CodeMap
open Unicode.UString *)

val generate_ast_interface : Grammar.t -> Format.formatter -> unit
(** Write the abstract syntax tree interface to the given output channel. *)

val generate_ast : Grammar.t -> Format.formatter -> unit
(** Write the abstract syntax tree to the given output channel. *)

val generate_lexer_interface : Grammar.t -> Format.formatter -> unit
(** Write the lexer interface to the given output channel. *)

val generate_lexer : Grammar.t -> Format.formatter -> unit
(** Write the lexer code to the given output channel. *)

val generate_parser_interface : Grammar.t -> Format.formatter -> unit
(** Write the parser interface to the given output channel. *)

val generate_parser : Grammar.t -> Format.formatter -> unit
(** Write the parser code to the given output channel. *)
