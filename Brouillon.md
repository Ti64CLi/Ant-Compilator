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

Il faut qu'avec une proba, les fourmis testent s'il y a des traces ennemis.

L'orientation correspond à l'une des 6 copies du code, avec seul la donnée de l'orientation qui change. L'orientation de base est l'est, celle pointée à l'origine.

Lors d'un croisement, la fourmi avec de la nouriture ou rentrant à la base est prioritaire. Sinon, les deux se décalent. Quand une fourmi se décale, elle contourne par le même côté (droite par exemple) pour se contourner.

Pour avoir une certaine proportion de fourmis qui attaquent/défendent/cehrchent/récupère etc... Il suffit de leur faire tirer aléatoirement une fonction. Pour un nombre suffisaznt de fourmis, il y aura statistiquement une proportion correspondant à cette proba donnée.

On peut crée un mod qui parcours le tour de la base et cherche dans quelle direction il y a de la nourriture/des ennemis etc... (grâce aux marquages) et aurait une certaine proba de la suivre (pour éviter d'envoyer toutes les fourmis dans cette direction)
Une autre idée serait de considérer un ordre d'importance sur les informations (par ex, Friend < Food < FriendWithFood < Foe etc....). À l'intérieur de la base, si plusieurs cases pointent vers une même case, cette dernière aura pour valeur l'information prioritaire. Cela permet donc d'avoir une sorte d'arbre de dictionnaire, et rediriger les fourmis selon leur rôle et leur importance.

	idée de réaction:

S'il y a des fourmis ennemis, une certaine quantité de fourmis peuvent s'organiser pour former un mur, empêchant les fourmis ennemis de trop s'approcher, tout en contrôlant leur potentielle attaque (à caondistion d'avoir suffisemment de fourmis)

l'intérieur de la base est marquée, et agit donc comme une information supplémentaire. De ce fait, de nouvelles informations peuvent être encodées.



	remarques:

Quelque soit le mode d'une fourmis, elle ne doit surtout pas oublier dans quelle direction pointe la case. Ainsi, lorsqu'elle se tourne pour une fonction, l'on doit créer 6 fonctions différentes selon combien de fois elle s'est tournée par rapport à l'orientation de base.

À l'instant initial, chaque fourmi pointe vers la même direction, qui devient la direction de base.

Il faudra essayer d'autre statégie qui ne marque pas toujours les directions, et ferait donc un parcours semi-aléatoire en suivant une direction marquée par exemple. Cela pourrait permettre de tester si des informations qu'on n'aurait pas pus mettre initialement sont plus ou moins importantes.

Pour garder l'information de la direction, il est nécessaire qu'un mode "sortie" soit exécutée en premier, et uniquement en premier pour écrire sur la base jsute le temps de sortir. Il faut également optimiser ce passagepour sortir le plus efficacement.

Une fois cette étape de faite, l'information "être dans la base" correspond à un bit supplémentaire, et permet donc d'encoder 64 informations différentes.