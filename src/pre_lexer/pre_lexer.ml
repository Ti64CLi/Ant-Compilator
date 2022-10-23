(* Pre lexer pour implémenter des variables *)

(* Définition des types *)

(* définition de fonctions *)

let rec is_in a l =
  match l with
  | h::t -> if h = a then true else is_in a t
  | [] -> false in

let rec _print_string_list l =
  match l with
  | h::t -> Printf.printf "\"%s\", " h; _print_string_list t
  | [] -> () in

let print_string_list l =
  Printf.printf "[ ";
  _print_string_list l;
  Printf.printf " ] \n"; in

let rec _browse_line_init l i var_current val_init val_possible =
match (l,i) with
  | (a::q, 0) -> _browse_line_init q (i+1) (a::var_current) val_init val_possible
  | (a::q, 1) -> _browse_line_init q (i+1) var_current (a::val_init) val_possible
  | (a::q, _) -> _browse_line_init q (i+1) var_current val_init (a::val_possible)
  | ([],_) ->  (var_current, val_init, List.rev val_possible) in

let browse_line_init l =
  _browse_line_init l 0 [] [] [] in

(* convert the index in the the complete_file to values of each variable *)
let _values_of_index var i nb_var prod =
  let values = ref [] in
  for p = 0 to nb_var - 1 do
    let var_current, val_possible, l_val_possible = var.(p) in
    values := (var_current, val_possible.(((i - (i mod !prod)) / !prod ) mod l_val_possible) )::!values;
    prod := !prod * l_val_possible;
  done;
  !values in

let values_of_index var i nb_var =
  _values_of_index var i nb_var (ref 1) in

(* let index_of_values var = () in *)

let rec string_of_values values =
  match values with
  | (var, value)::q -> var ^ "_" ^ value ^ "_" ^ (string_of_values q)
  | [] -> "end"
in

let rec _compatible_forced_values var_name value values =
  match values with
  | (v_name, v)::t when v_name = var_name -> value = v
  | h :: t -> _compatible_forced_values var_name value t
  | [] -> true in

let rec compatible_forced_values values1 values2 =
  match values1 with
  | (var_name, value) :: t -> _compatible_forced_values var_name value values2
                             && compatible_forced_values t values2
  | [] -> true in

let rec _compatible_banned_values var_name value values = 
  match values with
  | (v_name, v)::t when v_name = var_name -> value <> v
  | h :: t -> _compatible_banned_values var_name value t
  | [] -> true in

let rec compatible_banned_values banned_values values =
  match banned_values with
  | (var_name, value) :: t -> _compatible_banned_values var_name value values
                             && compatible_banned_values t values
  | [] -> true in  

let rec change_value values var_name new_value =
  match values with
  | (v_name, v)::t when v_name = var_name -> (v_name, new_value) :: t
  | h::t -> h :: (change_value t var_name new_value)
  | [] -> [] in

let add forced_values banned_values t len_arr s var nb_var =
  for i = 0 to len_arr-1 do
    let values = values_of_index var i nb_var in
    if (compatible_forced_values forced_values values && compatible_banned_values banned_values values)
    then (t.(i) <- t.(i)^s;)
  done; in

let add_value_related forced_values banned_values t l_t var nb_var var_name new_value =
  for i = 0 to l_t - 1 do
    let values = values_of_index var i nb_var in
    if (compatible_forced_values forced_values values && compatible_banned_values banned_values values)
    then (
    if new_value = "#"
    then (let s = string_of_values values in t.(i) <- t.(i)^s;)
    else (let s = string_of_values (change_value values var_name new_value) in t.(i) <- t.(i)^s;);
    )
  done; in


let incr_value_related forced_values banned_values t l_t var nb_var var_name new_value =
  for i = 0 to l_t - 1 do
    let values = values_of_index var i nb_var in
    let s = string_of_values values in t.(i) <- t.(i)^s;
  done; in

(* let incr_value values var value = () in *) 

let write_file final_file l_final_file file_name var nb_var header = 
  let file = open_out file_name in
  output_string file header;
  for i = 0 to l_final_file - 1 do
    let values = values_of_index var i nb_var in
    let s = string_of_values values in
    
    output_string file (Printf.sprintf "\nlabel_%s : \n" s);
    output_string file final_file.(i);
  done;  
in 

let get_line file separator line line_trim line_split line_filtered test =
  let test_line = try input_line file with End_of_file -> test := false; "" in
  line := test_line;
  line_trim := String.trim !line;
  line_split := !line_trim |> String.split_on_char ' ';
  line_filtered := !line_split |> List.filter (fun s -> not(is_in s separator)); in

let read_header file separator test_init test var_list values_init nb_var l_final_file line line_trim line_split line_filtered =
  while (!test_init && !test) do
    if (is_in "var" !line_split)
    then (
      nb_var := !nb_var + 1;

      let var_current, val_init, val_possible = browse_line_init !line_filtered in
      let l = List.length val_possible in
      
      Printf.printf "val_possible = ";
      print_string_list val_possible;
      
      l_final_file := l * !l_final_file;
      let array_val_possible = Array.of_list val_possible in
      var_list := (List.hd var_current, array_val_possible, l) :: !var_list;
      values_init := (List.hd var_current, List.hd val_init) :: !values_init;
      get_line file separator line line_trim line_split line_filtered test;
    )
    else (
      test_init := false;
    )
  done; in

