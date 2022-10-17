open CodeMap
open Unicode.UString

module StringMap = Map.Make (Utf8String)
module TerminalSet = Set.Make (Grammar.Terminal)
module TerminalMap = Map.Make (Grammar.Terminal)
module TerminalOptMap = Map.Make (struct type t = Grammar.Terminal.t option let compare = compare end)

module RuleSet = Set.Make (struct type t = Grammar.rule let compare = compare end)

module Route = struct
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

type t = (Utf8String.t, Route.t TerminalOptMap.t) Hashtbl.t

let rec compute_first_terminals_of_non_terminal_def visited_rules nt (def, span) =
  let add terminal_opt route set =
    begin match TerminalOptMap.find_opt terminal_opt set with
      | Some route' ->
        raise (Error (Ambiguity (nt, terminal_opt, route', route), span))
      | None ->
        TerminalOptMap.add terminal_opt route set
    end
  in
  List.fold_right (
    fun (rule, span) set ->
      if RuleSet.mem rule visited_rules then
        set
      else begin
        let rule_terminals = compute_first_terminals_of_rule visited_rules def (rule, span) in
        TerminalOptMap.fold (
          fun terminal_opt rule_route set ->
            let route = Route.Rule ((rule, span), rule_route) in
            add terminal_opt route set
        ) rule_terminals set
      end
  ) def.Grammar.rules TerminalOptMap.empty

and compute_first_terminals_of_simple_non_terminal visited_rules nt (simple, span) =
  match simple with
  | Grammar.Primitive p ->
    TerminalOptMap.singleton (Some (Grammar.Terminal.Primitive p)) Route.Primitive
  | Grammar.Ref rnt ->
    let def = Option.get rnt.definition in
    compute_first_terminals_of_non_terminal_def visited_rules nt (def, span)

and compute_first_terminals_of_non_terminal visited_rules (nt, span) =
  let add terminal_opt route set =
    begin match TerminalOptMap.find_opt terminal_opt set with
      | Some route' ->
        raise (Error (Ambiguity (nt, terminal_opt, route', route), span))
      | None ->
        TerminalOptMap.add terminal_opt route set
    end
  in
  begin match nt with
    | Grammar.Simple s ->
      compute_first_terminals_of_simple_non_terminal visited_rules nt (s, span)
    | Grammar.Iterated (simple, sep, non_empty) ->
      let set = compute_first_terminals_of_simple_non_terminal visited_rules nt (simple, span) in
      let set = match TerminalOptMap.find_opt None set with
        | Some route ->
          add (Some sep) route set
        | None -> set
      in
      if non_empty then set else add None Route.Nil set
    | Grammar.Optional simple ->
      add None Route.None (compute_first_terminals_of_simple_non_terminal visited_rules nt (simple, span))
  end

and compute_first_terminals_of_rule visited_rules def (rule, span) =
  let visited_rules = RuleSet.add rule visited_rules in
  let add rule_route terminal_opt set =
    let rule_route = List.rev rule_route in
    begin match TerminalOptMap.find_opt terminal_opt set with
      | Some rule_route' ->
        raise (Error (RuleAmbiguity (def, rule, terminal_opt, rule_route, rule_route'), span))
      | None ->
        TerminalOptMap.add terminal_opt rule_route set
    end
  in
  let rec aux rule_route tokens set =
    match tokens with
    | [] -> add rule_route None set
    | (Grammar.Terminal terminal, _)::_ -> add rule_route (Some terminal) set
    | (Grammar.NonTerminal nt, span)::tokens' ->
      let firsts = compute_first_terminals_of_non_terminal visited_rules (nt, span) in
      TerminalOptMap.fold (
        fun terminal_opt route set ->
          match terminal_opt with
          | Some terminal -> add (route::rule_route) (Some terminal) set
          | None -> aux (route::rule_route) tokens' set
      ) firsts set
  in
  aux [] rule.tokens TerminalOptMap.empty

let first_terminals_of_simple_non_terminal table simple =
  begin match simple with
    | Grammar.Primitive p ->
      TerminalOptMap.singleton (Some (Grammar.Terminal.Primitive p)) Route.Primitive
    | Grammar.Ref nt ->
      let def = Option.get nt.definition in
      Hashtbl.find table def.Grammar.name
  end

let check_rule_ambiguities table def (rule, rule_span) =
  let first_terminals_of table nt =
    let add terminal_opt route set =
      TerminalOptMap.add terminal_opt route set
    in
    begin match nt with
      | Grammar.Simple simple ->
        first_terminals_of_simple_non_terminal table simple
      | Grammar.Iterated (nt, sep, non_empty) ->
        let set = first_terminals_of_simple_non_terminal table nt in
        let set = match TerminalOptMap.find_opt None set with
          | Some route ->
            add (Some sep) route set
          | None -> set
        in
        if non_empty then set else add None Route.Nil set
      | Grammar.Optional nt ->
        add None Route.None (first_terminals_of_simple_non_terminal table nt)
    end
  in
  let rec check i tokens =
    match tokens with
    | [] -> ()
    | (Grammar.Terminal _, _)::tokens' ->
      check (i + 1) tokens'
    | (Grammar.NonTerminal nt, span)::tokens' ->
      let rec check_no_collision i span terminal route offset tokens =
        match tokens with
        | [] -> ()
        | (Grammar.Terminal terminal', span')::_ ->
          if terminal = terminal' then
            raise (Error (RuleInnerAmbiguity (def, rule, i, span, terminal, route, offset, span'), rule_span))
        | (Grammar.NonTerminal nt, span')::tokens' ->
          let terminals = first_terminals_of table nt in
          begin match TerminalOptMap.find_opt (Some terminal) terminals with
            | Some route ->
              raise (Error (RuleInnerAmbiguity (def, rule, i, span, terminal, route, offset, span'), rule_span))
            | None ->
              begin match TerminalOptMap.find_opt None terminals with
                | Some route ->
                  check_no_collision i span terminal route (offset + 1) tokens'
                | None -> ()
              end
          end
      in
      begin match nt with
        | Iterated (nt, sep, _) ->
          let terminals = first_terminals_of_simple_non_terminal table nt in
          begin match TerminalOptMap.find_opt (Some sep) terminals with
            | Some route ->
              raise (Error (IterationAmbiguity (def, rule, nt, sep, route), span))
            | None -> ()
          end
        | _ -> ()
      end;
      let terminals = first_terminals_of table nt in
      if TerminalOptMap.mem None terminals then
        TerminalOptMap.iter (
          fun terminal_opt route ->
            match terminal_opt with
            | None -> ()
            | Some terminal ->
              check_no_collision i span terminal route 1 tokens'
        ) terminals;
      check (i + 1) tokens'
  in
  check 0 rule.tokens

let of_grammar g =
  let table = Hashtbl.create 8 in
  Grammar.iter (
    function (def, def_span) ->
      let nt = Grammar.Simple (Grammar.Ref {
          span = def_span;
          definition = Some def
        })
      in
      let nt_table = compute_first_terminals_of_non_terminal RuleSet.empty (nt, def_span) in
      Hashtbl.add table def.name nt_table
  ) g;
  Grammar.iter (
    function (def, _) ->
      List.iter (check_rule_ambiguities table def) def.Grammar.rules
  ) g;
  table

let print_error e fmt =
  match e with
  | Ambiguity (nt, None, _, _) ->
    Format.fprintf fmt "multiple ways to nullify `%t`" (Grammar.print_non_terminal nt)
  | Ambiguity (nt, Some terminal, _, _) ->
    Format.fprintf fmt "multiple ways to start `%t` with `%t`" (Grammar.print_non_terminal nt) (Grammar.Terminal.print terminal)
  | RuleAmbiguity (_, rule, None, _, _) ->
    Format.fprintf fmt "the following rule have multiple ways to be empty:\n%t" (Grammar.print_rule rule)
  | RuleAmbiguity (_, rule, Some terminal, _, _) ->
    Format.fprintf fmt "the following rule have multiple ways to start with %t:\n%t" (Grammar.Terminal.print terminal) (Grammar.print_rule rule)
  | RuleInnerAmbiguity (_, rule, _, _, _, _, _, _) ->
    Format.fprintf fmt "the following rule is ambiguous:\n%t" (Grammar.print_rule rule)
  | IterationAmbiguity (_, rule, _, _, _) ->
    Format.fprintf fmt "the following rule is ambiguous:\n%t" (Grammar.print_rule rule)
