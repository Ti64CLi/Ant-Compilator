open CodeMap
open Unicode
open UString

module StringMap = Map.Make (Utf8String)

type error =
  | MultipleDefinitions of Utf8String.t * Span.t
  | UndefinedNonTerminal of Utf8String.t

exception Error of error Span.located

type primitive =
  | Int
  | Ident

module Terminal = struct
  type t =
    | Keyword of Utf8String.t
    | Begin of char
    | End of char
    | Operator of Utf8String.t
    | Primitive of primitive

  let is_indent name =
    let res, _ = Utf8String.fold_left (
        fun (res, non_first) c ->
          match res, non_first with
          | false, _ -> (false, true)
          | true, non_first ->
            if UChar.is_alphabetic c || (non_first && UChar.is_alphanumeric c) then
              (true, true)
            else
              (false, false)
      ) (true, false) name
    in
    res

  let of_string name =
    match name with
    | _ when is_indent name -> Keyword name
    | "{" -> Begin '{'
    | "[" -> Begin '['
    | "(" -> Begin '('
    | "}" -> End '}'
    | "]" -> End ']'
    | ")" -> End ')'
    | _ -> Operator name

  let compare = compare

  let print t out =
    match t with
    | Keyword name ->
      Format.fprintf out "%s" name
    | Begin c ->
      Format.fprintf out "%c" c
    | End c ->
      Format.fprintf out "%c" c
    | Operator name ->
      Format.fprintf out "%s" name
    | Primitive Int ->
      Format.fprintf out "<<int>>"
    | Primitive Ident ->
      Format.fprintf out "<<ident>>"
end

module TerminalSet = Set.Make (Terminal)

type token =
  | Terminal of Terminal.t
  | NonTerminal of non_terminal

and non_terminal =
  | Simple of simple_non_terminal
  | Iterated of simple_non_terminal * Terminal.t * bool
  | Optional of simple_non_terminal

and simple_non_terminal =
  | Ref of non_terminal_ref
  | Primitive of primitive

and non_terminal_ref = {
  span: Span.t;
  mutable definition: definition option
}

and rule = {
  constructor: Utf8String.t Span.located;
  tokens: token Span.located list
}

and definition = {
  name: Utf8String.t;
  rules: rule Span.located list
}

module NonTerminal = struct
  type t = non_terminal

  let print_simple t fmt =
    match t with
    | Primitive Int ->
      Format.fprintf fmt "<int>"
    | Primitive Ident ->
      Format.fprintf fmt "<ident>"
    | Ref nt ->
      Format.fprintf fmt "<%s>" (Option.get nt.definition).name

  let print t fmt =
    match t with
    | Simple s ->
      print_simple s fmt
    | Iterated (nt, sep, false) ->
      Format.fprintf fmt "<%t*%t>" (print_simple nt) (Terminal.print sep)
    | Iterated (nt, sep, true) ->
      Format.fprintf fmt "<%t+%t>" (print_simple nt) (Terminal.print sep)
    | Optional nt ->
      Format.fprintf fmt "<%t?>" (print_simple nt)

  let compare = compare
end

module NonTerminalSet = Set.Make (NonTerminal)

type t = (definition Span.located) StringMap.t

let simple_non_terminal_of_name table span name =
  begin match name with
    | "int" -> Primitive Int
    | "ident" -> Primitive Ident
    | _ ->
      begin match Hashtbl.find_opt table name with
        | Some nt -> Ref nt
        | None ->
          raise (Error (UndefinedNonTerminal name, span))
      end
  end

let token_of_ast table (token, span) =
  match token with
  | Ast.Terminal name ->
    Terminal (Terminal.of_string name), span
  | Ast.NonTerminal (Ast.Ident name) ->
    let nt = simple_non_terminal_of_name table span name in
    NonTerminal (Simple nt), span
  | Ast.NonTerminal (Ast.Iterated (name, sep, non_empty)) ->
    let nt = simple_non_terminal_of_name table span name in
    NonTerminal (Iterated (nt, (Terminal.of_string sep), non_empty)), span
  | Ast.NonTerminal (Ast.Optional name) ->
    let nt = simple_non_terminal_of_name table span name in
    NonTerminal (Optional nt), span

