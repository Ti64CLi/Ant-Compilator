open Printf

let errors = ref 0

let get_filename path = (* separates filename form directory and returns both *)
  let i = ref 0
  and s = ref 0
  and l = String.length path in
  while !i < l do
    if path.[!i] = '/' then
      s := !i + 1;
    
    i := !i + 1
  done;
  (String.sub path 0 !s, String.sub path !s (l - !s))

let get_filename_without_ext filename = (* separates extension from filename *)
  let i = ref 0 in
  while !i < String.length filename && filename.[!i] <> '.' do
    i := !i + 1
  done;
  String.sub filename 0 (!i)

let write_label oc msg =
  if !errors = 0 then
    fprintf oc "%s:\n" msg

let write_command oc msg =
  if !errors = 0 then
    fprintf oc "  %s\n" msg

let print_error file location message =
  eprintf "Error in file '%s' at '%t' :\n%s\n" file (CodeMap.Span.print location) message;
  errors := !errors + 1

let rec concat_string stringList =
  match stringList with
  | [] -> ""
  | (s, _) :: t -> s ^ concat_string t

let rec get_file_content infile =
  match input_line infile with
  | line -> String.trim line :: (get_file_content infile)
  | exception End_of_file -> []

let rec write_file oc text =
  match text with
  | [] -> fprintf oc "\n"
  | line :: text' ->
    begin
      if String.ends_with ~suffix:":" line then
        fprintf oc "%s\n" line
      else if String.length line > 0 then
        fprintf oc "  %s\n" line
      else
        fprintf oc "";

      write_file oc text'
    end

let optimize filename =
  let infile = open_in filename in
  let outfileOptimized = open_out (filename ^ ".opt") in
  let codeLines = get_file_content infile in
  let rec compute_optimizations lines =
    match lines with
    | [] -> []
    | [_] -> lines
    | line1 :: line2 :: t -> 
      begin
        if List.length t > 0 then begin
          let line3 = List.hd t in
          if String.ends_with ~suffix:":" line1 && String.starts_with ~prefix:"Goto" line2 && String.ends_with ~suffix:":" line3 && (* Label1: then Goto <name> then Label2: *)
          ((String.sub line2 5 (String.length line2 - 5)) = (String.sub line3 0 (String.length line3 - 1))) then (* and <name> = Label2 *)
            line1 :: (compute_optimizations t)
          else if (String.starts_with ~prefix:"Goto" line1 || String.starts_with ~prefix:"Sense" line1 || String.starts_with ~prefix:"Flip" line1) && String.starts_with ~prefix:"Goto" line2 then
            line1 :: (compute_optimizations t)
          else
            line1 :: (compute_optimizations (line2 :: t))
        end else begin
          line1 :: (compute_optimizations (line2 :: t))
        end
      end in
  write_file outfileOptimized (compute_optimizations codeLines);
  close_out outfileOptimized;
  close_in infile

