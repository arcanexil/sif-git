#!/bin/bash
# imprimer.sh - User Friendly's menu to print in UPSUD's SIF
# Author : Lucas Ranc <lucas.ranc@gmail.com>


# A faire :
# 1. Gérer les nom de fichiers avec des espaces, il y en a...
#    En fait le while recupere bien le fichier avec espaces c'est whiptail qui le recupere emal !
#
# 2. Trouver un solution pour la conversion des fichiers pdf > à 2 Mo car c'est lent
#    On peut envisager si le PDF est gros, dans un premier temps de proposer à l'utilisateur la première methode :-(
#    Pas genial mais bon ... Et donc de remettre la fonction PsCheck que j'avais supprimé


# Copie du fichier à imprimer au bon format :
# Le script prend mal en compte les noms de fichiers avec des espaces et autres
# caractères spéciaux (d'ailleurs le script lpr ne les gère pas !)
# il convient donc lors de la conversion de spécifier un nom different de celui donné en argument
# et donc un nom court
#############################################################################
#
# 1. Vérifier le quota de l'utilisateur lui afficher, afficher également l'éspace disque occupé
#    car si les quotas ne suivent pas probleme il y aura...
# 2. Afficher l'état de l'imprimante (file d'impression, prête, hors ligne ...)
# Si tu lis ces lignes Lucas, peut on creer un fichier avec les fonctionnalitées à ajouter etc.. ?
# ainsi on poura deplacer ce contenu
#    Que faire si incident imprimante ?
#    Dejà dans le welcome : prévenir l'utilsateur si une autre impression bloque, qu'il ne sert à rien
#    d'imprimer sous peine de perdre son quota de pages
# 3. Faut il proposer un shell à l'utilisateutr ? Pour le moment oui a cause des pdf superieur a 2Mo
# 4. Prevenir l'utilisateur que l'impression est traçée, pour ceux qui laissent la file bloquee

############################################################"
# Reaction inatendu lorsque on ajoute ce code dans profile
## Pour les PC imprimantes a mettre dans /etc/profile
#if [ "`id -u`" -ne 0 ]; then
#  /chemin/print.sh && exit
#fi
############################################################
# La recherche sur les pdf se base sur l'extention pdf, mais peut être améliorée
# C'est rare mais il peut exister des pdf sans extension ! la recherche ne le detecte pas!
# Pour l'impression on doit gérer la sortie (affichage du quota et décompte apres
# impression...
#
# Renvoi PDF
# file fichier | cut -d ":" -f2 | cut -c2-4

### Def some global vars
TITLE="SIF"
QUOTA=`quota`
LPQ=`lpq`
QUOTA_DISQUE=`du -sh ~ | cut -f1`

function Quota(){
### Print quota user :
# Replace with quota $USER
  whiptail --title "$TITLE"\
  --msgbox "Vous coccupez actuellement : $QUOTA_DISQUE .\n\
    Votre quota impresion est de : $QUOTA\n\n\
    Si vous n'avez plus de crédit impression, demandez au tuteur\n\
    qui en fera la demande, vous recevrez une notification par mail\n\
    Vous informant de votre nouveau crédit\n\n\
    Attention vous avez droit à un seul renouvellement de 100 " 0 0
}

function etat_imprimante(){
  ###
  ### Check for printer status
  ###
  ### If ready then continue, else show files queu
  # Moon
  LPQ=$(lpq)
  whiptail --title "$TITLE"\
  --msgbox "Etat de l'imprimante :\n\n $LPQ" 0 0
 }

