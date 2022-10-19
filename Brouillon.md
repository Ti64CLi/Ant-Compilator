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
-s'il n'y a qu'une exploration : 			1 info (*6 si distinction)
-s'il y a de la nouriture (directions ? )	6 infos
-où est la maison (direction ?) 			6 infos
-s'il y a des ennemis (trace ?)				6 infos (*2 si distinctions)
-s'il y a des murs							1 infos
-s'il n'y a plus de nourriture (moins de chance d'en trouver) 6 infos

total au plus d'infos : 37
total max d'infos : 63



	réfléxions:

L'objectif est de considérer des phases où la fourmi est orienté dans le même sens ou dans le sens opposé à celle indiqué par la case. Ainsi, la fourmi sait à chaque instant que la direction dans laquelle elle regarde est soit la direction pointée, soit la direction oposée à celle pointé ( en fonction de son mode (rentrer à la maison par exemple))
Pour rentrer à la maison, la fourmi est orientée selon la direction indiquée. Elle regarde la case de devant et compare la valeur de celle-ci à la sienne. En fonction, elle s'avance et se tourne d'une certaine manière. Ainsi fait, elle est de nouveau orientée vers la direction pointée par la case

Lors d'un croisement, la fourmi avec de la nouriture ou rentrant à la base est prioritaire. Sinon, les deux se décalent. Quand une fourmi se décale, elle contourne par le même côté (droite par exemple).

Pour avoir une certaine proportion de fourmis qui attaquent/défendent/cehrchent/récupère etc... Il suffit de leur faire tirer aléatoirement une fonction. Pour un nombre suffisaznt de fourmis, il y aura statistiquement une proportion correspondant à cette proba donnée.

On peut crée un mod qui parcours le tour de la base etcherche dans quelle direction il y a de la nourriture/des ennemis etc... et aurait une certaine proba de la suivre (pour éviter d'envoyer toutes les fourmis dans cette direction)

	idée de réaction:

S'il y a des fourmis ennemis, une certaine quantité de fourmis peuvent s'organiser pour former un mur, empêchant les fourmis ennemis de trop s'approcher, tout en contrôlant leur potentielle attaque (à caondistion d'avoir suffisemment de fourmis)

La forme de la base étant connue, une fourmi à l'instant initial pointe vers l'est. Ainsi, une fourmi sur un des bords de la base peut marquer une direction donnée. De ce fait, une fourmi qui se retrouve sur le bord saurait la direction (le numéro de la case), et dans quelle direction pointe ce numéro (la donné de la frontière de la base). Ce la permet de créer un mémoire à l'intérieure de la base en abandonnant l'information de la direction (qui est donc retrouvée sur le bord)



	remarques:

Quelque soit le mode d'une fourmis, elle ne doit surtout pas oublier dans quelle direction pointe la case. Ainsi, lorsqu'elle se tourne pour une fonction, l'on doit créer 6 fonctions différentes selon combien de fois elle s'est tournée par rapport à l'orientation de base.

À l'instant initial, chaque fourmi pointe vers la même direction, qui devient la direction de base.

Il faudra essayer d'autre statégie qui ne marque pas toujours les directions, et ferait donc un parcours semi-aléatoire en suivant une direction marquée par exemple. Cela pourrait permettre de tester si des informations qu'on n'aurait pas pus mettre initialement sont plus ou moins importantes.

Pour garder l'information de la direction, il est nécessaire qu'un mode "sortie" soit exécutée en premier, et uniquement en premier pour écrire sur la base jsute le temps de sortir. Il faut également optimiser ce passagepour sortir le plus efficacement.

Une fois cette étape de faite, l'information "être dans la base" correspond à un bit supplémentaire, et permet donc d'encoder 64 informations différentes.