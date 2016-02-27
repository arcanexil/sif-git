#!/bin/bash
# imprimer.sh - User Friendly's menu to print in UPSUD's SIF
# Author : Lucas Ranc <lucas.ranc@gmail.com>

# Moon :
# 
# 1. Vérifier le quota de l'utilisateur lui afficher, afficher également son login
#    et éventuellement l'éspace occupé
# 2. Afficher l'état de l'imprimante (file d'impression, prête, hors ligne ...)
#    prévenir l'utilsateur si une autre impression bloque, qu'il ne sert à rien
#    d'imprimer sous peine de perdre son quota de pages
#    Si imprimante OK continuer procédure...
# 3.  
#
# Spécifier si le script prend un paramettre ($1) et à quoi il correspond
# La recherche sur les pdf se base sur l'extention pdf, mais peut être améliorée
# J'ai vérifié mais la recherche ne parcours pas tout les rep !
# Pour impression on doit gérer la sortie (affichage du quota et décompte apres
# impression...
# un module de parcours des rep serait bien...
# L'avertissement avant impression est placée après l'impression (à inverser) 
# 
# Renvoi PDF si c'en est un
# file fichier | cut -d ":" -f2 | cut -c2-4
# Renvoi PostScript si c'en est un
# file fichier | cut -d ":" -f2 | cut -c2-11


### Def some global vars
TITLE="Imprimer au SIF"


function PsCheck(){
  ###
  ### Check for ps, prn files
  ### Take an arg to change the folder
  ### Result into $filepath
  ###
  if [ -z $1 ]; then
    filepath=$(ls -lhpR $HOME/*.ps  | awk -F ' ' ' { print $9 " " $5 } ')
    filepath="$filepath $(ls -lhpR $HOME/*.prn  | awk -F ' ' ' { print $9 " " $5 } ')"
    # filepath="$filepath $(ls -lhpR $HOME/*.pdf  | awk -F ' ' ' { print $9 " " $5 } ')"
  else
    filepath=$(ls -lhpR $1/*.ps  | awk -F ' ' ' { print $9 " " $5 } ')
    filepath="$filepath $(ls -lhpR $1/*.prn  | awk -F ' ' ' { print $9 " " $5 } ')"
    # filepath="$filepath $(ls -lhpR $1/*.pdf  | awk -F ' ' ' { print $9 " " $5 } ')"
  fi
}

function PdfCheck(){
  ###
  ### Check for pdf files
  ### Take an arg to change the folder
  ### Result into $filepath
  ###
  if [ -z $1 ]; then
    filepath=$(ls -lhpR $HOME/*.pdf  | awk -F ' ' ' { print $9 " " $5 } ')
  else
    filepath=$(ls -lhpR $1/*.pdf  | awk -F ' ' ' { print $9 " " $5 } ')
  fi
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
      echo "lpr $1 -#$CopyNumber $pathselect" > /home/lino/impression.txt
      ### After confirmation of lpr script, confirmation message :
      printed=$(basename $pathselect)
      whiptail --title "$TITLE"\
      --msgbox "Le fichier $printed va être imprimé $CopyNumber fois" 0 0
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
  PsCheck

  ### Ask which file to use
  if [ -z $1 ]; then
    pathselect=$(whiptail --menu "Selectionnez un fichier à imprimer" 0 0 0 \
    --cancel-button Retour --ok-button Select $filepath 3>&1 1>&2 2>&3)
  else
    pathselect=$(whiptail --menu "Selectionnez un fichier à imprimer" 0 0 0 \
    --cancel-button Retour --ok-button Selectionner $filepath 3>&1 1>&2 2>&3)
  fi

  ### Now we check the result path :
  status=$?
  if [ $status -eq 0 ]; then
    AskOptions
  else
    whiptail --title "$TITLE"\
    --msgbox "Attention : \n Vous n'avez pas de fichiers .PS dans votre\
répertoire personnel.\n Veuillez vérifier ou adressez-vous à un tuteur." 0 0
  fi
}

function Convert(){
  ###
  ### Allow User to convert his PDF into PS file
  ###
  PdfCheck
  ### Ask which file to use
  if [ -z $1 ]; then
    pathselect=$(whiptail --menu "Selectionnez un fichier à imprimer" 0 0 0 \
    --cancel-button Retour --ok-button Select $filepath 3>&1 1>&2 2>&3)
  else
    pathselect=$(whiptail --menu "Selectionnez un fichier à imprimer" 0 0 0 \
    --cancel-button Retour --ok-button Selectionner $filepath 3>&1 1>&2 2>&3)
  fi

  ### Now we check the result path :
  status=$?
  if [ $status -eq 0 ]; then
    	# moon
	echo "pdftops $pathselect &"
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
  whiptail --title "$TITLE"\
  --msgbox "Bienvenue sur le module d'impression du SIF.\n\n\
  Pour cela, il vous faut donc avoir déposé dans\n\
  votre dossier personnel le fichier à imprimer.\n\
  (Procédure expliquée sur le dossier /partage/procédure... )\n\n\
  Attention : votre fichier ne doit pas contenir d'espaces" 0 0
}

function menu(){
  ### Menu
  choice=$(whiptail --title "$TITLE" --menu "Choisir une option" 0 0 0 \
  "1" "Convertir un PDF en PS" \
  "2" "Imprimer un fichier" \
  "3" "Se déconnecter/Sortir du module" 3>&1 1>&2 2>&3)
  # "Refresh" "Actualiser la liste des fichiers" \
  status=$?

  if [ $status -eq 0 ]; then
    case $choice in
      1 )
        Convert
        menu
        ;;
      2 )
        Procedure
        menu
        ;;
      3 )
        exit 0
        ### Or logout
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
