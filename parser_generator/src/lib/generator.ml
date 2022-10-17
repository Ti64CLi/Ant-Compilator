open Unicode.UString

module CharSet = Set.Make (Char)
module StringSet = Set.Make (Utf8String)
module StringMap = Map.Make (Utf8String)
module TerminalSet = Set.Make (Grammar.Terminal)
module TerminalMap = Map.Make (Grammar.Terminal)
module TerminalOptMap = ParseTable.TerminalOptMap
module Route = ParseTable.Route

module RuleSet = Set.Make (struct type t = Grammar.rule let compare = compare end)
module RuleMap = Map.Make (struct type t = Grammar.rule let compare = compare end)

let constructor name =
  let buffer = Bytes.of_string name in
  let c = Char.code (Bytes.get buffer 0) in
  if c >= 0x61 && c <= 0x7a then
    Bytes.set buffer 0 (Char.chr (c - 0x20));
  Bytes.to_string buffer

let generate_simple_non_terminal_type nt fmt =
  match nt with
  | Grammar.Primitive Grammar.Int ->
    Format.fprintf fmt "int"
  | Grammar.Primitive Grammar.Ident ->
    Format.fprintf fmt "string"
  | Grammar.Ref r ->
    let def = Option.get r.definition in
    Format.fprintf fmt "%s" def.Grammar.name

let generate_non_terminal_type nt fmt =
  match nt with
  | Grammar.Simple s ->
    Format.fprintf fmt "(%t Span.located)" (generate_simple_non_terminal_type s)
  | Grammar.Iterated (s, _, _) ->
    Format.fprintf fmt "(%t Span.located list Span.located)" (generate_simple_non_terminal_type s)
  | Grammar.Optional s ->
    Format.fprintf fmt "(%t option Span.located)" (generate_simple_non_terminal_type s)

let generate_definition_declaration is_rec def fmt =
  let name = def.Grammar.name in
  if is_rec then
    Format.fprintf fmt "and %s = \n" name
  else
    Format.fprintf fmt "type %s = \n" name;
  List.iter (
    function (rule, _) ->
      let args = Grammar.rule_args rule in
      if args = [] then
        Format.fprintf fmt "| %s\n" (fst rule.constructor)
      else begin
        let rec generate_args args fmt =
          match args with
          | [] -> ()
          | a::[] ->
            Format.fprintf fmt "%t" (generate_non_terminal_type a)
          | a::args ->
            Format.fprintf fmt "%t * %t" (generate_non_terminal_type a) (generate_args args)
        in
        Format.fprintf fmt "| %s of %t\n" (fst rule.constructor) (generate_args args)
      end
  ) def.rules;
  Format.fprintf fmt "\n"

let generate_primitive_pattern p fmt =
  match p with
  | Grammar.Int ->
    Format.fprintf fmt "Lexer.Int _"
  | Grammar.Ident ->
    Format.fprintf fmt "Lexer.Ident _"

let generate_terminal t fmt =
  match t with
  | Grammar.Terminal.Keyword name ->
    Format.fprintf fmt "Lexer.Keyword Lexer.Keyword.%s" (constructor name)
  | Grammar.Terminal.Begin c ->
    Format.fprintf fmt "Lexer.Begin '%c'" c
  | Grammar.Terminal.End c ->
    Format.fprintf fmt "Lexer.End '%c'" c
  | Grammar.Terminal.Operator op ->
    Format.fprintf fmt "Lexer.Operator \"%s\"" op
  | Grammar.Terminal.Primitive p ->
    generate_primitive_pattern p fmt

let generate_definition_function_name def fmt =
  let name = def.Grammar.name in
  Format.fprintf fmt "parse_nt_%s" name

let generate_definition_printer_function_name def fmt =
  let name = def.Grammar.name in
  Format.fprintf fmt "print_nt_%s" name

let generate_simple_non_terminal_function_name nt fmt =
  match nt with
  | Grammar.Primitive Int ->
    Format.fprintf fmt "parse_int"
  | Grammar.Primitive Ident ->
    Format.fprintf fmt "parse_ident"
  | Grammar.Ref r ->
    let def = Option.get r.definition in
    generate_definition_function_name def fmt

let generate_simple_non_terminal_printer_function_name nt fmt =
  match nt with
  | Grammar.Primitive Int ->
    Format.fprintf fmt "print_int"
  | Grammar.Primitive Ident ->
    Format.fprintf fmt "print_ident"
  | Grammar.Ref r ->
    let def = Option.get r.definition in
    generate_definition_printer_function_name def fmt

