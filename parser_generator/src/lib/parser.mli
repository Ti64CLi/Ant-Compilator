open CodeMap

module SeqThen : sig
  type ('a, 'b) node =
    | Nil of 'b
    | Cons of 'a * ('a, 'b) t

  and ('a, 'b) t = unit -> ('a, 'b) node

  val fold_left : ('a -> 'b -> 'a) -> 'a -> ('b, 'c) t -> 'a * 'c
end

type error =
  | UnexpectedEOF
  | Unexpected of Lexer.token * (Lexer.token_kind list)

exception Error of error Span.located

val tokens : Lexer.t -> (Ast.token Span.located, Lexer.t) SeqThen.t

val rules : Lexer.t -> (Ast.rule Span.located, Lexer.t) SeqThen.t

val definitions : Lexer.t -> (Ast.definition Span.located, Lexer.t) SeqThen.t
(** Parse definitions. *)

val parse : Lexer.t -> Ast.grammar
(** Create a lexer from an unicode character sequence. *)

val print_error : error -> Format.formatter -> unit
