open Printf

let get_filename path =
  let i = ref 0
  and s = ref 0
  and l = String.length path in
  while !i < l do
    if path.[!i] = '/' then
      s := !i + 1;
    
    i := !i + 1
  done;
  String.sub path !s (l - !s)

let get_filename_without_ext filename =
  let i = ref 0 in
  while !i < String.length filename && filename.[!i] <> '.' do
    i := !i + 1
  done;
  String.sub filename 0 (!i)

let compile_file path program =
  let write_label oc msg =
    fprintf oc "%s:\n" msg in
  let write_command oc msg =
    fprintf oc "  %s\n" msg in
  let oc = open_out ((get_filename_without_ext path) ^ ".brain") in
  let labels = ref []
  and defines = ref []
  and calls = ref []
  and functions = ref []
  and inFunction = ref false
  and currentLabel = ref 0 in
  write_label oc (get_filename_without_ext (get_filename path));
  (* aux *)
  let look_in_labels label = (* check whether a label exists or not *)
    let rec aux l e =
      match l with
      | [] -> failwith ("Undeclared label '" ^ e ^ "'")
      | h :: _ when h = e -> ()
      | _ :: t -> aux t e in
    aux !labels label
  and look_in_defined define : int = (* check whether an identifier is linked to an int *)
    let rec aux l e =
      match l with
      | [] -> failwith ("Undeclared identifier '" ^ e ^ "'")
      | (d, v) :: _ when d = e -> v
      | _ :: t -> aux t e in
    aux !defines define in
  let process_value value =
    match value with
    | Ast.Var (var, _) -> look_in_defined var
    | Ast.Int (n, _) -> n in
  let get_direction direction =
    match direction with
    | Ast.Value (value, _) -> string_of_int (process_value value)
    | Ast.Ahead -> "Ahead"
    | Ast.Here -> "Here"
    | Ast.Left -> "LeftAhead"
    | Ast.Right -> "RightAhead"
  and get_condition category =
    match category with
    | Ast.Friend -> "Friend"
    | Ast.Foe -> "Foe"
    | Ast.FriendWithFood -> "FriendWithFood"
    | Ast.FoeWithFood -> "FoeWithFood"
    | Ast.Food -> "Food"
    | Ast.Rock -> "Rock"
    | Ast.Marker (value, _) -> 
      begin
        let bit = process_value value in
        if bit > 5 || bit < 0 then
          failwith "bit awaits for an integer between 0 and 5";
        "Marker " ^ (string_of_int bit)
      end
    | Ast.FoeMarker -> "FoeMarker"
    | Ast.Home -> "Home"
    | Ast.FoeHome -> "FoeHome" 
    | _ -> failwith "Pattern not supported for now" in
  (* aux *)
  let rec process_program program =
    match program with
    | Ast.PreprocessorProgram ((preprocessor, _), (prog, _)) -> 
      begin
        process_preprocessor preprocessor;

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
  and process_preprocessor preprocessor =
    match preprocessor with
    | Ast.Define ((ident, _), (num, _)) -> 
      begin
        print_string ("Defined " ^ ident ^ " as " ^ (string_of_int num) ^ "\n");
        defines := (ident, num) :: !defines
      end
    | _ -> ()
  and process_control control =
    match control with
    | Ast.Label (name, _) -> 
      begin
        labels := name :: !labels;

        write_command oc ("Goto " ^ name);
        write_label oc name
      end
    | Ast.IfThenElse ((category, _), (direction, _), (thenBody, _), (elseBody, _)) -> 
      begin
        let label1 = "_label" ^ (string_of_int !currentLabel)
        and label2 = "_label" ^ (string_of_int (!currentLabel + 1))
        and label3 = "_label" ^ (string_of_int (!currentLabel + 2)) in
        currentLabel := !currentLabel + 3;

        match category with
        | Ast.RandInt (value, _) ->
          begin
            let p = process_value value in
            if p = 0 then
              failwith "Argument in randint must be non-zero";
            
            match direction with
            | Ast.Value (value, _) ->
              begin
                let n = process_value value in
                if n <> 0 then
                  failwith "Can only compare randint(p) to 0";
                
                write_command oc ("Flip " ^ (string_of_int p) ^ " " ^ label1 ^ " " ^ label2);
                write_label oc label1;

                process_program thenBody;

                write_command oc ("Goto " ^ label3);
                write_label oc label2;

                process_program elseBody;

                write_command oc ("Goto " ^ label3);
                write_label oc label3
              end
            | _ -> failwith "Can only compare randint(p) to 0"
          end
        | _ ->
          begin
            write_command oc ("Sense " ^ (get_direction direction) ^ " " ^ label1 ^ " " ^ label2 ^ " " ^ (get_condition category));
            write_label oc label1;

            process_program thenBody;

            write_command oc ("Goto " ^ label3);
            write_label oc label2;

            process_program elseBody;

            write_command oc ("Goto " ^ label3);
            write_label oc label3
          end
      end
    | Ast.IfThen ((thenBody, _), (category, _), (direction, _)) -> 
      begin
        let label1 = "_label" ^ (string_of_int !currentLabel)
        and label2 = "_label" ^ (string_of_int (!currentLabel + 1)) in
        currentLabel := !currentLabel + 2;

        match category with
        | Ast.RandInt (value, _) ->
          begin
            let p = process_value value in
            if p = 0 then
              failwith "Argument in randint must be non-zero";
            
            match direction with
            | Ast.Value (value, _) ->
              begin
                let n = process_value value in
                if n <> 0 then
                  failwith "Can only compare randint(p) to 0";
                
                write_command oc ("Flip " ^ (string_of_int p) ^ " " ^ label1 ^ " " ^ label2);
                write_label oc label1;

                process_program thenBody;
                
                write_command oc ("Goto " ^ label2);
                write_label oc label2
              end
            | _ -> failwith "Can only compare randint(p) to 0"
          end
        | _ ->
          begin
            write_command oc ("Sense " ^ (get_direction direction) ^ " " ^ label1 ^ " " ^ label2 ^ " " ^ (get_condition category));
            write_label oc label1;

            process_program thenBody;

            write_command oc ("Goto " ^ label2);
            write_label oc label2;
          end
      end
    | Ast.Func ((name, _), (args, _), (funcBody, _)) -> 
      begin (* assuming there is no args for now *)
        let label = "_label" ^ (string_of_int !currentLabel) in

        labels := name :: !labels;
        functions := name :: !functions;
        let addLabel = if !inFunction then true else false in

        if addLabel then begin
          write_command oc ("Goto " ^ label);
          currentLabel := !currentLabel + 1
        end;
        
        inFunction := true;

        write_label oc name;
        process_program funcBody;
        write_command oc ("Goto " ^ name);

        if addLabel then begin
          write_label oc label
        end;
        
        functions := List.tl !functions;
        inFunction := false
      end
    | Ast.While ((category, _), (direction, _), (whileBody, _)) ->
      begin
        let label1 = "_label" ^ (string_of_int !currentLabel)
        and label2 = "_label" ^ (string_of_int (!currentLabel + 1))
        and label3 = "_label" ^ (string_of_int (!currentLabel + 2)) in
        match category with
        | Ast.RandInt (value, _) -> 
          begin
          end
        | _ ->
          begin
            write_command oc ("Goto " ^ label1);
            write_label oc label1;
            write_command oc ("Sense " ^ (get_direction direction) ^ " " ^ label2 ^ " " ^ label3 ^ (get_condition category));
            write_label oc label2;

            process_program whileBody;
            
            write_command oc ("Goto " ^ label1);
            write_label oc label3
          end
      end
    | Ast.Repeat ((value, _), (repeatBody, _)) ->
      begin (* for now assume cond is a number *)
        let num = process_value value in
        for i = 1 to num do
          process_program repeatBody
        done
      end
    | Ast.Case ((direction, _), (caseBody, _)) -> ()
    | Ast.Switch ((category, _), (switchBody, _)) -> ()
  and process_expression expression =
    match expression with
    | Ast.Args (value, _) -> ()
    | Ast.Move (value, _) ->
      begin
        let num = process_value value in
        let label = "_label" ^ (string_of_int (!currentLabel)) in
        for i = 1 to num do
          write_command oc ("Move " ^ label) 
        done;

        write_command oc ("Goto "^ label);
        write_label oc label;

        currentLabel := !currentLabel + 1
      end
    | Ast.Turn (value, _) -> 
      begin
        let num = process_value value in
        let i = num mod 6 in
        let dir = [|"Right"; "Left"|] in
        for j = 1 to i - 2*(i/4)*(i-3) do
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
    | Ast.Mark (value, _) -> 
      begin
        let num = process_value value in
        if num > 5 || num < 0 then
          failwith "Mark expects a number between 0 and 5"
        else
          write_command oc ("Mark " ^ (string_of_int num))
      end
    | Ast.Unmark (value, _) -> 
      begin
        let num = process_value value in
        if num > 5 || num < 0 then
          failwith "UnMark expects a number between 0 and 5"
        else
          write_command oc ("Unmark " ^ (string_of_int num))
      end
    | Ast.Call (ident, _) -> 
      begin
        write_command oc ("Goto " ^ ident);
        (*calls := (ident, List.hd !functions) :: !calls*)
      end
    | Ast.Nop -> ()
    | Ast.Return -> ()
      (*begin TODO
        if (List.length !calls) = 0 then
          failwith "Return from non-called function"
        else
          begin
            let label = look_in_calls List.hd  in
            write_command oc ("Goto " ^ label);
            calls := List.tl !calls
          end
      end*)
    | Ast.Break -> () in
  process_program program

let process_file path =
  (* Ouvre le fichier et créé un lexer. *)
  let file = open_in path in
  let lexer = Lexer.of_channel file in
  (* Parse le fichier. *)
  let (program, span) = Parser.parse_program lexer in
  printf "successfully parsed the following program at position %t:\n%t\n" (CodeMap.Span.print span) (Ast.print_program program);
  compile_file path program

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
