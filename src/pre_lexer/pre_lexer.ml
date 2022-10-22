(* Pre lexer pour implémenter des variables *)

(* définition de fonctions *)
Printf.printf "Entrée définition des fonctions \n";
let rec is_in a l =
  match l with
  | h::t -> if h = a then true else is_in a t
  | [] -> false in

let rec _browse_line_init l i var_current val_init val_possible =
match (l,i) with
  | (a::q, 0) -> _browse_line_init q (i+1) (a::var_current) val_init val_possible
  | (a::q, 1) -> _browse_line_init q (i+1) var_current (a::val_init) val_possible
  | (a::q, _) -> _browse_line_init q (i+1) var_current val_init (a::val_possible)
  | ([],_) ->  (var_current, val_init, val_possible) in

let browse_line_init l =
  _browse_line_init l 0 [] [] [] in

(* let rec browse_line_assignment line = () in *)

(* convert the index in the the complete_file to values of each variable *)
let _values_of_index var i nb_var prod =
  let values = ref [] in
  for p = 0 to nb_var - 1 do
    let var_current, val_possible, l_val_possible = var.(i) in
    values := (var_current, val_possible.(((i - (i mod prod)) / prod ) mod l_val_possible) )::!values;
  done;
  !values in

let values_of_index var i nb_var =
  _values_of_index var i nb_var 1 in

(* let index_of_values var = () in *)

let rec string_of_values values =
  match values with
  | (var, values)::q -> var ^ "_" ^ values ^ "_" ^ (string_of_values q)
  | [] -> "end"
in

let add t len_arr s =
  for i = 0 to len_arr-1 do
    t.(i) <- t.(i)^s;
  done; in

let rec change_value values var_name new_value =
  match values with
  | (v_name, v)::q when v_name = var_name -> (v_name, new_value) :: (change_value values var_name new_value)
  | h::t -> h :: (change_value values var_name new_value)
  | [] -> [] in

let add_value_related t l_t var nb_var var_name new_value =
  for i = 0 to l_t - 1 do
    let values = values_of_index var i nb_var in
    if new_value == "#"
    then (let s = string_of_values values in t.(i) <- t.(i)^s;)
    else (let s = string_of_values (change_value values var_name new_value) in t.(i) <- t.(i)^s;);
  done; in

let write_file final_file l_final_file file_name var nb_var header = 
  let file = open_out file_name in
  output_string file header;
  for i = 0 to l_final_file - 1 do
    let values = values_of_index var i nb_var in
    let s = string_of_values values in
    
    output_string file (Printf.sprintf "label_%s : \n" s);
    output_string file final_file.(i);
  done;  
in 
Printf.printf "Sortie définition des fonctions \n";

let test = ref true in

(* lecture des définitions de variables au début du programme *)
(* let nb_var = ref 0 in *)
Printf.printf "\n Début du programme \n";
Printf.printf "\n Ouverture du fichier \n";
let file = open_in "src/pre_lexer/0_test_pre_lexer.ant" in
let line = input_line file in

let var_list = ref [] in
let values_init = ref [] in
let nb_var = ref 0 in
let l_final_file = ref 0 in

Printf.printf "\n Début de l'initialisation \n";
while ((line.[0] = 'v') && (line.[1] = 'a') && (line.[2] = 'r')) do
  nb_var := !nb_var + 1;
  let line_sep = line
    |> String.split_on_char ' '
    |> List.filter (fun s -> (s <> "") || (s <> "var") || (s <> "=") || (s <> "in") || (s <> ";")) in  

  let var_current, val_init, val_possible = browse_line_init line_sep in
  l_final_file := List.length val_possible * !l_final_file;
  let array_val_possible = Array.of_list val_possible in
  var_list := (List.hd var_current,  array_val_possible, Array.length array_val_possible) :: !var_list;
  values_init := (List.hd var_current, List.hd val_init) :: !values_init;
done;
Printf.printf "Fin de l'initialisation \n";


(* var contient toutes les informations de l'initialisation *)
let var = Array.of_list !var_list in
(* lecture du fichier complet *)
let final_file = Array.make !l_final_file "" in
let time = ref 0 in
let header = Printf.sprintf "goto label_%s :" (string_of_values !values_init)  in

Printf.printf "Début lecture de ligne hors init \n";
while (!test) do
let line = try input_line file with End_of_file -> test := false; "" in
let line_trim = String.trim line in
let line_split = line_trim |> String.split_on_char ' ' in
let line_simple = line_split |> List.filter (fun s -> (s <> "=" || s <> "var" || s <> "if" || s <> "func" || s <> "++")) in
if (is_in "#" line_split || (String.length line_trim = 0))
then (* on ne réecrit pas les commentaires *)()
else (
  if (is_in "var" line_split)
  then (
    (* a var line to process *)
    if (is_in "if" line_split)
      then (
        (* gérer les var if *)()
      )
      else if (is_in "++" line_split)
      then (
        (* gérer une incrémentation *)

      )
      else (
        (* gérer une assignation *)
        (* write > goto time_1_x_1_y_2_ for the second assignment and go where
        x is 1 and y 2 *)
        let var_name = line_simple |> List.hd in
        let value = line_simple |> List.tl |> List.hd in
        add final_file !l_final_file (Printf.sprintf "goto time_%d_" !time);
        add_value_related final_file !l_final_file var !nb_var var_name value;
        add final_file !l_final_file ";\n";

        (* write > time_1_x_1_y_2_ : *)
        add final_file !l_final_file (Printf.sprintf "time_%d_" !time);
        add_value_related final_file !l_final_file var !nb_var var_name "#";
        add final_file !l_final_file " : \n";
        time := !time + 1;
        )
  )
  else if (is_in "func" line_split)
    then (
      (* rename every func for each label zone *)
    )
  else if (is_in "call" line_split)
  then (
    (* rename every call for each label zone *)
  )
  else (
    add final_file !l_final_file line;
  )       
)

done;


(* let () = print_string "file name : " in
let new_file_name = read_line () in *)
Printf.printf "\nDébut écriture fichier \n";
write_file final_file !l_final_file "src/pre_lexer/0_test_pre_compil.ant" var !nb_var header;
Printf.printf "Fin écriture fichier \n";