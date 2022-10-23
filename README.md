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

## preprogramme:

-
```include Name``` inclue au début du programme le fichier Name.ant

-
```define name as va``` donne à name la valeur val

## Utilisation de base:

-```Name:``` et -```goto Name``` permettent de créer un label et d'aller à un label

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
``` 
if (condition)
    then {
        code1
    }
    else {
        code2
    }
``` 
éxécute code1 si condition est vérifié, code2 sinon

-
``` 
do {
        code
    }
    if (condition)
``` 
éxécute code si condition

-
``` 
while (condition) {
        code
    }
``` 
éxécute code tant que la condition est vérifiée

-
``` 
repeate(n) times {
        code
    }
``` 
éxécute n fois le code

-
```
test(information) in {
        case direction1 :
            code1
        end
        case direction2 :
            code2
        end
        ...
        case directionp :
            codep
    }
``` 
vérifie pour chaque cas (information is direction*), et éxécute le code si c'est vérifié. Remarque : il n'y a pas de end final

> implémenter les **variables** dans notre language

## Utilisation des variables

- Tous les "var" en début de programme définissent des nouvelles variables. Il faut indiquer les valeurs possible de la varialble qui sont des chaines de caractères quelconque et la valeur initiale de la variable.

Remarque : il faut mettre des espaces avant les points virgules
```
var x = 0 in 0 1 2 3 ;
var y = nord in sud ouest nord est ;
```
Ici, x est initialement égale à 0 et peut valoir 0, 1, 2 ou 3 et y est initialement égale à "nord" et peut valoir "sud", "ouest", "nord" ou "est".

La création de variable ne compte aucune opération en assembleur, cependant est très couteux en espace du progamme finale compilé. le nombre de ligne du progamme est multiplié par un O(nb_valeurs_possible variable) et ceci pour chaque variable.

On peut changer la valeur d'une variable avec cette instruction


```
var nom_variable = nouvelle_valeur ;
```
Remarque : il faut mettre des espaces avant les points virgules

Remarque : une assignation fait 1 opération en assembleur

Pour utiliser ces variables on a des test sur ces valeurs. On ne peut faire que des tests simples (aucune opération logique implémenté) cependant on peut imbriquer les tests entre eux.
Voici la syntaxe :


```
var if x == 0 
beginthen {
    instruction0 ;
    ...
} endthen
beginelse {
    instruction1 ;
    ...
} endelse
```
Remarque : ce test ne prend aucune opération en assembleur

