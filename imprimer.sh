#!/bin/bash
# imprimer.sh - User Friendly's menu to print in UPSUD's SIF
# Author : Lucas Ranc <lucas.ranc@gmail.com>

# Moon :
##########################################################################
# IMPORTANT : Changement de procédure :
# On propose d'imprimer des fichiers uniquement au format PDF à charge du programme de convertirt 
# les dits fichiers en PS et de les exploiter ensuite, on abandone ainsi le format PS mal compris
# par l'utilisateur
#
# Le script prenant en compte le fichier PS prend mal les noms de fichiers avec des espaces et autres caractères spéciaux
# il convient donc lors de la conversion de spécifier un nom different de celui donné en argument
# et donc un nom court
#############################################################################
#
# 1. Vérifier le quota de l'utilisateur lui afficher, afficher également l'éspace disque occupé
# 2. Afficher l'état de l'imprimante (file d'impression, prête, hors ligne ...)
#    prévenir l'utilsateur si une autre impression bloque, qu'il ne sert à rien
#    d'imprimer sous peine de perdre son quota de pages
#    Si imprimante OK continuer procédure...
# 3. Faut il proposer un shell à l'utilisateutr ?
# 4. Prevenir l'utilisateur que l'impression est traçée
############################################################"
## Pour les PC imprimantes a mettre dans /etc/profile
#if [ "`id -u`" -ne 0 ]; then
#  /chemin/print.sh && exit
#fi
############################################################
# Spécifier si le script prend un paramettre ($1) et à quoi il correspond
# La recherche sur les pdf se base sur l'extention pdf, mais peut être améliorée
# J'ai vérifié mais la recherche ne parcours pas tout les rep !
# Pour l'impression on doit gérer la sortie (affichage du quota et décompte apres
# impression...
# un module de parcours des rep serait bien...
# L'avertissement avant impression est placée après l'impression (à inverser) 
# 
# Renvoi PDF
# file fichier | cut -d ":" -f2 | cut -c2-4
# Renvoi PostScript
# file fichier | cut -d ":" -f2 | cut -c2-11


### Def some global vars
TITLE="Imprimer au SIF"
# Moon Replace by QUOTA=`quota`
QUOTA=`quota`
LPQ=`lpq`
QUOTA_DISQUE=`du -sh ~ | cut -f1`

# SIF
#QUOTA_IPM=$(`quota`)
#QUOTA=65/100

function Quota(){
### Print quota user :
# Replace with quota $USER 
  whiptail --title "$TITLE"\
  --msgbox "Vous coccupez actuellement : $QUOTA_DISQUE .\n\
    Votre quota impresion est de : $QUOTA" 0 0
}
  
function etat_imprimante(){
  ###
  ### Check for printer status
  ### 
  ### If ready then continue, else show files queu
  # Moon
  ### Mettre lpq lorsque production
  # LPQ="HP-LaserJet-P4015 est prêt aucune entrée"
  whiptail --title "$TITLE"\
  --msgbox "Etat de l'imprimante :\n\n $LPQ" 0 0
 }

function PdfCheck(){
  ###
  ### Check for pdf files
  ### Take an arg to change the folder
  ### Result into $filepath
  ###
  
  # moon : inutile le script sera lancé par le systeme au login
    filepath=$(find $HOME \( ! -regex '.*/\..*' \) -type f -name "*.pdf" | while read i;do ls -lhp "$i" | awk -F ' ' ' { print $8 " " $5 } '; done)
}

function Print(){
  ###
  ### Function it is all about
  ### Take args : the options we asked before in the procedure
  ###
  CopyNumber=$(whiptail --title "$TITLE" --inputbox \
      "Combien de fois voulez-vous l'imprimer ?\n\
      (Par défaut : 1)" 0 0 1 3>&1 1>&2 2>&3)
  status=$?

  if [ $status = 0 ]; then
    if [[ "$CopyNumber" =~ ^[0-9]+$ ]]; then
      ### Here, every params is ok to send print command :
      # Doing echo for testings
      printed=$(basename $pathselect)
      whiptail --title "$TITLE"\
      --msgbox "Le fichier $printed va être imprimé $CopyNumber fois" 0 0
      # $1 est l'argument passé à la fonction Print
      # echo "lpr $1 -#$CopyNumber $pathselect" >> /home/$USER/impression.txt
      echo "o" | lpr $1 -#$CopyNumber $HOME/doc.ps
      ### After confirmation of lpr script, confirmation message :
      # Moon Replace by QUOTA=`quota` 
      # QUOTA=`quota`
            
    else
      whiptail --title "$TITLE"\
      --msgbox "Attention : \n Vous n'avez pas spécifié de nombre" 0 0
    fi
  else
    menu
  fi
}

function AskOptions(){
  choice=$(whiptail --title "$TITLE" --menu "Choisir une option" 0 0 0 \
  "1" "Imprimer normalement (recto seul)" \
  "2" "Imprimer recto-verso en Portrait" \
  "3" "Imprimer recto-verso en Paysage" 3>&1 1>&2 2>&3)
  status=$?

  if [ $status -eq 0 ]; then
    case $choice in
      1 )
      Print
      ;;
      2 )
      Print -DI
      ;;
      3 )
      Print -DP
      ;;
    esac
  else
      menu
  fi
}


