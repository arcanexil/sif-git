# Todo list + explications (todo-md via npm)
Legend :
         @branch : nom de la branch où se trouve les réflexions
         -> commit number or tag : todo achevé (rappel du commit si besoin)

--------------------------------------------------------------------------------
- [ ] Nouvelle Procedure (@dev)
  - [ ] renommage des fichiers avec espaces
      - [x] avec mv (-> d962d0f)
      - [ ] avec ifs
      - [ ] caractères spéciaux?
  - [ ] Solution de conversion pdf > 2 Mo
      - [ ] retour de la fonction PS
      - [ ] passage au tout PDF avec pdfinfo
  - [ ] Utilisation d'un demon
      - [ ] reverse engineering de LPR

# A faire :
# 1. Gérer les nom de fichiers avec des espaces, il y en a...
#    En fait le while recupere bien le fichier avec espaces c'est whiptail qui
#    le recupere emal !
#
# 2. Trouver un solution pour la conversion des fichiers pdf > à 2 Mo car c'est
#    lent
#    On peut envisager si le PDF est gros, dans un premier temps de proposer à
#     l'utilisateur la première methode :-(
#    Pas genial mais bon ... Et donc de remettre la fonction PsCheck que j'avais
#      supprimé

--------------------------------------------------------------------------------
- [x] Procedure normale (@master) (-> v0.0.1)
    - [x] Afficher quota + espace disque
    - [x] Afficher état imprimante
        - [ ] Trouver solution si imprimante bloquée
    - [x] Recherche de PDF/PS dans le dossier utilisateur
        - [x] Vérification du fichier
    - [x] Avertissement du lancement de l'impression
        - [ ] Que faire si file bloquée
    - [x] Envoie à LPR

# Copie du fichier à imprimer au bon format :
# Le script prend mal en compte les noms de fichiers avec des espaces et autres
# caractères spéciaux (d'ailleurs le script lpr ne les gère pas !)
# il convient donc lors de la conversion de spécifier un nom different de celui
# donné en argument et donc un nom court
#############################################################################
#
# 1. Vérifier le quota de l'utilisateur lui afficher, afficher également
#    l'espace disque occupé car si les quotas ne suivent pas probleme il y aura
# 2. Afficher l'état de l'imprimante (file d'impression, prête, hors ligne ...)
#    Que faire si incident imprimante ?
#    Dejà dans le welcome : prévenir l'utilsateur si une autre impression bloque,
#    qu'il ne sert àrien d'imprimer sous peine de perdre son quota de pages
# 3. Faut il proposer un shell à l'utilisateutr ? Pour le moment oui a cause des
#    pdf superieur a 2Mo
# 4. Prevenir l'utilisateur que l'impression est traçée, pour ceux qui laissent
#    la file bloquee
############################################################
# La recherche sur les pdf se base sur l'extention pdf, mais peut être améliorée
# C'est rare mais il peut exister des pdf sans extension ! la recherche ne le detecte pas!
# Pour l'impression on doit gérer la sortie (affichage du quota et décompte apres
# impression...
#
# Renvoi PDF
# file fichier | cut -d ":" -f2 | cut -c2-4
--------------------------------------------------------------------------------
- [ ] Lancement du script automatiquement au login
############################################################"
# Reaction inatendu lorsque on ajoute ce code dans profile
## Pour les PC imprimantes a mettre dans /etc/profile
#if [ "`id -u`" -ne 0 ]; then
#  /chemin/print.sh && exit
#fi

--------------------------------------------------------------------------------