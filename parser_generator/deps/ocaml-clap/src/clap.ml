module Value = struct
  type t =
    | Unit
    | Int of int
    | String of string
end

type 'a action =
  | Flag of ('a -> 'a)
  | Int of (int -> 'a -> 'a)
  | String of (string -> 'a -> 'a)
  | Help
  | Version

(** Option identifier *)
type ident = {
  long: string option;
  short: char option
}

type 'a arg = {
  id: ident;
  action: 'a action;
  summary: string
}

type 'a anonymous = {
  name: string;
  action: 'a action;
  multiple: bool;
  summary: string
}

type 'a arg_spec =
  | Arg of 'a arg
  | Anon of 'a anonymous

type 'a t = {
  name: string;
  version: string;
  authors: string list;
  args: ('a arg) list;
  anons: ('a anonymous) list;
  summary: string;
}

let id_to_string id () =
  match id.long, id.short with
  | Some l, Some s ->
    Format.sprintf "-%c, --%s" s l
  | None, Some s ->
    Format.sprintf "-%c" s
  | Some l, None ->
    Format.sprintf "--%s" l
  | _ -> raise (Invalid_argument "invalid id")

let print_id id out =
  Format.fprintf out "%s" (id_to_string id ())

let print_usage t out =
  let proc_name = Sys.argv.(0) in
  Format.fprintf out "Usage: %s" proc_name;
  if List.length t.args > 0 then
    Format.fprintf out " [OPTIONS]";
  let introduce_anon (a : 'a anonymous) =
    Format.fprintf out " <%s>" a.name;
    if a.multiple then
      Format.fprintf out "..."
  in
  List.iter introduce_anon t.anons;
  (* ... *)
  Format.fprintf out "\n%s" t.summary;
  Format.fprintf out "\n\n%s %s" t.name t.version;
  let print_author a =
    Format.fprintf out "\n%s" a
  in
  List.iter print_author t.authors;
  (* ... *)
  let print_preformatted l =
    let tab_width = 4 in
    let find_max_width m (label, _) =
      max m (String.length label)
    in
    let max_width = List.fold_left find_max_width 0 l in
    let print_item (label, summary) =
      let space_width = max_width - (String.length label) + tab_width in
      Format.fprintf out "\n%s%s%s%s" (String.make tab_width ' ') label (String.make space_width ' ') summary
    in
    List.iter print_item l
  in
  if List.length t.args > 0 then
    begin
      Format.fprintf out "\n\nOPTIONS:";
      let preformat_option o =
        let label = Format.sprintf "%t" (id_to_string o.id) in
        label, o.summary
      in
      let preformatted = List.map preformat_option t.args in
      print_preformatted preformatted
    end;
  if List.length t.anons > 0 then
    begin
      Format.fprintf out "\n\nARGS:";
      let preformat_arg (a : 'a anonymous) =
        a.name, a.summary
      in
      let preformatted = List.map preformat_arg t.anons in
      print_preformatted preformatted
    end;
  Format.fprintf out "\n"

let arg id action summary =
  Arg {
    id = id;
    action = action;
    summary = summary
  }

let anon name ?(multiple=false) action summary =
  Anon {
    name = name;
    action = action;
    multiple = multiple;
    summary = summary
  }

let long id =
  {
    long = Some id;
    short = None
  }

let short id =
  {
    long = None;
    short = Some id
  }

let id long short =
  {
    long = Some long;
    short = Some short
  }

let ident_repr id =
  match id.long, id.short with
  | Some id, _ -> id
  | None, Some id -> String.make 1 id
  | None, None -> failwith "invalid arg id"

let ident_leq a b =
  compare (ident_repr a) (ident_repr b) <= 0

let arg_spec_leq a b = ident_leq a.id b.id

let rec insert a = function
  | [] -> [a]
  | b::l -> if arg_spec_leq a b then a::b::l else b::(insert a l)

let (+>) t = function
  | Arg a ->
    {
      t with
      args = insert a t.args
    }
  | Anon a ->
    {
      t with
      anons = t.anons @ [a]
    }

let app name version authors summary =
  {
    name = name;
    version = version;
    authors = authors;
    args = [];
    anons = [];
    summary = summary
  }
  +> arg (id "help" 'h') Help "Prints this message."
  +> arg (id "version" 'V') Version "Prints version information."

let is_short_arg str =
  let len = String.length str in
  len > 1 && str.[0] == '-' && str.[1] != '-'

let is_long_arg str =
  let len = String.length str in
  len > 2 && str.[0] == '-' && str.[1] == '-'

exception Invalid_value of ident * string
exception Invalid_ano_value of string * string
exception Value_expected of ident
exception Unexpected_value of string
exception Unknown_option of ident

let fold_args f g t accu =
  let expect_param arg i =
    if Array.length Sys.argv <= i then
      raise (Value_expected arg.id)
    else
      Sys.argv.(i)
  in
  let rec fold i remaining_anons accu =
    let rec read_expected_params i (selected_args : 'a arg list) accu =
      match selected_args with
      | [] -> fold i remaining_anons accu
      | arg::selected_args' ->
        let value, j = begin match arg.action with
          | Int _ ->
            let str = expect_param arg i in
            begin match int_of_string_opt str with
              | Some value ->
                Value.Int value, (i + 1)
              | None -> raise (Invalid_value (arg.id, str))
            end
          | String _ ->
            let value = expect_param arg i in
            Value.String value, (i + 1)
          | _ ->
            Value.Unit, i
        end
        in
        read_expected_params j selected_args' (f arg value accu)
    in
    if Array.length Sys.argv <= i then accu else begin
      let str = Sys.argv.(i) in
      if is_short_arg str then
        let names = List.of_seq (String.to_seq (String.sub str 1 ((String.length str) - 1))) in
        let selected_args = List.map (
            function c ->
            match List.find_opt (function arg -> arg.id.short = Some c) t.args with
            | Some arg -> arg
            | None -> raise (Unknown_option {
                short = Some c;
                long = None
              })
          ) names
        in
        read_expected_params (i + 1) selected_args accu
      else if is_long_arg str then
        let name = String.sub str 2 ((String.length str) - 2) in
        let selected_arg = match List.find_opt (function arg -> arg.id.long = Some name) t.args with
          | Some arg -> arg
          | None -> raise (Unknown_option {
              short = None;
              long = Some name
            })
        in
        read_expected_params (i + 1) [selected_arg] accu
      else begin
        match remaining_anons with
        | [] -> raise (Unexpected_value str)
        | arg::remaining_anons' ->
          let value = match arg.action with
            | Int _ ->
              begin match int_of_string_opt str with
                | Some value ->
                  Value.Int value
                | None -> raise (Invalid_ano_value (arg.name, str))
              end
            | String _ ->
              Value.String str
            | _ -> Value.Unit
          in
          let accu = g arg value accu in
          fold (i + 1) (if arg.multiple then [arg] else remaining_anons') accu
      end
    end
  in
  fold 1 t.anons accu

let parse t accu =
  try
    let parsed_args, parsed_anons, special_action = fold_args (
        fun arg value (args, anons, special_action) ->
          let special_action = match special_action, arg.action with
            | None, Version -> Some Version
            | _, Help -> Some Help
            | _, _ -> special_action
          in
          (arg, value)::args, anons, special_action
      ) (
        fun ano value (args, anons, special_action) ->
          args, (ano, value)::anons, special_action
      ) t ([], [], None)
    in
    begin match special_action with
      | Some Help ->
        print_usage t Format.std_formatter;
        exit 0
      | Some Version ->
        Format.fprintf Format.std_formatter "%s\n" t.version;
        exit 0
      | _ ->
        let apply_action action value accu =
          match action, value with
          | Flag f, Value.Unit -> f accu
          | Int f, Value.Int i -> f i accu
          | String f, Value.String s -> f s accu
          | _ -> failwith "clap failed."
        in
        let accu = List.fold_left (
            fun accu ((arg : 'a arg), value) ->
              apply_action arg.action value accu
          ) accu parsed_args
        in
        List.fold_left (
          fun accu (ano, value) ->
            apply_action ano.action value accu
        ) accu parsed_anons
    end
  with
  | Invalid_value (id, str) ->
    Format.eprintf "Invalid value `%s' for option `%t'\n" str (print_id id);
    print_usage t Format.err_formatter;
    exit 1
  | Invalid_ano_value (name, str) ->
    Format.eprintf "Invalid value `%s' for `%s'\n" str name;
    print_usage t Format.err_formatter;
    exit 1
  | Value_expected id ->
    Format.eprintf "Value expected for option `%t'\n" (print_id id);
    print_usage t Format.err_formatter;
    exit 1
  | Unknown_option id ->
    Format.eprintf "Unknown option `%t'\n" (print_id id);
    print_usage t Format.err_formatter;
    exit 1
  | Unexpected_value value ->
    Format.eprintf "Unexpected value `%s'\n" value;
    print_usage t Format.err_formatter;
    exit 1
