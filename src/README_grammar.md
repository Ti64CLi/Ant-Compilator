# README Grammar

Explication de notre grammaire :

On nomme "language assembleur" pour 

---

> ## **Type program** 
ce type définit la structure global du programme :
- Preprocessor Program :
- ControlProgram :
- ExpressionProgram : définit le type expression qui se finit par un ";" pour enchainer sur le reste du programme

```
type program =
	| PreprocessorProgram	<preprocessor> <program?>
	| ControlProgram		<control> <program?>
	| ExpressionProgram		<expression>; <program?>
```

---

> ## **Type preprocessor**
ce type nous permet de séparer les traitements qui sont fait par le compilateur (car impossible à faire avec le language assembleur)
- Include et Define : similaire à la syntaxe C, define permet de définir des constantes qui sont remplacés à la compilation
- Org : dit qui est le point d'entrée du programme

```
type preprocessor =
	| Include				include <ident>
	| Define				define <ident> as <program>
	| Org					.org <ident>
```

---

> ## **Type Control**
- Label : comme en assembleur
- IfThenelse, While : comportement classique de tout language de programmation
- Fun : définit une fonction avec des paramètres
- Repeat : répéte un certains nombre de fois un programm (l'entier doit être connu par le compilateur)
- Switch/Case : vérifie si une catégorie se trouve dans différentes directions
```
type control =
	| Label					<ident>:
	| IfThenElse			if(<bool>) then {<program>} else {<program>}
	| Func					func <ident>(<ident*,>) {<program>}
	| While					while(<bool>) {<program>}
	| Repeat			    repeat(<bool>) {<program>}
	| Case				    case <bool>: <program>
	| Switch				test(<bool>) in {<program>}
```

---

> ## **Type Expression**
On définit toutes les expressions utiles dans les programmes
- Num pour les entiers 
- Args pour les arguments(constants traités par le compilo) de fonctions
- Move, Turn, Pickup, Drop, Goto, Mark, Unmark : même que les commandes en assembleur
- Call : appelle une fonction
- IfThen : classique if then (pas d'ambiguité car écrit do{}if{})
- Nop : traduit par un vide en assembleur, action vide
- Return : retourne où la fonction a été appelé
- Break : quitte la structure de controle en cours 

```
type expression =
	| Num					<int>
	| Args					args[<int>]
	| Move					move(<int>)
	| Turn					turn(<int>)
	| PickUp				pickup(<ident>)
	| Drop					drop()
	| Goto					goto <ident>
	| Mark 					mark(<int>)
	| Unmark				unmark(<int>)
	| Call					call <ident>
	| IfThen				do {<program>} if(<bool>)
	| Nop					nop
	| Return			    return
	| Break				    break
```

---

> ## **Type Bool**
création d'un type booléen classique
- Or, And, Equal, Not, NotEqual : les opérations habituels
- Is : vérifie si une catégorie est dans une direction

```
type bool =
	| Value					<value>
	| Category			    <category>
	| Dir				    <direction>
	| Or					or(<bool>, <bool>)
	| And					and(<bool>, <bool>)
	| Equal 				eq(<bool>, <bool>)
	| Not					not(<bool>)
	| NotEqual				neq(<bool>, <bool>)
	| Is					is(<category>, <direction>)
```

---

> ## **Type Value**

```
type value =
	| Var					<ident>
	| Int					<int>
```

---

> ## **Type Direction**
- les différentes "directions" possibles du point de vue d'une fourmis

```
type direction =
	| Ahead					ahead
	| Left					left
	| Right					right
	| Here					here
```

---

> ## **Type Category**
- les différentes catégories de cases possibles qui sont testables par l'assembleur
```
type category =
	| Friend				friend
	| Foe					foe
	| FriendWithFood	    friendWithFood
	| FoeWithFood			foeWithFood
	| Food					food
	| Rock					rock
	| Marker				bit(<value>)
	| FoeMarker				foeMarker
	| Home					home
	| FoeHome				foeHome
	| RandInt				randint(<value>)
```