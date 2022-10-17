Fonctions à définir dans Ant:

-Label : label
-Goto label
-If cond Is dir Then expr1 Else expr2
-Mark i
-Unmark i
-PickUp Fun
-Drop 
-Turn i  (négatif = gauche + opti (modulo 6))
-Flip p Fun1 Fun2 (0 → Fun1)
-Move 

-Fun Name {}
-Look dir If cond
-Ifnot ...




Fonctions aux :

-prend le nombre courant et renvoie l’une des 64 fonctions
-insère un nombre dans la case courante1
-regarde une direction, et compare le résultat à toutes les possibilités et retourne une fonction en retour
-test mur
-test des cases autour → priorité aux valeurs les plus probables


exemple de fonction comme je voudrait le faire :


search :
	Look Ahead if  Foe Do Attack
	Look Ahead If food  Do Food_ahead
	Look left If food Do Food_left
	Look right If food Do Food_right
	If Rock Is Ahead Then Wall Else Run
	Goto Search

Fun Run{
	Move Attendre }

Food_left:
	Turn left
	Goto Food_ahead

Food_right :
	Turn right
	Goto Food_ahead

Food_ahead :
	Move Attendre
	PickUp search
	Goto Return_home


Func check_food(dir) {
	Look dir If food Do {
		look dir ;
		}
}




Listes des informations que l'on aimerait bien contenir dans les bit(e)s d'une case:
-s'il n'y a qu'une exploration
-s'il y a de la nouriture (directions ?)
-où est la maison (direction ?)
-s'il y a des ennemis
-s'il y a des murs
-s'il n'y a plus de nourriture (moins de chance d'en trouver)