let rec compile_file pathin oc program oldCurrentLabel =
  let labels = ref []
  and defines = ref []
  (*and calls = ref []*)
  and functions = ref []
  and inFunction = ref false
  and currentLabel = ref oldCurrentLabel in

  let (path, filename) = get_filename pathin in

  write_label oc (get_filename_without_ext filename);
  (* aux *)
  let look_in_labels label location = (* check whether a label exists or not *)
    let rec aux l e =
      match l with
      | [] -> ()
      | h :: _ when h = e -> print_error pathin location "Label was previously declared"
      | _ :: t -> aux t e in
    aux !labels label
  and look_in_defined defineList location = (* check whether an identifier is linked to an int *)
    let rec aux l e =
      match l with
      | [] -> 
        begin
          print_error pathin location ("Undeclared identifier '" ^ e ^ "'");
          0
        end
      | (d, v) :: _ when d = e -> v
      | _ :: t -> aux t e in
      let define = concat_string defineList in
    aux !defines define in
  let process_value value =
    match value with
    | Ast.Var (var, location) -> look_in_defined var location
    | Ast.Int (n, _) -> n in
  let get_direction direction =
    match direction with
    | Ast.Ahead -> "Ahead"
    | Ast.Here -> "Here"
    | Ast.Left -> "LeftAhead"
    | Ast.Right -> "RightAhead"
  and get_category category location =
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
          print_error pathin location "bit expects an integer between 0 and 5";
        "Marker " ^ (string_of_int bit)
      end
    | Ast.FoeMarker -> "FoeMarker"
    | Ast.Home -> "Home"
    | Ast.FoeHome -> "FoeHome" 
    | _ -> 
      begin
        print_error pathin location "Pattern not supported for now";
        "Error"
      end in
  (* aux *)
  let rec process_program program = (* processes type program *)
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
    | Ast.CommentProgram ((_, _), (prog, _)) ->
      begin
        match prog with
        | Some p -> process_program p
        | None -> ()
      end
  and process_preprocessor preprocessor = (* processes type preprocessor *)
    match preprocessor with
    | Ast.Define ((identList, _), (num, _)) -> 
      begin
        let ident = concat_string identList in
        print_string ("Defined " ^ ident ^ " as " ^ (string_of_int num) ^ "\n");
        defines := (ident, num) :: !defines
      end
    | Ast.Include (identList, location) ->
      begin
        let ident = concat_string identList in
        if not (Sys.file_exists (path ^ ident ^ ".ant")) then
          print_error pathin location ("File '" ^ ident ^ ".ant' does not exist");
        
        process_file (path ^ ident ^ ".ant") oc !currentLabel
      end
    | Ast.Org (_, _) -> ()
  and process_condition condition = (* processes type condition *)
    match condition with
    | Ast.Is ((category, location), (direction, _)) ->
      begin
        let condLabel = "_label" ^ (string_of_int !currentLabel) in
        write_command oc ("Goto " ^ condLabel);
        write_label oc condLabel;

        currentLabel := !currentLabel + 1;

        let rec process_category category location =
          match category with
          | Ast.Not (nestedCategory, loc) ->
            begin
              let (_, thenLabel, elseLabel) = process_category nestedCategory loc in
              (condLabel, elseLabel, thenLabel)
            end
          | Ast.Or ((nestedCategory1, loc1), (nestedCategory2, loc2)) ->
            begin
              let (_, thenLabel1, elseLabel1) = process_category nestedCategory1 loc1 in
              write_command oc ("Goto " ^ elseLabel1);
              write_label oc elseLabel1;
              let (_, thenLabel2, elseLabel2) = process_category nestedCategory2 loc2 in
              write_command oc ("Goto " ^ thenLabel2);
              write_label oc thenLabel2;

              (condLabel, thenLabel1, elseLabel2)
            end
          | Ast.And ((nestedCategory1, loc1), (nestedCategory2, loc2)) ->
            begin
              let (_, thenLabel1, elseLabel1) = process_category nestedCategory1 loc1 in
              write_command oc ("Goto " ^ thenLabel1);
              write_label oc thenLabel1;
              let (_, thenLabel2, elseLabel2) = process_category nestedCategory2 loc2 in
              write_command oc ("Goto " ^ elseLabel2);
              write_label oc elseLabel2;
              write_command oc ("Goto " ^ elseLabel1);
              write_label oc thenLabel2;

              (condLabel, thenLabel1, elseLabel1)
            end
          | _ -> 
            begin
              let condLabel' = "_label" ^ (string_of_int !currentLabel)
              and thenLabel = "_label" ^ (string_of_int (!currentLabel + 1))
              and elseLabel = "_label" ^ (string_of_int (!currentLabel + 2)) in
              write_command oc ("Goto " ^ condLabel');
              write_label oc condLabel';
              write_command oc ("Sense " ^ (get_direction direction) ^ " " ^ thenLabel ^ " " ^ elseLabel ^ " " ^ (get_category category location));

              currentLabel := !currentLabel + 3;
              (condLabel, thenLabel, elseLabel)
            end in
        process_category category location;
      end
    | Ast.RandInt ((value, location1), (n, location2)) -> 
      begin
        let p = process_value value in
        if p = 0 then
          print_error pathin location1 "Argument in randint must be non-zero";
        
        if n >= p then
          print_error pathin location2 "Randint(p) can only be compared with a number between 0 and p - 1";
        
        let condLabel = "_label" ^ (string_of_int !currentLabel)
        and thenLabel = "_label" ^ (string_of_int (!currentLabel + 1)) 
        and elseLabel = "_label" ^ (string_of_int (!currentLabel + 2)) in
        write_command oc ("Goto " ^ condLabel);
        write_label oc condLabel;
        write_command oc ("Flip " ^ (string_of_int p) ^ " " ^ thenLabel ^ " " ^ elseLabel);

        currentLabel := !currentLabel + 3;
        (condLabel, thenLabel, elseLabel)
      end
  and process_control control = (* processes type control *)
    match control with
    | Ast.Label (nameList, _) -> 
      begin
        let name = concat_string nameList in
        labels := name :: !labels;

        write_command oc ("Goto " ^ name);
        write_label oc name
      end
    | Ast.IfThenElse ((condition, _), (thenBody, _), (elseBody, _)) -> 
      begin
        let (_, thenLabel, elseLabel) = process_condition condition
        and label3 = "_label" ^ (string_of_int (!currentLabel)) in
        currentLabel := !currentLabel + 1;

        write_command oc ("Goto " ^ thenLabel);
        write_label oc thenLabel;
        
        process_program thenBody;

        write_command oc ("Goto " ^ label3);
        write_label oc elseLabel;

        process_program elseBody;

        write_command oc ("Goto " ^ label3);
        write_label oc label3
      end
    | Ast.IfThen ((thenBody, _), (condition, _)) -> 
      begin
        let (_, thenLabel, elseLabel) = process_condition condition in
        write_command oc ("Goto " ^ thenLabel);
        write_label oc thenLabel;
        
        process_program thenBody;

        write_command oc ("Goto " ^ elseLabel);
        write_label oc elseLabel
      end
    | Ast.Func ((nameList, loc1), (args, loc2), (funcBody, _)) -> 
      begin (* assuming there is no args for now *)
      let name = concat_string nameList in
        look_in_labels name loc1;

        if List.length args > 0 then
          print_error pathin loc2 "Arguments are not supported yet";
        
        let label = "_label" ^ (string_of_int !currentLabel) in

        labels := name :: !labels;
        functions := name :: !functions;
        let addLabel = if !inFunction then true else false in

        if addLabel then begin (* that way a function declared inside another function doesn't get executed directly *)
          write_command oc ("Goto " ^ label);
          currentLabel := !currentLabel + 1
        end;
        
        inFunction := true;
        
        (* write_command oc ("Goto " ^ name); *)
        write_label oc name;
        process_program funcBody;
        write_command oc ("Goto " ^ name);

        if addLabel then begin
          write_label oc label
        end;
        
        functions := List.tl !functions;
        inFunction := false
      end
    | Ast.While ((condition, _), (whileBody, _)) ->
      begin
        let (whileLabel, thenLabel, elseLabel) = process_condition condition in
        write_command oc ("Goto " ^ thenLabel);
        write_label oc thenLabel;
        
        process_program whileBody;

        write_command oc ("Goto " ^ whileLabel);
        write_label oc elseLabel
      end
    | Ast.Repeat ((value, _), (repeatBody, _)) ->
      begin (* for now assume cond is a number *)
        let num = process_value value in
        for _ = 1 to num do
          process_program repeatBody
        done
      end
    | Ast.Switch ((category, loc1), (switchBody, _)) -> 
      begin
        let endSwitchLabel = "_label" ^ (string_of_int !currentLabel) in
        currentLabel := !currentLabel + 1;

        let rec process_cases cases =
          match cases with
          | [] -> write_command oc ("Goto " ^ endSwitchLabel)
          | (Ast.Case ((direction, loc2), (program, _)), _) :: nextCases -> 
            begin
              let (_, thenLabel, elseLabel) = process_condition (Ast.Is ((category, loc1), (direction, loc2))) in
              write_command oc ("Goto " ^ thenLabel);
              write_label oc thenLabel;

              process_program program;

              write_command oc ("Goto " ^ endSwitchLabel);
              write_label oc elseLabel;

              process_cases nextCases
            end in
        process_cases switchBody;

        write_command oc ("Goto " ^ endSwitchLabel);
        write_label oc endSwitchLabel
      end
  and process_expression expression = (* processes type expression *)
    match expression with
    | Ast.Args (_, _) -> ()
    | Ast.Move ((value, _), (onErrorOption, _)) ->
      begin
        let num = process_value value in
        let label = "_label" ^ (string_of_int (!currentLabel)) in
        let labelOnError = 
          match onErrorOption with
          | Some (Ast.LabelOnError (identList, _)) -> concat_string identList
          | None -> label in

        for _ = 1 to num do
          write_command oc ("Move " ^ labelOnError) 
        done;

        currentLabel := !currentLabel + 1;

        write_command oc ("Goto " ^ label);
        write_label oc label
      end
    | Ast.Turn (value, _) -> 
      begin
        let num = process_value value in
        let i = num mod 6 in
        let dir = [|"Right"; "Left"|] in
        for _ = 1 to i - 2*(i/4)*(i-3) do
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
    | Ast.Goto (labelList, _) -> 
      begin
        let label = concat_string labelList in
        write_command oc ("Goto " ^ label)
      end
    | Ast.Mark (value, location) -> 
      begin
        let num = process_value value in
        if num > 5 || num < 0 then
          print_error pathin location "Mark expects a number between 0 and 5"
        else
          write_command oc ("Mark " ^ (string_of_int num))
      end
    | Ast.Unmark (value, location) -> 
      begin
        let num = process_value value in
        if num > 5 || num < 0 then
          print_error pathin location "UnMark expects a number between 0 and 5"
        else
          write_command oc ("Unmark " ^ (string_of_int num))
      end
    | Ast.Call (identList, _) -> 
      begin
        let ident = concat_string identList in
        write_command oc ("Goto " ^ ident);
        (*calls := (ident, List.hd !functions) :: !calls*)
      end
    | Ast.Nop -> () (* does nothing *)
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

and process_file pathin oc oldCurrentLabel =
  let new_filename = Pre_lexer.pre_lexer pathin in
  (* Ouvre le fichier et créé un lexer. *)
  let file = open_in new_filename in
  let lexer = Lexer.of_channel file in
  (* Parse le fichier. *)
  let (program, _) = Parser.parse_program lexer in
  (*printf "successfully parsed the following program at position %t:\n%t\n" (CodeMap.Span.print span) (Ast.print_program program);*)
  let currentErrors = !errors in
  compile_file pathin oc program oldCurrentLabel;

  printf "Compilation of '%s' ended with %d errors\n" pathin (!errors - currentErrors)

(* Le point de départ du compilateur. *)
let _ =
  (* On commence par lire le nom du fichier à compiler passé en paramètre. *)
  if Array.length Sys.argv <= 1 then begin
    (* Pas de fichier... *)
    eprintf "An argument is missing\nUsage : %s <filename> [-O<number>]\n" (Sys.argv.(0));
    exit 1
  end else begin
    let optimizationRounds = 
      if Array.length Sys.argv > 2 && String.starts_with ~prefix:"-O" Sys.argv.(2) then begin
        let arg1length = String.length Sys.argv.(2) in
        if arg1length > 2 then begin
          let num = (String.sub Sys.argv.(2) 2 (arg1length - 2)) in
          match int_of_string_opt num with
          | Some i -> i
          | None -> 
            begin
              eprintf "'%s' is not a valid number\n" num;
              exit 1
            end
        end else begin
          eprintf "Usage : %s <filename> [-O<number>]\n" Sys.argv.(0);
          exit 1
        end 
      end else
        0
      in

    try
      (* On compile le fichier. *)
      let pathout = ((get_filename_without_ext Sys.argv.(1))) in
      let oc = open_out (pathout ^ ".brain") in
      process_file (Sys.argv.(1)) oc 0;

      close_out oc;

      if !errors <> 0 then (* removes file if there was any error *)
        begin
          Sys.remove (pathout ^ ".brain");
        end
      else
        begin
          let _ = Sys.command ("rm " ^ pathout ^ ".antpl") in

          for i = 1 to optimizationRounds do
            printf "Optimization round %d of %d...\n" i optimizationRounds;

            optimize (pathout ^ ".brain");
            let _ = Sys.command ("rm " ^ pathout ^ ".brain && " ^ "mv " ^ pathout ^ ".brain.opt " ^ pathout ^ ".brain") in
            ()
          done
        end
    with
    | Lexer.Error (e, span) ->
      eprintf "Lex error: %t: %t\n" (CodeMap.Span.print span) (Lexer.print_error e)
    | Parser.Error (e, span) ->
      eprintf "Parse error: %t: %t\n" (CodeMap.Span.print span) (Parser.print_error e)
  end