function PdfCheck(){
  ###
  ### Check for pdf files
  ### Take an arg to change the folder
  ### Result into $filepath
  ###

  # moon chez moi car c'est $9 au lieu de $8
    pcmoon=`uname -a | cut -d " " -f3`
    if [ "$pcmoon" == "3.13.0-83-generic" ]; then
            filepath=$(find $HOME \( ! -regex '.*/\..*' \) -type f -name "*.pdf" | while read i;do ls -lhp "$i" | awk -F ' ' ' { print $9 " " $5 } '; done)
    else
    # filepath=$(find $HOME \( ! -regex '.*/\..*' \) -type f -name "*.pdf" | while read i;do ls -lhp "$i" | awk -F ' ' ' { print $8 " " $5 } '; done)
    filepath=$(find Documents \( ! -regex '.*/\..*/' \) -type f -name "*.pdf" | while read i;do new=$(ls "$i" | sed 's/ /_/'); if [ "$i" != "$new" ]; then mv "$i" $new; fi; ls -lhp "$new" | awk -F ' ' ' { print $8 " " $5 } '; done)
    fi
}

function suppr_file_impression(){
  ###
  ### Delete (all)owner print qeu
  ###
  LPQ=$(lpq)
  imprimante_prete=`lpq | wc -l`
  #whiptail --msgbox "contenu de imprimante _prete: $imprimante_prete" 0 0
  if [ $imprimante_prete -ne 2 ]; then
  	numero_job=$(whiptail --title "Fille impression" --inputbox "Seul vos jobs peuvent être annulés\n\
  	Si vous voulez supprimer tous vos jobs tapez -\n\n\
  	Entrez le numéro du job à annuler:\n\
	Etat de la file d'impression: $LPQ\n\n\
	Si la situation est bloquéé : Ctrl+Alt+Suppr, ainsi au redémarage\n\
	La file sera supprimée" 0 0 3>&1 1>&2 2>&3)
  	status=$?
      if [[ "$numero_job" =~ ^[0-9]+$ ]] || [ $numero_job == "-" ]; then
      	#whiptail --msgbox "contenu de numero_job: $numero_job" 0 0
      	if [ $status = 0 ] && [ $numero_job -ne 0 ] || [ $numero_job == "-" ]; then
      		num_job=`lprm $numero_job 2>&1`
          	if [ -z "$num_job" ]; then
            		if [ $numero_job == "-" ]; then
               			whiptail --msgbox "Tous vos jobs ont été annulés" 0 0
            		else
               			whiptail --msgbox "Le job $numero_job a bien été annulé" 0 0
            		fi
          	else
            		whiptail --msgbox "$status" 0 0
          	fi
        else
            whiptail --msgbox "Le numéro entré n'est pas bon" 0 0
        fi
      else
        whiptail --msgbox "Uniquement des chiffres, repérez le numéro du job !" 0 0
      fi
     else
      whiptail --msgbox "Pas de file d'impression" 0 0
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
      printed=$(basename $pathselect)
      whiptail --title "$TITLE"\
      --yesno "Le fichier $printed va être imprimé $CopyNumber fois voulez vous continuer ? " 0 0
      status=$?
      if [ $status -ne 0 ]; then
	menu
      fi

      # $1 est l'argument passé à la fonction Print, on abandone les formats paysage et portrait
      # Par contre il faut ajouter le format recto-verso...(remplacer menu par ce choix 2 dans AskOprtions
      # echo "lpr $1 -#$CopyNumber $pathselect" >> /home/$USER/impression.txt
      lpr -#$CopyNumber $HOME/doc.ps
      ### After confirmation of lpr script, confirmation message :
      # Moon Replace by QUOTA=`quota`
      QUOTA=`quota`

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
  "1" "Imprimer le fichier  selectioné ?" \
  "2" "Retour au menu" 3>&1 1>&2 2>&3)
  status=$?

  if [ $status -eq 0 ]; then
    case $choice in
      1 )
      Print
      ;;
      2 )
      menu
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
PdfCheck
  ### Ask which file to use

    # Les boutons ne passent pas !
    #pathselect=$(whiptail --menu "Selectionnez un fichier à imprimer" 0 0 0 \
    #--cancel-button Retour --ok-button Select $filepath 3>&1 1>&2 2>&3)

    pathselect=$(whiptail --menu "Selectionnez un fichier à imprimer" 0 0 0 $filepath 3>&1 1>&2 2>&3)
    type_f=`file $pathselect | cut -d ":" -f2 | cut -c2-4`

  ### Now we check the result path :
  status=$?
  if [ $status -eq 0 -a "$type_f" == "PDF" ]; then
    taille=`du "$pathselect" | awk '{print $1}'`
    if [ $taille -gt "2000" ]; then
       whiptail --yesno "Attention votre fichier occupe $taille Kiloctets, la conversion sera longue\n\
       et l'impression également, il est conseillé de convertir ce fichier sur le PC de travail et revenir\n\
       pour l'imprimer en faisant lpr nom_de_fichier.ps (ancienne méthode)\n\n\
       Continuer ? oui/non" 0 0
       status=$?
       if [ $status -ne 0 ];then
       #whiptail --msgbox "status : $status" 0 0
       menu
       fi
    fi

    pdftops "$pathselect" $HOME/doc.ps &
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


