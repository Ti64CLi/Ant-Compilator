let authors = [
  "Timothée Haudebourg <timothee.haudebourg@irisa.fr>"
]

let version = "0.1"

let summary =
  "Parser generator for BNF-based LL1 grammars."

type component =
  | Ast
  | Lexer
  | Parser

module Conf = struct
  type t = {
    verbosity: int;
    interface: bool;
    component: component;
    filename: string option;
  }

  let default = {
    verbosity = 0;
    interface = false;
    component = Ast;
    filename = None;
  }

  let select c t =
    { t with component = c }

  let interface t =
    { t with interface = true }

  let verbose t =
    { t with verbosity = t.verbosity+1 }

  let quiet t =
    { t with verbosity = t.verbosity-1 }

  let set_file filename t =
    { t with filename = Some filename }
end

let spec =
  let open Clap in
  app "Simple parser generator" "0.0" authors summary
  +> arg (id "ast" 'a') (Flag (Conf.select Ast)) "Print the abstract syntax tree definition."
  +> arg (id "lexer" 'l') (Flag (Conf.select Lexer)) "Print the lexer."
  +> arg (id "parser" 'p') (Flag (Conf.select Parser)) "Print the parser."
  +> arg (short 'i') (Flag Conf.interface) "Output the interface of the selected component."
  +> arg (short 'v') (Flag Conf.verbose) "Increase the level of verbosity."
  +> arg (short 'q') (Flag Conf.quiet) "Decrease the level of verbosity."
  +> anon "FILE" (String Conf.set_file) "Sets the input file to process."

(** Make a sequence of char out of an input channel. *)
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

let process_file conf filename =
  try
    let file = open_in filename in
    let input = seq_of_channel file in
    let utf8_input = Unicode.Encoding.utf8_decode input in
    let lexer = SimpleParser.Lexer.create utf8_input in
    let ast = SimpleParser.Parser.parse lexer in
    let grammar = SimpleParser.Grammar.of_ast ast in
    (* Seq.iter (function (token, _) -> Format.printf "%t@." (SimpleParser.Lexer.Token.print token)) lexer *)
    (* Format.printf "%t@." (SimpleParser.Ast.print ast) *)
    (* Format.printf "%t@." (SimpleParser.Grammar.print grammar); *)
    begin match conf.Conf.component with
      | Ast ->
        if conf.interface then
          Format.printf "%t@." (SimpleParser.Generator.generate_ast_interface grammar)
        else
          Format.printf "%t@." (SimpleParser.Generator.generate_ast grammar)
      | Lexer ->
        if conf.interface then
          Format.printf "%t@." (SimpleParser.Generator.generate_lexer_interface grammar)
        else
          Format.printf "%t@." (SimpleParser.Generator.generate_lexer grammar)
      | Parser ->
        if conf.interface then
          Format.printf "%t@." (SimpleParser.Generator.generate_parser_interface grammar)
        else
          Format.printf "%t@." (SimpleParser.Generator.generate_parser grammar)
    end
  with
  | SimpleParser.Lexer.Error (e, span) ->
    Format.eprintf "\x1b[31mLex error\x1b[0m: %t: %t@." (CodeMap.Span.format span) (SimpleParser.Lexer.print_error e)
  | SimpleParser.Parser.Error (e, span) ->
    Format.eprintf "\x1b[31mParse error\x1b[0m: %t: %t@." (CodeMap.Span.format span) (SimpleParser.Parser.print_error e)
  | SimpleParser.Grammar.Error (e, span) ->
    Format.eprintf "\x1b[31mGrammar error\x1b[0m: %t: %t@." (CodeMap.Span.format span) (SimpleParser.Grammar.print_error e)
  | SimpleParser.ParseTable.Error (e, span) ->
    Format.eprintf "\x1b[31mGeneration error\x1b[0m: %t: %t@." (CodeMap.Span.format span) (SimpleParser.ParseTable.print_error e)

let _ =
  (* let opt = Format.get_formatter_out_functions () in
  Format.set_formatter_out_functions { opt with out_indent = function i -> }; *)
  (* read options. *)
  let conf = Clap.parse spec Conf.default in
  begin match conf.filename with
    | Some filename ->
      process_file conf filename
    | None ->
      Printf.eprintf "No file specified. Use `simple-parser-gen --help` to show usage informations.";
      exit 1
  end
