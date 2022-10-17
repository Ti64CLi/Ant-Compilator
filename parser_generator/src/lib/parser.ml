open CodeMap

module SeqThen = struct
  type ('a, 'b) node =
    | Nil of 'b
    | Cons of 'a * ('a, 'b) t

  and ('a, 'b) t = unit -> ('a, 'b) node

  let rec fold_left f accu t =
    match t () with
    | Nil b -> accu, b
    | Cons (a, t') -> fold_left f (f accu a) t'
end

type error =
  | UnexpectedEOF
  | Unexpected of Lexer.token * (Lexer.token_kind list)

exception Error of error Span.located

let consume span lexer =
  match lexer () with
  | Seq.Nil -> raise (Error (UnexpectedEOF, span))
  | Seq.Cons ((token, span'), lexer') ->
    (token, span'), (Span.union span span'), lexer'

let is_ocaml_ident _ =
  true

let is_constructor_name _ =
  true

let tokens lexer : (Ast.token Span.located, Lexer.t) SeqThen.t =
  let rec next lexer () =
    match lexer () with
    | Seq.Nil
    | Seq.Cons ((Lexer.Token.Terminal "|", _), _)
    | Seq.Cons ((Lexer.Token.Terminal "type", _), _) ->
      SeqThen.Nil lexer
    | Seq.Cons ((token, span), lexer') ->
      begin match token with
        | Lexer.Token.Terminal name -> SeqThen.Cons ((Ast.Terminal name, span), next lexer')
        | Lexer.Token.NonTerminal name -> SeqThen.Cons ((Ast.NonTerminal (Ast.Ident name), span), next lexer')
        | Lexer.Token.Iterated (name, sep, non_empty) -> SeqThen.Cons ((Ast.NonTerminal (Ast.Iterated (name, sep, non_empty)), span), next lexer')
        | Lexer.Token.Optional name -> SeqThen.Cons ((Ast.NonTerminal (Ast.Optional name), span), next lexer')
        (* | _ -> raise (Error (Unexpected (token, [Lexer.TokenKind.Terminal; Lexer.TokenKind.NonTerminal]), span)) *)
      end
  in
  next lexer

let rules lexer =
  let rec next lexer () =
    match lexer () with
    | Seq.Nil -> SeqThen.Nil lexer
    | Seq.Cons ((Lexer.Token.Terminal "type", _), _) ->
      SeqThen.Nil lexer
    | Seq.Cons ((Lexer.Token.Terminal "|", _), lexer') -> (* Skip it *)
      next lexer' ()
    | Seq.Cons ((Lexer.Token.Terminal constructor, span), lexer') when is_constructor_name constructor ->
      let (tokens, span'), lexer' = SeqThen.fold_left
          (fun (tokens, span) (t, s) -> (t, s)::tokens, Span.union s span)
          ([], span)
          (tokens lexer')
      in
      let rule = {
        Ast.constructor = (constructor, span);
        tokens = List.rev tokens
      }
      in
      SeqThen.Cons ((rule, span'), next lexer')
    | Seq.Cons ((token, span), _) -> raise (Error (Unexpected (token, [Lexer.TokenKind.Type; Lexer.TokenKind.RuleSeparator; Lexer.TokenKind.Constructor]), span))
  in
  next lexer

let definitions lexer =
  let rec next lexer () =
    match lexer () with
    | Seq.Nil -> SeqThen.Nil lexer
    | Seq.Cons ((Lexer.Token.Terminal "type", span), lexer') -> (* Parse keyword `type`. *)
      (* Parse non-terminal name *)
      let (token, name_span), span, lexer' = consume span lexer' in
      begin match token with
        | Lexer.Token.Terminal name when is_ocaml_ident name ->
          (* Consume the required keyword `=`. *)
          let (token, token_span), span, lexer' = consume span lexer' in
          begin match token with
            | Lexer.Token.Terminal "=" ->
              let (rules, span), lexer' = SeqThen.fold_left
                (
                  fun (rules, span) (r, s) ->
                    (r, s)::rules, Span.union s span
                )
                ([], span)
                (rules lexer')
              in
              (* Generate the definition. *)
              let definition =
                {
                  Ast.name = name, name_span;
                  rules = List.rev rules
                }
              in
              SeqThen.Cons ((definition, span), next lexer')
            | _ -> raise (Error (Unexpected (token, [Lexer.TokenKind.Equal]), token_span))
          end
        | unexpected ->
          raise (Error (Unexpected (unexpected, [Lexer.TokenKind.TypeIdent]), span))
      end
    | Seq.Cons ((unexpected, span), _) ->
      raise (Error (Unexpected (unexpected, [Lexer.TokenKind.Type]), span))
  in
  next lexer

let parse lexer =
  let g, _ = SeqThen.fold_left
      (fun g def -> def::g)
      []
      (definitions lexer)
  in
  g

let print_error e fmt =
  match e with
  | Unexpected (token, _) ->
    Format.fprintf fmt "unexpected token `%t`" (Lexer.Token.print token)
  | UnexpectedEOF ->
    Format.fprintf fmt "unexpected end of file"