function Welcome(){
  ### Welcome :
  imprimante_prete=`lpq | wc -l`

  # si > 2 document en file d'impression, si non prête
  #if [ "$imprimante_prete" == "4" ]; then
    whiptail --title "$TITLE"\
  --msgbox "Bienvenue sur le module d'impression du SIF.\n\n\
  Le fichier que vous voulez imprimer DOIT être au format PDF, et présent dans votre dossier personnel \n\n\
  Si ce n'est pas le cas, allez sur un PC libre et convertissez le document en fichier PDF\n\n\
  Attention sous Windows vous devez enregistrez le fichier sous le lecteur U:\\$USER\n\
  Plus d'explications dans /partage/procédure_impression.pdf sous linux\n
   et sur Windows sur le dossier "Partage" sur le bureau \n\n\
  Vérifiez ci dessous l'état de la file d'impression, si des documents s'y trouvent\n\
  attendez qu'ils soient imprimés, si ces documents bloquent la file, vous ne pourrez pas imprimer\n\
  Voyez avec un tuteur\n\n\
  Si vous même vous n'obtenez pas vos impressions, après les avoir lancées, pensez à les annuler si non vous bloquerez les autres\n\
  Respectez la chartre\n\n\
  Pour le moment vous ne pouvez pas imprimer des fichiers avec des espaces, rénommez les\n\n\
  MERCI\n\n\
  Apuyer sur "OK" pour continuer...\n\n\
  ETAT DE L'IMPRIMANTE:\n\
  $LPQ" 0 0
 # else
 # whiptail --title "$TITLE"\
 # --msgbox "Bienvenue sur le module d'impression du SIF.\n\n\n\
 # Désolé, il semble qu'une impression est bloqué, ou que l'imprimante n'est pas prête \n\n\
 # Vous ne pouvez pas imprimer pour le moment.\n\
 # Il peux être nécessaire de redémarrer pour supprimer la file d'impression\
 # Dans ce cas appuyez en même temps sur les touches Ctrl+Alt+Suppr, la marchine redémarera\n\n\
 # Ou bien demandez l'aide à un tuteur\n\n\
 # Etat de imprimante: $LPQ" 0 0
 # exit
 # fi
}

function menu(){
  ### Menu
  choice=$(whiptail --title "$TITLE" --menu "Votre quota impression: $QUOTA Pages\nVous occupez $QUOTA_DISQUE\nQue voulez vous faire ? " 0 0 0 \
  "1" "Afficher l'état de l'imprimante" \
  "2" "Imprimer les fichiers PDF" \
  "3" "Annuler les impressions envoyées" \
  "4" "Afficher le quota d'impression et l'espace disque occupé" \
  "5" "Quiter" 3>&1 1>&2 2>&3)
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
	suppr_file_impression
        menu
        ;;
      4)
	Quota
	menu
	;;
      5)
	# marche po il fot etre root, au fait il faut lancer le script avec l'option "&& exit"
	#kill -HUP `pgrep -s 0 -o`
	# logout
	clear
        exit 0
        ### Or logout
        ;;
    esac
  else
    	exit && logout
	#exit 0
  fi
}


### Launch welcoming and menu
Welcome
menu

exit 0
