open CodeMap
open Unicode.UString

type non_terminal =
  | Ident of Utf8String.t
  | Iterated of Utf8String.t * Utf8String.t * bool
  | Optional of Utf8String.t

(** Token. *)
type token =
  | Terminal of Utf8String.t
  | NonTerminal of non_terminal

(** Non-terminal rule. *)
type rule = {
  constructor: Utf8String.t Span.located;
  tokens: token Span.located list
}

(** Non-terminal definition. *)
type definition = {
  name: Utf8String.t Span.located;
  rules: rule Span.located list
}

(** Grammar definition. *)
type grammar = definition Span.located list

val print : grammar -> Format.formatter -> unit

val print_definition : definition -> Format.formatter -> unit

val print_rule : rule -> Format.formatter -> unit

val print_token : token -> Format.formatter -> unit
