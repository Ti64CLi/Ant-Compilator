open Printf

let write_file filename = (* Ceci est un exemple. *)
  let oc = open_out filename in (* Ouvre un fichier pour écrire dedans. *)
  let write_label (msg:string) : unit = (* Écriture d'un label. *)
    fprintf oc "%s:\n" msg in
  let write_command (msg:string) : unit = (* Écriture d'autres commandes. *)
    fprintf oc "  %s\n" msg in
  write_label   "start";
  write_command "Drop";
  write_command "Goto start";
  close_out oc

let compile_file filename program =
  let write_label oc msg =
    fprintf oc "%s:\n" msg in
  let write_command oc msg =
    fprintf oc "  %s\n" msg in
  let oc = open_out (filename ^ ".brain") in
  let labels = ref [] 
  and currentLabel = ref 0 in
  let programLines = ref [] in
  write_label oc filename;
  (* aux *)
  let rec process_program program =
    match program with
    | PreprocessorProgram ((preprocessor, _), (prog, _)) -> 
      begin
        process_program prog
      end
    | ControlProgram ((control, _), (prog, _)) ->
      begin
        process_control control;
        process_program prog
      end
    | ExpressionProgram ((expression, _), (prog, _)) ->
      begin
        process_expression expression;
        process_program prog
      end
  and rec process_control control =
    match control with
    | Label (name, _) -> 
      begin
        labels := name :: !labels;
        write_label oc name
      end
    | IfThenElse ((cond, _), (thenProgram, _), (elseProgram, _)) -> ()
    | Func ((name, _), (args, _), (funcBody, _)) -> 
      begin (* assume there is no args for now *)
        labels := name :: !labels;
        write_label oc name;
        process_program funcBody;
        write_command oc ("Goto " ^ name)
      end
    | While ((cond, _), (whileBody, _)) -> ()
    | Repeat ((cond, _), (repeatBody, _)) ->
      begin (* for now assume cond is a number *)
        match cond with
        | Value (Int (num, _), _) -> (* it's a number *)
          begin
            for i = 1 to num do
              process_program repeatBody
            done
          end
        | _ -> failwith "Repeat expects an argument of type <int>"
      end
    | Case ((case, _), (caseBody, _)) -> ()
    | Switch ((cond, _), (switchBody, _)) -> ()
  and rec process_expression expression =
    match program with
    | Num (num, _) -> ()
    | Args (index, _) -> ()
    | Move (num, _) ->
      begin
        let label = "_label" ^ (string_of_int (!currentLabel)) in
        for i = 1 to num do
          write_command oc ("Move " ^ label)
        done;
        write_label oc label;
        currentLabel := !currentLabel + 1
      end
    | Turn (num, _) -> 
      begin
        let i = num mod 6 in
        let dir = [|"Right"; "Left"|] in
        for j = 1 to i - ((i / 4) * 3) do
            write_command ("Turn " ^ dir.(i / 4))
        done
      end
    | PickUp (onError, _) ->
      begin
        write_command ("PickUp " ^ onError)
      end
    | Drop -> 
      begin
        write_command "Drop"
      end
    | Goto (label, _) -> 
      begin
        write_command ("Goto " ^ label)
      end
    | Mark (num, _) -> 
      begin
        if num > 6 || num < 1 then
          failwith "Mark expects a number between 1 and 6"
        else
          write_command ("Mark" ^ (string_of_int i))
      end
    | Unmark (num, _) -> 
      begin
        if num > 6 || num < 1 then
          failwith "UnMark expects a number between 1 and 6"
        else
          write_command ("Unmark" ^ (string_of_int i))
      end
    | Call (ident, _) -> 
      begin
        write_command ("Goto " ^ ident);
        nestedCalls := ident :: !nestedCalls
      end
    | IfThen ((cond, _), (ifThenBody, _)) -> ()
    | Nop -> ()
    | Return -> 
      begin
        if (List.length nestedCalls) = 1 then
          failwith "Return from non-called function"
      end
    | Break -> ()

let get_filename_ext filename =
  let i = ref 0 in
  while i < String.length filename && filename.(i) <> '.' do
    i := !i + 1
  done;
  String.sub filename 0 (!i)

let process_file filename =
  (* Ouvre le fichier et créé un lexer. *)
  let file = open_in filename in
  let lexer = Lexer.of_channel file in
  (* Parse le fichier. *)
  let (program, span) = Parser.parse_program lexer in
  printf "successfully parsed the following program at position %t:\n%t\n" (CodeMap.Span.print span) (Ast.print_program program);
  compile_file (get_filename_ext filename) program

(* Le point de départ du compilateur. *)
let _ =
  (* On commence par lire le nom du fichier à compiler passé en paramètre. *)
  if Array.length Sys.argv <= 1 then begin
    (* Pas de fichier... *)
    eprintf "An argument is missing\nUsage : %s <filename>\n" (Sys.argv.(0));
    exit 1
  end else begin
    try
      (* On compile le fichier. *)
      process_file (Sys.argv.(1))
    with
    | Lexer.Error (e, span) ->
      eprintf "Lex error: %t: %t\n" (CodeMap.Span.print span) (Lexer.print_error e)
    | Parser.Error (e, span) ->
      eprintf "Parse error: %t: %t\n" (CodeMap.Span.print span) (Parser.print_error e)
  end
