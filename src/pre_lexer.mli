
(* Pre lexer *)
(* le pre lexer va gérer les varibles et les commentaires et fait
   une première étape de la compilation
   on passe filename.ant -> filename.antpl pl pour pre lexer *)

(* la fonction pre_lexer prend en argument le nom du fichier .ant
   et renvoie le nom du fichier modifié .antpl*)

val pre_lexer : string -> string