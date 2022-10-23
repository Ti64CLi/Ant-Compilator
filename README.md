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
- L'utilisation de la grammaire et l'usage de chacune des commandes est explicité dans "README_grammar.md"

## Compilateur :
- 

---

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
