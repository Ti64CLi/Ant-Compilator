(* Pre lexer pour implémenter des variables *)
let file = open_in "test.ant" in
let line = input_line file in

let rec browse_line_init l i var_current val_init val_possible =
  match (l,i) with
  | (a::q, 0) -> browse_line_init q (i+1) (a::var_current) val_init val_possible
  | (a::q, 1) ->  browse_line_init q (i+1) var_current (a::val_init) val_possible
  | (a::q, _) -> browse_line_init q (i+1) var_current val_init (a::val_possible)
  | ([],_) ->  (var_current, val_init, val_possible) in

let test = true in 

(* lecture des définitions de variables au début du programme *)
let nb_var = ref 0 in
let var = ref [] in
while ((line.[0] = 'v') && (line.[1] = 'a') && (line.[2] = 'r')) do
  nb_var := !nb_var + 1;
  let line_sep = line 
    |> String.split_on_char ' '
    |> List.filter (fun s -> (s <> "") || (s <> "var") || (s <> "=") || (s <> "in") || (s <> ";")) in  
  let l_line_sep = List.length line_sep in
  nb_var := l_line_sep - 3;

  let var_current, val_init, val_possible = browse_line_init line_sep 0 [] [] [] in
  var := (var_current, val_possible) :: !var;
  done;

  while (test) do
  (* lecture du fichier *)
  let time = ref 0 in
  let line = input_line file in
  let l_line = String.length line in
  if (l_line < 3)
  then
    begin
    
    end
  else
    begin
    if (line.[0] = 'v' && line.[1] = 'a' && line.[2] = 'r')
    then 
      (* a line to process *)
      begin
        if (true)
        then ()
        else ()
      end
    else
      (* on recopie la ligne dans tous les labels *)
      begin
      end
      
  end
done;