let generate_non_terminal_function_name nt fmt =
  match nt with
  | Grammar.Simple s ->
    generate_simple_non_terminal_function_name s fmt
  | Grammar.Iterated (s, sep, false) ->
    Format.fprintf fmt "iter_%t (%t)" (generate_simple_non_terminal_function_name s) (generate_terminal sep)
  | Grammar.Iterated (s, sep, true) ->
    Format.fprintf fmt "non_empty_iter_%t (%t)" (generate_simple_non_terminal_function_name s) (generate_terminal sep)
  | Grammar.Optional s ->
    Format.fprintf fmt "opt_%t" (generate_simple_non_terminal_function_name s)

let generate_non_terminal_printer_function_name nt fmt =
  match nt with
  | Grammar.Simple s ->
    generate_simple_non_terminal_printer_function_name s fmt
  | Grammar.Iterated (s, sep, false) ->
    Format.fprintf fmt "iter_%t (%t)" (generate_simple_non_terminal_printer_function_name s) (generate_terminal sep)
  | Grammar.Iterated (s, sep, true) ->
    Format.fprintf fmt "non_empty_iter_%t (%t)" (generate_simple_non_terminal_printer_function_name s) (generate_terminal sep)
  | Grammar.Optional s ->
    Format.fprintf fmt "opt_%t" (generate_simple_non_terminal_printer_function_name s)

let generate_definition_parser table def fmt =
  let name = def.Grammar.name in
  Format.fprintf fmt "and %t span lexer = \n" (generate_definition_function_name def);
  Format.fprintf fmt "match lexer () with ";
  let nt_table = Hashtbl.find table name in
  let add_terminal terminal_opt rule rule_table =
    match RuleMap.find_opt rule rule_table with
    | Some terminals -> RuleMap.add rule (terminal_opt::terminals) rule_table
    | None -> RuleMap.add rule [terminal_opt] rule_table
  in
  let rule_table = TerminalOptMap.fold (
      fun terminal_opt route rule_table ->
        match route with
        | Route.Rule ((rule, _), _) ->
          add_terminal terminal_opt rule rule_table
        | _ -> rule_table
    ) nt_table RuleMap.empty
  in
  let rec generate_tokens rule arg_count tokens =
    match tokens with
    | [] ->
      if arg_count = 0 then
        Format.fprintf fmt "(Ast.%s, span), lexer\n" (fst rule.Grammar.constructor)
      else begin
        let rec print_args n fmt =
          if n = 0 then
            Format.fprintf fmt "arg0"
          else begin
            Format.fprintf fmt "%t, arg%d" (print_args (n - 1)) n
          end
        in
        Format.fprintf fmt "(Ast.%s (%t), span), lexer\n" (fst rule.constructor) (print_args (arg_count - 1))
      end
    | (Grammar.Terminal terminal, _)::tokens' ->
      Format.fprintf fmt "begin match consume span lexer with \n";
      Format.fprintf fmt "| (%t, _), span, lexer -> \n" (generate_terminal terminal);
      generate_tokens rule arg_count tokens';
      Format.fprintf fmt "| (token, token_span), _, _ -> raise (Error (UnexpectedToken token, token_span))\n";
      (* Format.fprintf fmt "| None, span -> raise (Error (UnexpectedEOF, span))\n"; *)
      Format.fprintf fmt "end\n"
    | (Grammar.NonTerminal nt, _)::tokens' ->
      let i = arg_count in
      Format.fprintf fmt "let arg%d, lexer = %t (Span.next span) lexer in \n" i (generate_non_terminal_function_name nt);
      Format.fprintf fmt "let span = Span.union span (snd arg%d) in \n" i;
      generate_tokens rule (arg_count + 1) tokens'
  in
  RuleMap.iter (
    fun rule terminals ->
      if terminals = [] then failwith "non-spotted empty rule";
      if List.mem None terminals then () else begin
        List.iter (
          function
          | Some terminal ->
            Format.fprintf fmt "\n| Seq.Cons ((%t, _), _) " (generate_terminal terminal)
          | None ->
            Format.fprintf fmt "\n| _ "
        ) terminals;
        Format.fprintf fmt " -> \n";
        generate_tokens rule 0 rule.tokens
      end
  ) rule_table;
  RuleMap.iter (
    fun rule terminals ->
      if List.mem None terminals then begin
        List.iter (
          function
          | Some terminal ->
            Format.fprintf fmt "\n| Seq.Cons ((%t, _), _) " (generate_terminal terminal)
          | None ->
            Format.fprintf fmt "\n| _ "
        ) terminals;
        Format.fprintf fmt " -> \n";
        generate_tokens rule 0 rule.tokens
      end else ()
  ) rule_table;
  begin match TerminalOptMap.find_first_opt Option.is_none nt_table with
    | Some (_, _) -> ()
    | None ->
      Format.fprintf fmt "| Seq.Cons ((token, token_span), _) -> raise (Error (UnexpectedToken token, token_span))\n";
      Format.fprintf fmt "| Seq.Nil -> raise (Error (UnexpectedEOF, span))\n"
  end;
  Format.fprintf fmt "@."