function Procedure(){
  ###
  ### Launch precedure to print : find files, ask options, print
  ###
 # moon
 # PsCheck
PdfCheck
  ### Ask which file to use
#  if [ -z $1 ]; then
    #pathselect=$(whiptail --menu "Selectionnez un fichier à imprimer" 0 0 0 \
    #--cancel-button Retour --ok-button Select $filepath 3>&1 1>&2 2>&3)
    pathselect=$(whiptail --menu "Selectionnez un fichier à imprimer" 0 0 0 $filepath 3>&1 1>&2 2>&3)
    type_f=`file $pathselect | cut -d ":" -f2 | cut -c2-4`
   
#  else
#    pathselect=$(whiptail --menu "Selectionnez un fichier à imprimer" 0 0 0 \
#    --cancel-button Retour --ok-button Selectionner $filepath 3>&1 1>&2 2>&3)
#  fi

  ### Now we check the result path :
  status=$?
  if [ $status -eq 0 -a "$type_f" == "PDF" ]; then
    pdftops $pathselect $HOME/doc.ps &
    {
        echo 10
        sleep 1
        while (true)
        do
            echo 50
            if [ "$(ps aux | grep -v grep | grep -e "pdftops")" == "" ]; then
              break
            fi
        done
        # If it is done then display 100%
        echo 100
        # Give it some time to display the progress to the user.
        sleep 1
    } | whiptail --title "$TITLE" --gauge "Patientez conversion en cours ...selon la taille du fichier" 0 0 0
    AskOptions
  else
    whiptail --title "$TITLE"\
    --msgbox "Attention : \n Vous n'avez pas selectionné de fichier ou le fichier n'est pas un fichier 
    pdf valide:\n `file $pathselect`\n Recreez le fichier PDF ou adressez-vous à un tuteur pendant ses 
    heures de bureau." 0 0
  fi
}

function Convert(){
  ###
  ### Allow User to convert his PDF into PS file
  ###
  PdfCheck
  ### Ask which file to use
  # if [ -z $1 ]; then
    pathselect=$(whiptail --menu "Selectionnez un fichier à convertir au format ps" 0 0 0 \
    --cancel-button Retour --ok-button Select $filepath 3>&1 1>&2 2>&3)
  # else
  #  pathselect=$(whiptail --menu "Selectionnez un fichier à imprimer" 0 0 0 \
  #  --cancel-button Retour --ok-button Selectionner $filepath 3>&1 1>&2 2>&3)
  # fi

  ### Now we check the result path :
  status=$?
  if [ $status -eq 0 ]; then
      # moon
  echo "pdftops $pathselect"
  pdftops $pathselect &
    {
        echo 10
        sleep 1
        while (true)
        do
            echo 50
            if [ "$(ps aux | grep -v grep | grep -e "pdftops")" == "" ]; then
              break
            fi
        done
        # If it is done then display 100%
        echo 100
        # Give it some time to display the progress to the user.
        sleep 1
} | whiptail --title "$TITLE" --gauge "Conversion en cours ..." 0 0 0
  fi
}

function Welcome(){
  ### Welcome :
  imprimante_prete=`echo $LPQ | cut -d" " -f3`
  #if [ "$imprimante_prete" == "prêt" ]; then
    whiptail --title "$TITLE"\
  --msgbox "Bienvenue sur le module d'impression du SIF.\n\n\
  Ce module recheche, affiche et propose d'imprimer les fichiers PDF présents dans votre dossier\n\
  Si vous êtes la c'est que vous avez déjà consulté la procédure d'impression que vous trouverez sur le dossier: \n
  /partage/procédure_impression.pdf\n
  ou affichée à coté des imprimantes\n\n\
  Ou bien vous savez ou se trouve votre fichier PDF\n\n Etat de imprimante:\n $LPQ" 0 0
  
  #else
  #whiptail --title "$TITLE"\
  #--msgbox "Bienvenue sur le module d'impression du SIF.\n\n\
  #Vous ne pouvez pas imprimer pour le moment, attendez l'aide un tuteur\n\
  #Etat de imprimante: $LPQ" 0 0
  #exit
  #fi
}

function menu(){
  ### Menu
  choice=$(whiptail --title "$TITLE" --menu "Votre quota impression: $QUOTA Pages\nVous occupez $QUOTA_DISQUE\nQue voulez vous faire ? " 0 0 0 \
  "1" "Afficher l'état de l'imprimante ou la file d'impression" \
  "2" "Imprimer un fichier PDF" \
  "3" "Quiter et fermer la session" \
  "4" "Afficher quota" 3>&1 1>&2 2>&3)
# "Refresh" "Actualiser la liste des fichiers" \
  status=$?

  if [ $status -eq 0 ]; then
    case $choice in
      1 )
        etat_imprimante
        menu
        ;;
      2 )
        Procedure
        menu
        ;;
      3 )
  # marche po il fot etre root, au fait il faut lancer le script avec l'option "&& exit"  
  #kill -HUP `pgrep -s 0 -o`
  # logout        
  exit 0
        ### Or logout
        ;;
      4)
  Quota
  menu
  ;;
    esac
  else
    exit 0
  fi
}


### Launch welcoming and menu
Welcome
menu

exit 0
