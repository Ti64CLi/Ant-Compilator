# Projet Fourmis

Equipe Antstein :
- Paul ADAM
- Adrien DECOSSE
- Elie DUMONT

---

## Objectifs :
- créer un language intuitif pour écrire le cerveau d'une fourmis
    - créer une grammaire efficace et clair
- écrire un compilateur qui nous traduit nos lignes de code en assembleur fourmis
- écrire une "bonne" stratégie pour les fourmis

## Grammaire :

##preprogramme:

-
```include Name``` inclue au début du programme le fichier Name.ant

-
```define name as va``` donne à name la valeur val

## Utilisation de base:

-```Name:``` et -```Goto Name``` permettent de créer un label et d'aller à un label

- ```/* commentaire */``` créé un commentaire

- friend, friendWithFoe, foe, foeWithFood, food, rock, home et foeHome sont des informations sur la map

- ```bit(i)``` indique si le bit i (pourt i de 0 à 5) vaut 1

- ahead, left, right et here sont les directions qui peut envisager une fourmi, selon son orientation

-```nop;``` est une commande vide, permet de continuer le programme

-```move(p,label1);``` avance p fois, et va au label label1 si il ne peut pas. ```move(p);``` continue le programme en cazs d'échec

-```turn(p);``` tourne p fois la fourmi sur la droite

-```pickup(Name);``` tente de récupérer de la nouriture sur la case courante, et va en Name sinon. Name peut faire référence à un label comme une fonction 

-```drop();``` dépose la nouriture sur la case courante si le fourmi en porte

-```mark(i);``` change le bit i pour 1 (i de 0 à 5)

-```unmark(i);``` change le bit i pour 0 (i de 0 à 5)

-```call Name``` appelle la fonction Name

-```func Name () {code}``` crée mla fonction Name contenant un code


## Commandes complexes:

- une condition est de la forme:
    - information is direction
    - randint(p) is q
    - and(info1,info2) is direction
    - or(info1,info2) is direction
    - not(information) is direction

Remarque : il est possible de combiner les and, or et not 

- 
``` if (condition)
    then {
        code1
    }
    else {
        code2
    }
``` éxécute code1 si condition est vérifié, code2 sinon

-
``` do {
        code
    }
    if (condition)
``` éxécute code si condition

-
``` while (condition) {
        code
    }
``` éxécute code tant que la condition est vérifiée

-
``` repeate(n) times {
        code
    }
``` éxécute n fois le code

-
```test(information) in {
        case direction1 :
            code1
        end
        case direction2 :
            code2
        end
        ...
        case directionp :
            codeP
    }
``` vérifie pour chaque cas (information is direction*), et éxécute le code si c'est vérifié. Remarque : il n'y a pas de end final



## TO DO

> ##### Voici les idées d'implémentation de fonctionnalités dans notre language que nous n'avons pas eu le temps de faire.
>
> implémenter les **variables** dans notre language

- pour utiliser des variables, on pensait à dupliquer des labels en assembleur pour stocker des informations dans les fourmis

exemple de syntaxe pour implémenter une variable :

```
var x in 0 1 2 ;
var y in 0 1 ;

# on définit x et y et on donne les valeurs qu'ils peuvent prendre dans le programme
# une varible DOIT être définit en début de programme

# on change la valeur de x
var x = 2;
turn(2)
varif y 1
then
{
    move(1);
}
else
{
    turn(2);
}
```

devrait donner en assembleur

```
goto var-x-0-y-1

var-x-0-y-0 :
    goto time-0-x-2-y-0
    time-0-x-0-y-0 :
    turn(2);

var-x-0-y-1 :
    goto time-0-x-2-y-1
    time-0-x-0-y-1 :
    move(1);

var-x-1-y-0 :
    goto time-0-x-2-y-0
    time-0-x-1-y-0 :
    turn(2);

var-x-1-y-1 :
    goto time-0-x-2-y-1
    time-0-x-1-y-1 :
    move(1);

var-x-2-y-0 :
    goto time-0-x-2-y-0
    time-0-x-2-y-0 :
    turn(2);

var-x-2-y-1 :
    goto time-0-x-2-y-1
    time-0-x-2-y-1 :
    move(1);
```

- On se déplace vers le label où x vaut 2 (sans changer la valeur de y) pour traduire la commande x = 2

- pour attérie au "même endroit" dans tous les labels lors d'une assignation, on crée les labels "time-int..." qui vaut 0 pour la première assignation du fichier, 1 pour la deuxième. 

- on a mis move(1) que lorsque on était dans un label où y = 0
- on a mis turn(2) que lorsque on était dans un label où y =1

Sur le principe se comportement devrait être implémenté par le 