let generate_definition_printer def fmt =
  (* let name = def.Grammar.name in *)
  let has_non_terminal = List.exists (
      function (rule, _) ->
        Grammar.rule_args rule != []
    ) def.Grammar.rules
  in
  Format.fprintf fmt "and %t %s t out = \n" (generate_definition_printer_function_name def) (if has_non_terminal then "indent" else "_");
  Format.fprintf fmt "match t with\n";
  List.iter (
    function (rule, _) ->
      let args = Grammar.rule_args rule in
      if args = [] then
        Format.fprintf fmt "| %s -> Printf.fprintf out \"" (fst rule.constructor)
      else begin
        let rec print_args n fmt =
          match n with
          | 0 -> ()
          | 1 -> Format.fprintf fmt "(arg0, _)"
          | n -> Format.fprintf fmt "%t, (arg%d, _)" (print_args (n-1)) (n-1)
        in
        Format.fprintf fmt "| %s (%t) -> Printf.fprintf out \"" (fst rule.constructor) (print_args (List.length args))
      end;
      ignore (List.fold_left (
        fun i token ->
          (* let sep = if i = 0 then "" else " " in *)
          begin match token with
          | (Grammar.Terminal t, _) ->
            Format.fprintf fmt "%t " (Grammar.Terminal.print t)
          | (Grammar.NonTerminal (Grammar.Iterated (_, _, _)), _) ->
            Format.fprintf fmt "%%t"
          | (Grammar.NonTerminal _, _) ->
            Format.fprintf fmt "%%t"
          end;
          i + 1
      ) 0 rule.tokens);
      Format.fprintf fmt "\" ";
      ignore (List.fold_left (
          fun i (token, _) ->
            match token with
            | Grammar.NonTerminal nt ->
              Format.fprintf fmt "(%t indent arg%d) " (generate_non_terminal_printer_function_name nt) i;
              i + 1
            | _ -> i
        ) 0 rule.tokens);
      Format.fprintf fmt "\n"
  ) def.rules;
  Format.fprintf fmt "\n"

let generate_simple_non_terminal_parser table nt fmt =
  match nt with
  | Grammar.Primitive Grammar.Int ->
    Format.fprintf fmt "and parse_int span lexer =
  match lexer () with
  | Seq.Cons ((Int i, token_span), lexer) -> (i, token_span), lexer
  | Seq.Cons ((token, token_span), _) -> raise (Error (UnexpectedToken token, token_span))
  | Seq.Nil -> raise (Error (UnexpectedEOF, span))

  "
  | Grammar.Primitive Grammar.Ident ->
    Format.fprintf fmt "and parse_ident span lexer =
  match lexer () with
  | Seq.Cons ((Ident name, token_span), lexer) -> (name, token_span), lexer
  | Seq.Cons ((token, token_span), _) -> raise (Error (UnexpectedToken token, token_span))
  | Seq.Nil -> raise (Error (UnexpectedEOF, span))

  "
  | Grammar.Ref r ->
    generate_definition_parser table (Option.get r.definition) fmt

let generate_simple_non_terminal_printer nt fmt =
  match nt with
  | Grammar.Primitive Grammar.Int ->
    Format.fprintf fmt "and print_int _ t out =
  Printf.fprintf out \"%%d \" t

"
  | Grammar.Primitive Grammar.Ident ->
    Format.fprintf fmt "and print_ident _ t out =
  Printf.fprintf out \"%%s \" t

