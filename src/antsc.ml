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
  and currentLabel = ref 0 
  and programLines = ref []
  and nestedCalls = ref [] in
  write_label oc filename;
  (* aux *)
  let rec process_program program =
    match program with
    | Ast.PreprocessorProgram ((preprocessor, _), (prog, _)) -> 
      begin
        match prog with
        | Some p -> process_program p
        | None -> ()
      end
    | Ast.ControlProgram ((control, _), (prog, _)) ->
      begin
        process_control control;
        match prog with
        | Some p -> process_program p
        | None -> ()
      end
    | Ast.ExpressionProgram ((expression, _), (prog, _)) ->
      begin
        process_expression expression;
        match prog with
        | Some p -> process_program p
        | None -> ()
      end
  and process_control control =
    match control with
    | Ast.Label (name, _) -> 
      begin
        labels := name :: !labels;
        write_label oc name
      end
    | Ast.IfThenElse ((cond, _), (thenProgram, _), (elseProgram, _)) -> ()
    | Ast.IfThen ((cond, _), (ifThenBody, _)) -> ()
    | Ast.Func ((name, _), (args, _), (funcBody, _)) -> 
      begin (* assume there is no args for now *)
        labels := name :: !labels;
        write_label oc name;
        process_program funcBody;
        write_command oc ("Goto " ^ name)
      end
    | Ast.While ((cond, _), (whileBody, _)) -> ()
    | Ast.Repeat ((cond, _), (repeatBody, _)) ->
      begin (* for now assume cond is a number *)
        match cond with
        | Ast.Value (Ast.Int (num, _), _) -> (* it's a number *)
          begin
            for i = 1 to num do
              process_program repeatBody
            done
          end
        | _ -> failwith "Repeat expects an argument of type <int>"
      end
    | Ast.Case ((case, _), (caseBody, _)) -> ()
    | Ast.Switch ((cond, _), (switchBody, _)) -> ()
  and process_expression expression =
    match expression with
    | Ast.Num (num, _) -> ()
    | Ast.Args (index, _) -> ()
    | Ast.Move (num, _) ->
      begin
        let label = "_label" ^ (string_of_int (!currentLabel)) in
        for i = 1 to num do
          write_command oc ("Move " ^ label)
        done;
        write_label oc label;
        currentLabel := !currentLabel + 1
      end
    | Ast.Turn (num, _) -> 
      begin
        let i = num mod 6 in
        let dir = [|"Right"; "Left"|] in
        for j = 1 to i - ((i / 4) * 3) do
            write_command oc ("Turn " ^ dir.(i / 4))
        done
      end
    | Ast.PickUp (onError, _) ->
      begin
        write_command oc ("PickUp " ^ onError)
      end
    | Ast.Drop -> 
      begin
        write_command oc "Drop"
      end
    | Ast.Goto (label, _) -> 
      begin
        write_command oc ("Goto " ^ label)
      end
    | Ast.Mark (num, _) -> 
      begin
        if num > 6 || num < 1 then
          failwith "Mark expects a number between 1 and 6"
        else
          write_command oc ("Mark" ^ (string_of_int num))
      end
    | Ast.Unmark (num, _) -> 
      begin
        if num > 6 || num < 1 then
          failwith "UnMark expects a number between 1 and 6"
        else
          write_command oc ("Unmark" ^ (string_of_int num))
      end
    | Ast.Call (ident, _) -> 
      begin
        write_command oc ("Goto " ^ ident);
        nestedCalls := ident :: !nestedCalls
      end
    | Ast.Nop -> ()
    | Ast.Return -> 
      begin
        if (List.length !nestedCalls) = 1 then
          failwith "Return from non-called function"
      end
    | Ast.Break -> () in
  process_program program

let get_filename_ext filename =
  let i = ref 0 in
  while !i < String.length filename && filename.[!i] <> '.' do
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
