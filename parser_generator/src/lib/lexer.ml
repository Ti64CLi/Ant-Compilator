open Unicode
open UString
open CodeMap

type error =
  | Unexpected of UChar.t option
  | EmptyToken

exception Error of error Span.located

module Token = struct
  type t =
    | Terminal of Utf8String.t
    | NonTerminal of Utf8String.t
    | Iterated of Utf8String.t * Utf8String.t * bool
    | Optional of Utf8String.t

  let print t fmt =
    match t with
    | Terminal name -> Format.fprintf fmt "%s" name
    | NonTerminal name -> Format.fprintf fmt "<%s>" name
    | Iterated (name, sep, false) -> Format.fprintf fmt "<%s*%s>" name sep
    | Iterated (name, sep, true) -> Format.fprintf fmt "<%s+%s>" name sep
    | Optional name -> Format.fprintf fmt "<%s?>" name
end

module TokenKind = struct
  type t =
    | Terminal
    | NonTerminal
    | Type
    | TypeIdent
    | Equal
    | RuleSeparator
    | Constructor

  let print t fmt =
    match t with
    | Terminal -> Format.fprintf fmt "terminal"
    | NonTerminal -> Format.fprintf fmt "non terminal `<...>`"
    | Type -> Format.fprintf fmt "keyword `type`"
    | TypeIdent -> Format.fprintf fmt "type identifier"
    | Equal -> Format.fprintf fmt "keyword `=`"
    | RuleSeparator -> Format.fprintf fmt "rule separator `|`"
    | Constructor -> Format.fprintf fmt "OCaml constructor"
end

type token = Token.t

type token_kind = TokenKind.t

type t = token Span.located Seq.t

let consume span chars =
  begin match chars () with
    | Seq.Nil -> (span, Seq.Nil)
    | Seq.Cons (c, chars) ->
      (* Add [c] to the [span]. *)
      let span = Span.push c span in
      (span, Seq.Cons (c, chars))
  end

let rec read_non_terminal span chars =
  let return span chars buffer =
    Seq.Cons (Span.located span (Token.NonTerminal buffer), next (Span.next span) chars)
  in
  let return_iterated span chars buffer sep non_empty =
    Seq.Cons (Span.located span (Token.Iterated (buffer, sep, non_empty)), next (Span.next span) chars)
  in
  let return_optional span chars buffer =
    Seq.Cons (Span.located span (Token.Optional buffer), next (Span.next span) chars)
  in
  let rec read_separator name non_empty span chars buffer =
    match consume span chars with
    | _, Seq.Nil ->
      raise (Error (Span.located span (Unexpected None)))
    | span', Seq.Cons (c, chars') ->
      begin match UChar.to_int c with
        | 0x3e -> (* > *)
          (* Read the char and stop. *)
          return_iterated span' chars' name buffer non_empty
        | _ when UChar.is_whitespace c || UChar.is_control c ->
          (* Error. *)
          raise (Error (Span.located span (Unexpected (Some c))))
        | _ ->
          read_separator name non_empty span' chars' (Utf8String.push c buffer)
      end
  in
  let rec read span chars buffer =
    match consume span chars with
    | _, Seq.Nil ->
      raise (Error (Span.located span (Unexpected None)))
    | span', Seq.Cons (c, chars') ->
      begin match UChar.to_int c with
        | 0x3e -> (* > *)
          (* Read the char and stop. *)
          return span' chars' buffer
        | 0x2a -> (* * *)
          read_separator buffer false span' chars' ""
        | 0x2b -> (* + *)
          read_separator buffer true span' chars' ""
        | 0x3f -> (* ? *)
          begin match consume span' chars' with
            | span', Seq.Cons (c, chars') when (UChar.to_int c) = 0x3e -> (* > *)
              (* Read the char and stop. *)
              return_optional span' chars' buffer
            | _ ->
              (* Error. *)
              raise (Error (Span.located span' (Unexpected (Some c))))
          end
        | _ when UChar.is_whitespace c || UChar.is_control c ->
          (* Error. *)
          raise (Error (Span.located span (Unexpected (Some c))))
        | _ ->
          read span' chars' (Utf8String.push c buffer)
      end
  in
  read span chars ""

and read_terminal span (c, chars) =
  let return span chars buffer =
    let token = match buffer with
      | _ -> Token.Terminal buffer
    in
    Seq.Cons (Span.located span token, next (Span.next span) chars)
  in
  let rec read span chars buffer =
    match consume span chars with
    | _, Seq.Nil -> return span chars buffer
    | span', Seq.Cons (c, chars') ->
      begin match UChar.to_int c with
        | 0x3c | 0x28 | 0x29 |0x5b | 0x5d | 0x7b | 0x7d -> (* < ( ) [ ] { } *)
          (* Stop here. *)
          return span chars buffer
        | _ when UChar.is_whitespace c || UChar.is_control c ->
          (* Stop here. *)
          return span chars buffer
        | _ ->
          read span' chars' (Utf8String.push c buffer)
      end
  in
  read span chars (Utf8String.push c "")

and next span chars () =
  let rec consume_first escaped span chars =
    begin match consume span chars with
      | _, Seq.Nil -> Seq.Nil
      | span, Seq.Cons (c, chars) ->
        (* Find the token type. *)
        begin match UChar.to_int c with
          | _ when UChar.is_whitespace c || UChar.is_control c ->
            if escaped then raise (Error (EmptyToken, span));
            (* skip spaces and controls. *)
            next (Span.next span) chars ()
          | 0x5c when not escaped -> (* \ *)
            consume_first true span chars
          | 0x3c when not escaped -> (* < *)
            (* It's a non terminal. *)
            read_non_terminal span chars
          | _ ->
            (* It's a terminal, or a keyword. *)
            read_terminal span (c, chars)
        end
    end
  in
  consume_first false span chars

let create chars =
  next Span.default chars

let print_error e fmt =
  match e with
  | Unexpected (Some c) ->
    Format.fprintf fmt "unexpected char `%s`" (Utf8String.push c "")
  | Unexpected None ->
    Format.fprintf fmt "unexpected end of file"
  | EmptyToken ->
    Format.fprintf fmt "you must use a non-empty separator: in <name*sep> or <name+sep>, the `sep` part cannot be empty."