"
  | Grammar.Ref r ->
    generate_definition_printer (Option.get r.definition) fmt

let generate_non_terminal_parser defined_functions table nt fmt =
  match nt with
  | Grammar.Simple s ->
    generate_simple_non_terminal_parser table s fmt
  | Grammar.Iterated (s, _, true) ->
    let name = Format.asprintf "non_empty_iter_%t" (generate_simple_non_terminal_function_name s) in
    if Hashtbl.mem defined_functions name then () else begin
      Hashtbl.add defined_functions name ();
      Format.fprintf fmt "and %s sep span lexer =
  let item, lexer = %t span lexer in
  match lexer () with
  | Seq.Cons ((token, token_span), lexer) when token = sep ->
    let span = Span.union token_span (snd item) in
    let (items, span'), lexer = %s sep (Span.next span) lexer in
    let span = Span.union span span' in
    (item::items, span), lexer
  | _ -> ([item], snd item), lexer

"
        name
        (generate_simple_non_terminal_function_name s)
        name
    end
  | Grammar.Iterated (s, _, false) ->
    let name = Format.asprintf "iter_%t" (generate_simple_non_terminal_function_name s) in
    let terminals = ParseTable.first_terminals_of_simple_non_terminal table s in
    Format.fprintf fmt "and %s sep span lexer = \n" name;
    Format.fprintf fmt "  begin match lexer () with";
    TerminalOptMap.iter (
      fun terminal_opt _ ->
        match terminal_opt with
        | Some terminal ->
          Format.fprintf fmt "\n    | Seq.Cons ((%t, _), _) " (generate_terminal terminal)
        | None ->
          Format.fprintf fmt "\n    | Seq.Cons ((token, _), _) when token = sep"
    ) terminals;
    Format.fprintf fmt "->\n";
    Format.fprintf fmt "      let item, lexer = %t span lexer in\n" (generate_simple_non_terminal_function_name s);
    Format.fprintf fmt "      begin match lexer () with
        | Seq.Cons ((token, token_span), lexer) when token = sep ->
          let span = Span.union token_span (snd item) in
          let (items, span'), lexer = %s sep (Span.next span) lexer in
          let span = Span.union span span' in
          (item::items, span), lexer
        | _ -> ([item], snd item), lexer
      end
    | _ ->
      ([], span), lexer
  end

" name
  | Grammar.Optional s ->
    let terminals = ParseTable.first_terminals_of_simple_non_terminal table s in
    Format.fprintf fmt "and opt_%t span lexer = \n" (generate_simple_non_terminal_function_name s);
    Format.fprintf fmt "  begin match lexer () with";
    TerminalOptMap.iter (
      fun terminal_opt _ ->
        match terminal_opt with
        | Some terminal ->
          Format.fprintf fmt "\n    | Seq.Cons ((%t, _), _) " (generate_terminal terminal)
        | None ->
          failwith "non-spotted ambiguity"
    ) terminals;
    Format.fprintf fmt "->\n";
    Format.fprintf fmt "      let (item, span), lexer = %t span lexer in\n" (generate_simple_non_terminal_function_name s);
    Format.fprintf fmt "      (Some item, span), lexer
    | _ ->
      (None, span), lexer
  end

"

let generate_non_terminal_printer defined_functions nt fmt =
  match nt with
  | Grammar.Simple s ->
    generate_simple_non_terminal_printer s fmt
  | Grammar.Iterated (s, _, true) ->
    let sname = Format.asprintf "%t" (generate_simple_non_terminal_printer_function_name s) in
    let name = Format.asprintf "non_empty_iter_%s" sname in
    if Hashtbl.mem defined_functions name then () else begin
      Hashtbl.add defined_functions name ();
      Format.fprintf fmt "and %s sep indent l out =
  Printf.fprintf out \"\n\";
  let rec print l out =
    match l with
    | [] -> ()
    | (e, _)::[] ->
      print__indent (indent + 1) out;
      %s (indent + 1) e out
    | (e, _)::l ->
      print__indent (indent + 1) out;
      Printf.fprintf out \"%%t%%t\\n\" (%s (indent + 1) e) (Lexer.print_token sep);
      print l out
  in
  print l out;
  Printf.fprintf out \"\n\";
  print__indent indent out

"
        name
        sname
        sname
    end
  | Grammar.Iterated (s, _, false) ->
    let sname = Format.asprintf "%t" (generate_simple_non_terminal_printer_function_name s) in
    let name = Format.asprintf "iter_%s" sname in
    if Hashtbl.mem defined_functions name then () else begin
      Hashtbl.add defined_functions name ();
      Format.fprintf fmt "and %s sep indent l out =
  if l = [] then () else begin
    Printf.fprintf out \"\n\";
    let rec print l out =
      match l with
      | [] -> ()
      | (e, _)::[] ->
        print__indent (indent + 1) out;
        %s (indent + 1) e out
      | (e, _)::l ->
        print__indent (indent + 1) out;
        Printf.fprintf out \"%%t%%t\\n\" (%s (indent + 1) e) (Lexer.print_token sep);
        print l out
    in
    print l out;
    Printf.fprintf out \"\n\";
    print__indent indent out
  end

"
        name
        sname
        sname
    end
  | Grammar.Optional s ->
    let sname = Format.asprintf "%t" (generate_simple_non_terminal_printer_function_name s) in
    Format.fprintf fmt "and opt_%s indent e_opt out =
  match e_opt with
  | Some e -> %s indent e out
  | None -> ()

"
      sname
      sname

module TokenKind = struct
  type t =
    | Keyword
    | Begin
    | End
    | Operator
    | Primitive of Grammar.primitive

  let compare = compare
end

module TokenKindSet = Set.Make (TokenKind)

let terminal_kinds g =
  Grammar.fold_terminals (
    fun t set ->
      let kind = match t with
        | Grammar.Terminal.Keyword _ -> TokenKind.Keyword
        | Grammar.Terminal.Begin _ -> TokenKind.Begin
        | Grammar.Terminal.End _ -> TokenKind.End
        | Grammar.Terminal.Operator _ -> TokenKind.Operator
        | Grammar.Terminal.Primitive p -> TokenKind.Primitive p
      in
      TokenKindSet.add kind set
  ) g TokenKindSet.empty

let terminal_keywords g =
  Grammar.fold_terminals (
    fun t set ->
      match t with
      | Grammar.Terminal.Keyword name -> StringSet.add name set
      | _ -> set
  ) g StringSet.empty

let terminal_operators g =
  Grammar.fold_terminals (
    fun t set ->
      match t with
      | Grammar.Terminal.Operator name -> StringSet.add name set
      | _ -> set
  ) g StringSet.empty

let terminal_delimiters g =
  Grammar.fold_terminals (
    fun t set ->
      match t with
      | Grammar.Terminal.Begin d -> CharSet.add d set
      | Grammar.Terminal.End d -> CharSet.add d set
      | _ -> set
  ) g CharSet.empty

let generate_ast g fmt =
  Format.fprintf fmt "open CodeMap\n\n";
  ignore (Grammar.fold (
      fun (def, _) is_rec ->
        generate_definition_declaration is_rec def fmt;
        true
    ) g false);
  Format.fprintf fmt "let rec print__indent n out =
    if n <= 0 then () else begin
      Printf.fprintf out \"  \";
      print__indent (n-1) out
    end

  ";
  let defined_functions = Hashtbl.create 8 in
  Grammar.iter_non_terminals (
    function nt ->
      generate_non_terminal_printer defined_functions nt fmt
  ) g;
  Grammar.iter (
    function (def, _) ->
      let name = def.Grammar.name in
      Format.fprintf fmt "let print_%s = %t 0\n\n" name (generate_definition_printer_function_name def)
  ) g

let generate_ast_interface g fmt =
  Format.fprintf fmt "open CodeMap\n\n";
  ignore (Grammar.fold (
      fun (def, _) is_rec ->
        generate_definition_declaration is_rec def fmt;
        true
    ) g false);
  Grammar.iter (
    function (def, _) ->
      let name = def.Grammar.name in
      Format.fprintf fmt "val print_%s : %s -> out_channel -> unit\n" name name
  ) g

let generate_lexer_token_type g out =
  let kinds = terminal_kinds g in
  Format.fprintf out "type token = \n";
  TokenKindSet.iter (
    function
    | TokenKind.Keyword -> Format.fprintf out "| Keyword of Keyword.t \n"
    | TokenKind.Begin -> Format.fprintf out "| Begin of char \n"
    | TokenKind.End -> Format.fprintf out "| End of char \n"
    | TokenKind.Operator -> Format.fprintf out "| Operator of Utf8String.t \n"
    | TokenKind.Primitive Grammar.Int -> Format.fprintf out "| Int of int \n"
    | TokenKind.Primitive Grammar.Ident -> Format.fprintf out "| Ident of Utf8String.t \n"
  ) kinds;
  Format.fprintf out "\n";
  kinds

let generate_lexer_token_printer kinds out =
  Format.fprintf out "let print_token t fmt = \n";
  Format.fprintf out "  match t with \n";
  TokenKindSet.iter (
    function
    | TokenKind.Keyword -> Format.fprintf out "| Keyword kw -> Keyword.print kw fmt\n"
    | TokenKind.Begin -> Format.fprintf out "| Begin d -> Printf.fprintf fmt \"%%c\" d \n"
    | TokenKind.End -> Format.fprintf out "| End d -> Printf.fprintf fmt \"%%c\" d \n"
    | TokenKind.Operator -> Format.fprintf out "| Operator name -> Printf.fprintf fmt \"%%s\" name \n"
    | TokenKind.Primitive Grammar.Int -> Format.fprintf out "| Int i -> Printf.fprintf fmt \"%%d\" i \n"
    | TokenKind.Primitive Grammar.Ident -> Format.fprintf out "| Ident name -> Printf.fprintf fmt \"%%s\" name \n"
  ) kinds;
  Format.fprintf out "\n";
  Format.fprintf out "let print_token_debug t fmt = \n";
  Format.fprintf out "  match t with \n";
  TokenKindSet.iter (
    function
    | TokenKind.Keyword -> Format.fprintf out "| Keyword kw -> Printf.fprintf fmt \"keyword `%%t`\" (Keyword.print kw)\n"
    | TokenKind.Begin -> Format.fprintf out "| Begin d -> Printf.fprintf fmt \"opening `%%c`\" d \n"
    | TokenKind.End -> Format.fprintf out "| End d -> Printf.fprintf fmt \"closing `%%c`\" d \n"
    | TokenKind.Operator -> Format.fprintf out "| Operator name -> Printf.fprintf fmt \"operator `%%s`\" name \n"
    | TokenKind.Primitive Grammar.Int -> Format.fprintf out "| Int i -> Printf.fprintf fmt \"integer `%%d`\" i \n"
    | TokenKind.Primitive Grammar.Ident -> Format.fprintf out "| Ident name -> Printf.fprintf fmt \"identifier `%%s`\" name \n"
  ) kinds;
  Format.fprintf out "\n"

let generate_lexer_keyword_type keywords out =
  Format.fprintf out "type t = \n";
  StringSet.iter (
    function name ->
      Format.fprintf out "  | %s \n" (constructor name)
  ) keywords

let generate_lexer_keyword_printer keywords out =
  Format.fprintf out "let print t fmt = \n";
  Format.fprintf out "  match t with \n";
  StringSet.iter (
    function name -> Format.fprintf out "   | %s -> Printf.fprintf fmt \"%s\" \n" (constructor name) name
  ) keywords;
  Format.fprintf out "\n"

let generate_lexer_int fmt =
  Format.fprintf fmt "let int_opt str =
  match int_of_string_opt str with
  | Some i -> Some (Int i)
  | None -> None

"

let generate_lexer_delimiters g fmt =
  let delimiters = terminal_delimiters g in
  if CharSet.is_empty delimiters then
    Format.fprintf fmt "let delimiter_opt _ = None\n\n"
  else begin
    Format.fprintf fmt "let delimiter_opt str =
                                                              match str with\n";
    CharSet.iter (
      function
      | '(' -> Format.fprintf fmt "  | \"(\" -> Some (Begin '(')\n"
      | '[' -> Format.fprintf fmt "  | \"[\" -> Some (Begin '[')\n"
      | '{' -> Format.fprintf fmt "  | \"{\" -> Some (Begin '{')\n"
      | ')' -> Format.fprintf fmt "  | \")\" -> Some (End ')')\n"
      | ']' -> Format.fprintf fmt "  | \"]\" -> Some (End ']')\n"
      | '}' -> Format.fprintf fmt "  | \"}\" -> Some (End '}')\n"
      | _ -> failwith "invalid delimiter"
    ) delimiters;
    Format.fprintf fmt " | _ -> None

"
  end

let generate_lexer_keywords g fmt =
  let keywords = terminal_keywords g in
  if StringSet.is_empty keywords then
    Format.fprintf fmt "let keyword_opt _ = None\n\n"
  else begin
    Format.fprintf fmt "let keyword_opt str =
match str with\n";
    StringSet.iter (
      function name ->
        Format.fprintf fmt "  | \"%s\" -> Some (Keyword Keyword.%s)\n" name (constructor name)
    ) keywords;
    Format.fprintf fmt " | _ -> None

"
  end

let generate_lexer_operators g fmt =
  let operators = terminal_operators g in
  if StringSet.is_empty operators then
    Format.fprintf fmt "let operator_opt _ = None\n\n"
  else begin
    Format.fprintf fmt "let operator_opt str =
match str with\n";
    StringSet.iter (
      function name ->
        Format.fprintf fmt "  | \"%s\" -> Some (Operator \"%s\")\n" name name
    ) operators;
    Format.fprintf fmt " | _ -> None

"
  end

let generate_lexer_ident fmt =
  Format.fprintf fmt "let ident_opt str =
let res, _ = Utf8String.fold_left (
    fun accu c ->
      match accu with
      | false, _ -> false, true
      | true, not_first ->
        if UChar.is_alphabetic c || (not_first && UChar.is_numeric c) then
          (true, true)
        else
          (false, true)
  ) (true, false) str
in
if res then Some (Ident str) else None

"

let generate_lexer_errors fmt =
  Format.fprintf fmt "type error = UnknownToken of Utf8String.t

exception Error of error CodeMap.Span.located

"

let generate_lexer_interface g fmt =
  Format.fprintf fmt "open Unicode\n";
  Format.fprintf fmt "open UString\n\n";
  let keywords = terminal_keywords g in
  if StringSet.is_empty keywords then () else
    Format.fprintf fmt "module Keyword : sig\n  %t  val print : t -> out_channel -> unit\nend\n\n" (generate_lexer_keyword_type keywords);
  ignore (generate_lexer_token_type g fmt);
  Format.fprintf fmt "val print_token : token -> out_channel -> unit\n";
  Format.fprintf fmt "val print_token_debug : token -> out_channel -> unit\n\n";
  generate_lexer_errors fmt;
  Format.fprintf fmt "val print_error : error -> out_channel -> unit\n\n";
  Format.fprintf fmt "type t = token CodeMap.Span.located Seq.t\n\n";
  Format.fprintf fmt "val create : UChar.t Seq.t -> t\n";
  Format.fprintf fmt "val of_channel : in_channel -> t\n"

let generate_lexer g fmt =
  Format.fprintf fmt "open CodeMap\n";
  Format.fprintf fmt "open Unicode\n";
  Format.fprintf fmt "open UString\n\n";
  let keywords = terminal_keywords g in
  if StringSet.is_empty keywords then () else
    Format.fprintf fmt "module Keyword = struct\n  %t  %t\nend\n\n" (generate_lexer_keyword_type keywords) (generate_lexer_keyword_printer keywords);
  let kinds = generate_lexer_token_type g fmt in
  generate_lexer_token_printer kinds fmt;
  generate_lexer_errors fmt;
  Format.fprintf fmt "let print_error e fmt =
  match e with
  | UnknownToken name -> Printf.fprintf fmt \"unknown token `%%s`\" name

";
  Format.fprintf fmt "type t = token CodeMap.Span.located Seq.t\n\n";

  generate_lexer_delimiters g fmt;
  generate_lexer_keywords g fmt;
  generate_lexer_operators g fmt;

  if TokenKindSet.mem (TokenKind.Primitive Grammar.Int) kinds then
    generate_lexer_int fmt
  else
    Format.fprintf fmt "let int_opt _ = None\n\n";

  if TokenKindSet.mem (TokenKind.Primitive Grammar.Ident) kinds then
    generate_lexer_ident fmt
  else
    Format.fprintf fmt "let ident_opt _ = None\n\n";

  Format.fprintf fmt "let token_of_buffer span str =
  match delimiter_opt str with
  | Some token -> token
  | None ->
    begin match int_opt str with
    | Some token -> token
    | None ->
      begin match keyword_opt str with
        | Some token -> token
        | None ->
          begin match ident_opt str with
            | Some token -> token
            | None ->
              begin match operator_opt str with
                | Some token -> token
                | None ->
                  raise (Error (UnknownToken str, span))
              end
          end
      end
  end

";
  Format.fprintf fmt "let consume span chars =
  begin match chars () with
    | Seq.Nil -> (span, Seq.Nil)
    | Seq.Cons (c, chars) ->
      (* Add [c] to the [span]. *)
      let span = Span.push c span in
      (span, Seq.Cons (c, chars))
  end

let create input =
  let rec next span chars () =
    begin match consume span chars with
      | _, Seq.Nil -> Seq.Nil
      | span, Seq.Cons (c, chars) ->
        begin match UChar.to_int c with
          | 0x28 | 0x29 |0x5b | 0x5d | 0x7b | 0x7d -> (* ( ) [ ] { } *)
            return span chars (Utf8String.push c \"\")
          | _ when UChar.is_whitespace c || UChar.is_control c ->
            next (Span.next span) chars ()
          | _ when UChar.is_alphanumeric c ->
            read_alphanumeric span (c, chars)
          | _ ->
            read_operator span (c, chars)
        end
    end
  and return span chars buffer =
    let token = token_of_buffer span buffer in
    Seq.Cons (Span.located span token, next (Span.next span) chars)
  and read_alphanumeric span (c, chars) =
    let rec read span chars buffer =
      match consume span chars with
      | _, Seq.Nil -> return span chars buffer
      | span', Seq.Cons (c, chars') ->
        if UChar.is_whitespace c || UChar.is_control c || not (UChar.is_alphanumeric c) then
          return span chars buffer
        else
          read span' chars' (Utf8String.push c buffer)
    in
    read span chars (Utf8String.push c \"\")
  and read_operator span (c, chars) =
      let rec read span chars buffer =
        match consume span chars with
        | _, Seq.Nil -> return span chars buffer
        | span', Seq.Cons (c, chars') ->
          begin match UChar.to_int c with
            | 0x28 | 0x29 |0x5b | 0x5d | 0x7b | 0x7d -> (* ( ) [ ] { } *)
              return span chars buffer
            | _ when UChar.is_whitespace c || UChar.is_control c || UChar.is_alphanumeric c ->
              return span chars buffer
            | _ ->
              read span' chars' (Utf8String.push c buffer)
          end
      in
      read span chars (Utf8String.push c \"\")
  in
  next Span.default input

(* Create a sequence of chars from an input channel. *)
let seq_of_channel input =
  let rec next mem () =
    match !mem with
    | Some res -> res
    | None ->
      let res =
        try
          let c = input_char input in
          Seq.Cons (c, next (ref None))
        with
        | End_of_file -> Seq.Nil
      in
      mem := Some res;
      res
  in
  next (ref None)

let of_channel chan =
  let input = seq_of_channel chan in
  let utf8_input = Unicode.Encoding.utf8_decode input in
  create utf8_input
"

let generate_parser_errors fmt =
  Format.fprintf fmt "type error =
  | UnexpectedToken of Lexer.token
  | UnexpectedEOF

exception Error of error CodeMap.Span.located

"

let generate_parser g fmt =
  let table = ParseTable.of_grammar g in
  Format.fprintf fmt "open CodeMap\n\n";
  generate_parser_errors fmt;
  Format.fprintf fmt "let print_error e fmt =
  match e with
  | UnexpectedToken token -> Printf.fprintf fmt \"unexpected %%t\" (Lexer.print_token_debug token)
  | UnexpectedEOF -> Printf.fprintf fmt \"unexpected end of file\"

";
  Format.fprintf fmt "let rec consume span lexer =
    match lexer () with
    | Seq.Nil -> raise (Error (UnexpectedEOF, span))
    | Seq.Cons ((token, span'), lexer') ->
      (token, span'), (Span.union span span'), lexer'

";
  let defined_functions = Hashtbl.create 8 in
  Grammar.iter_non_terminals (
    function nt ->
      generate_non_terminal_parser defined_functions table nt fmt
  ) g;
  Grammar.iter (
    function (def, _) ->
      let name = def.Grammar.name in
      Format.fprintf fmt "let parse_%s lexer =
  let res, _ = %t Span.default lexer in
  res

" name (generate_definition_function_name def)
  ) g

let generate_parser_interface g fmt =
  generate_parser_errors fmt;
  Format.fprintf fmt "val print_error : error -> out_channel -> unit\n\n";
  Grammar.iter (
    function (def, _) ->
      let name = def.Grammar.name in
      Format.fprintf fmt "val parse_%s : Lexer.t -> Ast.%s CodeMap.Span.located\n" name name
  ) g
