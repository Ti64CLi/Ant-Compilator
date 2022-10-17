open CodeMap
open Unicode.UString

module Route : sig
  type t =
    | Rule of (Grammar.rule Span.located) * rule_route
    | Primitive
    | None
    | Nil

  and rule_route = t list
end

type error =
  | Ambiguity of Grammar.non_terminal * Grammar.Terminal.t option * Route.t * Route.t
  | RuleAmbiguity of Grammar.definition * Grammar.rule * Grammar.Terminal.t option * Route.rule_route * Route.rule_route
  | RuleInnerAmbiguity of Grammar.definition * Grammar.rule * int * Span.t * Grammar.Terminal.t * Route.t * int * Span.t
  | IterationAmbiguity of Grammar.definition * Grammar.rule * Grammar.simple_non_terminal * Grammar.Terminal.t * Route.t

exception Error of error Span.located

module TerminalOptMap : Map.S with type key = Grammar.Terminal.t option

type t = (Utf8String.t, Route.t TerminalOptMap.t) Hashtbl.t

val of_grammar : Grammar.t -> t

val first_terminals_of_simple_non_terminal : t -> Grammar.simple_non_terminal -> Route.t TerminalOptMap.t

val print_error : error -> Format.formatter -> unit