let rec read_file forced_values banned_values separator var time final_file file test_init test var_list values_init nb_var l_final_file line line_trim line_split line_filtered =
  while (!test) do
    if (is_in "#" !line_split || (String.length !line_trim = 0) || is_in "beginthen" !line_split || is_in "beginelse" !line_split)
    then ((* (suppresion of comments) or (empty line) or (begin of an then or else) *))
    else if (is_in "endthen" !line_split || is_in "endelse" !line_split)
    then (
    (* deal with the begin and end of then ans else *)
    test := false;
    )
    else if (is_in "var" !line_split)
    then (
        (* var line to process *)
        Printf.printf "In var \n";
        if (is_in "if" !line_split)
          then (
            Printf.printf "In if \n";
            (* var if to process *) 
            let var_name, value = (List.hd !line_filtered, !line_filtered |> List.tl |> List.hd)in
            (* process  then *)
            Printf.printf "In Then";
            get_line file separator line line_trim line_split line_filtered test;
            read_file ((var_name, value)::forced_values) banned_values separator var time final_file file test_init test var_list values_init nb_var l_final_file line line_trim line_split line_filtered;
            test := true;

            (* process else *)
            Printf.printf "In Else";
            get_line file separator line line_trim line_split line_filtered test;
            read_file forced_values ((var_name, value)::banned_values) separator var time final_file file test_init test var_list values_init nb_var l_final_file line line_trim line_split line_filtered;
            test := true;
            )
          else if (is_in "++" !line_split)
          then (
            Printf.printf "In ++ \n";
            (* gérer une incrémentation *)
            (* incr_value_related final_file !l_final_file var !nb_var; *)
            add forced_values banned_values final_file !l_final_file (Printf.sprintf "goto time_%d_" !time) var !nb_var;
            incr_value_related forced_values banned_values final_file !l_final_file var !nb_var "" "";
            add forced_values banned_values final_file !l_final_file ";\n" var !nb_var;
  
            (* write the time label *)
            add forced_values banned_values final_file !l_final_file (Printf.sprintf "time_%d_" !time) var !nb_var;
            add_value_related forced_values banned_values final_file !l_final_file var !nb_var "" "#";
            add forced_values banned_values final_file !l_final_file " : \n" var !nb_var;
            time := !time + 1;
          )
          else (
            Printf.printf "In assignation \n";
            (* gérer une assignation *)
            (* write > goto time_1_x_1_y_2_ for the second assignment and go where
            x is 1 and y 2 *)
            let var_name = !line_filtered |> List.hd in
            let new_value = !line_filtered |> List.tl |> List.hd in
            add forced_values banned_values final_file !l_final_file (Printf.sprintf "goto time_%d_" !time) var !nb_var;
            add_value_related forced_values banned_values final_file !l_final_file var !nb_var var_name new_value;
            add forced_values banned_values final_file !l_final_file ";\n" var !nb_var;
  
            (* write > time_1_x_1_y_2_ : *)
            add forced_values banned_values final_file !l_final_file (Printf.sprintf "time_%d_" !time) var !nb_var;
            add_value_related forced_values banned_values final_file !l_final_file var !nb_var "" "#";
            add forced_values banned_values final_file !l_final_file " : \n" var !nb_var;
            time := !time + 1;
            )
      )
    else if (is_in "func" !line_split)
      then (
        Printf.printf "In func \n";
        (* rename every func for each label zone *)
      )
    else if (is_in "call" !line_split)
    then (
      Printf.printf "In Call \n";
      (* rename every call for each label zone *)
    )
    else (
      Printf.printf "In normal line \n";
      add forced_values banned_values final_file !l_final_file (!line^"\n") var !nb_var;
    );
  get_line file separator line line_trim line_split line_filtered test;  
  done;
in

let pre_lexer file_name =
  Printf.printf "Begin programm \n";
  
  Printf.printf "Open File \n";
  let file = open_in file_name in

  let separator = [""; "var"; "="; "in"; "=="; "if"; "func"; "++"; ";"; "{"; "}"] in
  let test_init = ref true in
  let test = ref true in
  let var_list = ref [] in
  let values_init = ref [] in
  let nb_var = ref 0 in
  let l_final_file = ref 1 in
  let line = ref "" in
  let line_trim = ref "" in
  let line_split = ref [] in
  let line_filtered = ref [] in

  get_line file separator line line_trim line_split line_filtered test;

  (* Read of the Header *)
  Printf.printf "\nIn read_header \n";
  read_header file separator test_init test var_list values_init nb_var l_final_file line line_trim line_split line_filtered;

  (* var contient toutes les informations de l'initialisation *)
  let var = Array.of_list !var_list in
  let final_file = Array.make !l_final_file "" in
  let time = ref 0 in
  values_init := List.rev !values_init;
  let header = Printf.sprintf "goto label_%s ;\n" (string_of_values !values_init) in

  (* Read of the File *)
  Printf.printf "\nIn read_file \n";
  read_file [] [] separator var time final_file file test_init test var_list values_init nb_var l_final_file line line_trim line_split line_filtered;


  Printf.printf "\nIn write file \n";
  let new_file_name = (file_name^"pl") in
  write_file final_file !l_final_file new_file_name var !nb_var header;
  new_file_name
  in 


let () = print_string "version_test : " in
let version_test = read_line () in
let file_name = version_test^"_test_pre_lexer.ant" in
let a = pre_lexer file_name in ();