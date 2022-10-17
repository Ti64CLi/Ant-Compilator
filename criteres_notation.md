## Qualité du code (majorité de la note)

- Structure du code
    * README : est-ce qu'il aide, est-ce qu'on s'y retrouve ?
    * Bon découpage fonctions ? (Trop grosse fonction ? Niveaux d'indentation ?)
    * Annotations de type pour les arguments et le retour des fonctions ?
- Commentaires ?

## Compilation du projet et lancement des tests.

+ Est-ce que `make` marche ?
+ Est-ce qu'il y a des tests unitaires ?
+ Est-ce qu'il y a des tests de bout en bout ?
+ Est-ce qu'il y a une façon facile de lancer les tests ?
  (`make test` ou équivalent)

## Langage source et remarques de programmation

- Est-ce que le langage source est facile à prendre en main ?
- Est-ce agréable de programmer dedans ?
- Est-ce que les différentes constructions du langage marchent quand on les imbrique
  les unes dans les autres ?
  (Quand cela est permis par la grammaire du langage, bien sûr)
- Est-ce que le langage est structuré ?
  En particulier, il ne devrait pas y avoir besoin de connaître l'assembleur fourmi
  pour comprendre comment s'exécutera un programme.
- S'il y a des passes d'optimisation du code produit : est-ce qu'elles sont vraiment utiles ? utilisées ?

## Niveau de couverture des tests

+ Quelles zones sont testées et quelles ne le sont pas ?

## Propreté git (regardé mais pas pris en compte dans la note)

+ Messages de commit qui ont un sens ?
+ Utilisation de noms complets et d'adresses mail institutionnelles dans git ?