let rule_of_ast table ((ast, span) : Ast.rule Span.located) =
  {
    constructor = ast.constructor;
    tokens = List.map (token_of_ast table) ast.tokens
  }, span

let definition_of_ast table (ast, span) =
  {
    name = fst ast.Ast.name;
    rules = List.map (rule_of_ast table) ast.Ast.rules
  }, span

let of_ast ast =
  let table = Hashtbl.create (List.length ast) in
  (* Register non-terminals. *)
  List.iter (
    function (def_ast, span) ->
      let name = fst def_ast.Ast.name in
      begin match Hashtbl.find_opt table name with
        | Some nt -> raise (Error (MultipleDefinitions (name, nt.span), span))
        | None ->
          Hashtbl.replace table name { span = span; definition = None }
      end
  ) ast;
  (* Compile non-terminals. *)
  List.iter (
    function (def_ast, span) ->
      let name = fst def_ast.Ast.name in
      let nt = Hashtbl.find table name in
      let def, _ = definition_of_ast table (def_ast, span) in
      nt.definition <- Some def
  ) ast;
  (* Building the grammar. *)
  Hashtbl.fold (
    fun name nt g ->
      StringMap.add name (Option.get nt.definition, nt.span) g
  ) table StringMap.empty

let fold f t accu =
  StringMap.fold (fun _ def accu -> f def accu) t accu

let iter f t =
  fold (fun def () -> f def) t ()

let non_terminals t =
  StringMap.fold (fun _ (def, span) set ->
      let nt = Simple (Ref { span = span; definition = Some def }) in
      let set = NonTerminalSet.add nt set in
      List.fold_right (fun (rule, _) set ->
          List.fold_right (
            fun (token, _) set ->
              match token with
              | Terminal _ -> set
              | NonTerminal nt ->
                NonTerminalSet.add nt set
          ) rule.tokens set
        ) def.rules set
    ) t NonTerminalSet.empty

let fold_non_terminals f t accu =
  NonTerminalSet.fold f (non_terminals t) accu

let iter_non_terminals f t =
  fold_non_terminals (fun nt () -> f nt) t ()

let terminals t =
  let raw_terminals = StringMap.fold (fun _ (def, _) set ->
      List.fold_right (fun (rule, _) set ->
          List.fold_right (
            fun (token, _) set ->
              match token with
              | Terminal t ->
                TerminalSet.add t set
              | NonTerminal _ -> set
          ) rule.tokens set
        ) def.rules set
    ) t TerminalSet.empty
  in
  let process_simple_nt nt set =
    match nt with
    | Primitive p ->
      TerminalSet.add (Terminal.Primitive p) set
    | _ -> set
  in
  fold_non_terminals (
    fun nt set ->
      match nt with
      | Simple s ->
        process_simple_nt s set
      | Iterated (s, sep, _) ->
        TerminalSet.add sep (process_simple_nt s set)
      | Optional s ->
        process_simple_nt s set
  ) t raw_terminals

let fold_terminals f t accu =
  TerminalSet.fold f (terminals t) accu

let iter_terminals f t =
  fold_terminals (fun nt () -> f nt) t ()

let rule_args rule =
  List.filter_map (
    function
    | NonTerminal nt, _ -> Some nt
    | _ -> None
  ) rule.tokens

let print_token token fmt =
  match token with
  | Terminal terminal ->
    Terminal.print terminal fmt
  | NonTerminal nt ->
    NonTerminal.print nt fmt

let print_rule rule fmt =
  Format.fprintf fmt "| %s " (fst rule.constructor);
  List.iter (
    function (token, _) ->
      Format.fprintf fmt "%t " (print_token token)
  ) rule.tokens

let print_definition def fmt =
  Format.fprintf fmt "<%s> ::= \n" def.name;
  List.iter (
    function (rule, _) ->
      Format.fprintf fmt "\t%t\n" (print_rule rule)
  ) def.rules

let print_non_terminal =
  NonTerminal.print

let print g fmt =
  StringMap.iter (
    fun _ (definition, _) ->
      print_definition definition fmt
  ) g

let print_error e fmt =
  match e with
  | MultipleDefinitions (name, _) ->
    Format.fprintf fmt "multiple definitions of non-terminal `%s`" name
  | UndefinedNonTerminal name ->
    Format.fprintf fmt "undefined non-terminal `%s`" name
