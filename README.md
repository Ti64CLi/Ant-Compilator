# Projet Fourmis

Equipe **Ant-stein** :

- Paul ADAM
- Adrien DECOSSE
- Elie DUMONT

---

## Structure du projet

Le dossier `test` contient tous les tests :

- les tests unitaires de la grammaire dans `test/unit_test_grammar`
- les tests de stratégies naïves se trouve dans `test/naifs`
- les test du pre-lexer se trouve dans `test/pre_lexer`

---

## Compiler le projet

```
> make clean
> make
```

Pour compiler les tests, il suffit d'exécuter :

```
> make test
```

---

## Objectifs :

- créer un language intuitif pour écrire le cerveau d'une fourmis
  - créer une grammaire efficace et clair
- écrire un compilateur qui nous traduit nos lignes de code en assembleur fourmis
- écrire une "bonne" stratégie pour les fourmis

---

## Grammaire :

> ### Préprocesseur :

- `include Name` inclue à cet endroit le fichier Name.ant

- `define name as va` donne à name la valeur val

> ### Expressions :
>
> (à la fin d'un expresion se touve toujours un `;`)

- `nop` est une commande vide, permet de continuer le programme.

- `move(p, onError)` avance p fois, et va au label/fonction `onError` si il ne peut pas. `move(p)` continue le programme en cas d'échec

- `turn(p)` tourne p fois la fourmi sur la droite

- `pickup(onError)` tente de récupérer de la nouriture sur la case courante, et va en `onError` sinon. `onError` peut faire référence à un label comme une fonction

- `drop()` dépose la nouriture sur la case courante si le fourmi en porte

- `mark(i)` change le bit i pour 1 (i de 0 à 5)

- `unmark(i)` change le bit i pour 0 (i de 0 à 5)

- `call Name` appelle la fonction Name

> ### Autres commandes

- `label:` et `goto label` permettent de créer un label et d'aller à un label (possible de les utiliser mais déconseillé)

- `/* commentaire */` créé un commentaire
  /!\ mettre un `_` entre chaque mot

- `friend`, `friendWithFoe`, `foe`, `foeWithFood`, `food`, `rock`, `home` et `foeHome` sont des informations sur la map

- `bit(i)` indique si le bit i (pourt i de 0 à 5) vaut 1

- `ahead`, `left`, `right` et `here` sont les directions que peut envisager une fourmi, selon son orientation

> ### Commandes complexes:

- une condition est de la forme:
  - `<information> is <direction>`
  - `randint(p) is q` avec `q` compris entre `0` et `p - 1`
  - `and(<information>, <information>) is <direction>`
  - `or(<information>, <information>) is <direction>`
  - `not(<information>) is <direction>`

Remarque : il est possible de combiner les `and`, `or` et `not`

- Structure `func`

```
func name () {
    <code>
}
```

défini une fonction `name` qui exécute `<code>`.

- Structure `if`

```
if (condition) then {
    code1
} else {
    code2
}
```

exécute `code1` si `condition` est vérifié, `code2` sinon

- Structure `do`

```
do {
    code
} if (condition)
```

exécute `code` si `condition`

- Structure `while`

```
while (condition) {
    code
}
```

exécute `code` tant que `condition` est vérifiée

- Structure repeat

```
repeat (n) times {
    code
}
```

exécute n fois `code`

- Structure `test`

```
test (information) in {
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

vérifie pour chaque cas (information is direction\*), et éxécute le code si c'est vérifié. Remarque : il n'y a pas de end final

---

## Utilisation des variables

### Pre-lexer

Toutes les commandes qui suivent sont traités par le pre-lexer.

- Tous les "var" en début de programme définissent des nouvelles variables. Il faut indiquer les valeurs possible de la variable qui sont des chaines de caractères quelconque et la valeur initiale de la variable.

> Remarque : il faut mettre des espaces avant les points virgules

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

> Remarque : il faut mettre des espaces avant les points virgules

> Remarque : une assignation fait 1 opération en assembleur

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

> Remarque : ce test ne prend aucune opération en assembleur

---

## TO DO

- Gérer une incrémentation est très pratique pour programmer. ie : faire un cycle sur les valeurs possibles données en début du programme

Voici la syntaxe :

```
var nom_variable ++ ;
```

```
var x = sud in nord sud est ouest ;

var x ++ ;
```

après ce programme, x a la valeur "est".
Remarque : l'espace après le ; est obligatoire.

- Gérer les arguments des fonctions :
  celà reviendrai à remplacer le pre_lexer par le support des varibles dans la grammaire.
