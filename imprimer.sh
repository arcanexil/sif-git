#!/bin/bash
# imprimer.sh - User Friendly's menu to print in UPSUD's SIF
# Author : Lucas Ranc <lucas.ranc@gmail.com>

### Def some global vars

TITLE="SIF"
LPQ=`lpq`

QUOTA=`quota`

# LPQ="HP-LaserJet-P4015 est prêt aucune entrée"
QUOTA_DISQUE=`du -sh ~ | cut -f1`

function Quota(){
### Print quota user :
# Replace with quota $USER
  whiptail --title "$TITLE"\
  --msgbox "Vous êtes logué sous l'identité $USER, Vous coccupez actuellement : $QUOTA_DISQUE .\n\
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
  LPQ=$(lpq)
  whiptail --title "$TITLE"\
  --msgbox "Etat de l'imprimante :\n\n $LPQ" 0 0
 }

function Pdf_Ps_Check(){
  ###
  ### Check for pdf files
  ### Take an arg to change the folder
  ### Result into $filepath
  ###

  cherche=$(find $HOME \( ! -regex '.*/\..*' \) -type f \( -name "*.ps" -o -name "*.pdf" \) | while read i;do taille=$((du -sh "$(dirname "$i")/$(basename "$i")")| cut -f1);echo -e "$i""|""$taille";  done)

    oldIFS="$IFS"
    IFS=$'|\n'
    filepath=($cherche)
    IFS=$' \t\n'

}

function suppr_file_impression(){
  ###
  ### Manage owner print qeu
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
      	if [ $status = 0 ] && [ ! -z $numero_job ] || [ $numero_job == "-" ]; then
      		num_job=`lprm $numero_job 2>&1`
          	if [ -z "$num_job" ]; then
            		if [ $numero_job == "-" ]; then
               			whiptail --msgbox "Tous vos jobs ont été annulés" 0 0
            		else
               			whiptail --msgbox "Le job $numero_job a bien été annulé" 0 0
            		fi
          	else
            		whiptail --msgbox "La tache $numero_job n'existe pas ou à déjà été annulée" 0 0
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

      # $1 est l'argument passé à la fonction Print
      # echo "lpr $1 -#$CopyNumber $pathselect" >> /home/$USER/impression.txt
      if [ "$type_f" == "PostScript" ]; then
	mv "$pathselect" $HOME/doc.ps
      elif [ "$type_f" == "PDF" ]; then
	echo
      fi
      lpr -#$CopyNumber $HOME/doc.ps
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
  "1" "Imprimer eco responsable en recto-verso ?" \
  "2" "Imprimer recto ?" \
  "3" "Retour au menu" 3>&1 1>&2 2>&3)
  status=$?

  if [ $status -eq 0 ]; then
    case $choice in
      1 )
      Print -D
      ;;
      2 )
      Print
      ;;
      3 )
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
Pdf_Ps_Check
  ### Ask which file to use

   pathselect=$(whiptail --menu "Selectionnez un fichier à imprimer" 0 0 0 \
    --cancel-button Retour --ok-button Select "${filepath[@]}" 3>&1 1>&2 2>&3)
   status=$?
   #file `echo $pathselect` | grep postScript  && whiptail --msgbox "Vous avez selectionné un fichier PS" 0 0
  #file `echo $pathselect` | grep PDF && whiptail --msgbox "Vous avez selectionné un fichier PDF $pathselect" 0 0
   cp "$pathselect" source.pdf
   type_f=`file "$pathselect" | cut -d: -f2 | cut -d" " -f2`
   taille=`du "$pathselect" | awk -F " " '{print $1}'`
  #whiptail --msgbox "type_f: $type_f" 0 0

### Now we check the result path :

  if [ "$type_f" == "PDF" ]; then

    if [ $taille -gt "10000" ]; then
       whiptail --yesno "Attention le fichier: $pathselect occupe : $taille Kiloctets, l'impression risque d'être lente, si vous le souhaitez nous allons de tenter de le reduire, si toute fois le resultat obtenu n'est pas satifaisant, repondez non pour l'imprimer tel quel" 0 0
       status=$?
       if [ $status -eq 0 ];then
	test -f doc.pdf && mv doc.pdf doc.pdf.bak
	optimise.sh -s source.pdf -o doc.pdf & 3>&1 1>&2 2>&3
        # Here you can test others options :
	# optimize_pdf.sh "$pathselect" & 3>&1 1>&2 2>&3
	# gs -sDEVICE=pdfwrite -dCompatibilityLevel=1.4 -dPDFSETTINGS=/screen -dNOPAUSE -dProcessColorModel=/DeviceGray -dColorConversionStrategy=/Gray -dQUIET -dBATCH -sOutputFile=doc.pdf "$pathselect" & 3>&1 1>&2 2>&3
       
     # Keep checking if the process is running. And keep a count.
     {    i="0"
        while (true)
        do
             proc=$(ps aux | grep -v grep | grep pdfwrite)
	     #proc=$(ps aux | grep -v grep | grep setpdfwrite)
	     #proc=$(ps aux | grep -v grep | grep "gs" | grep "sDEVICE")
            if [ "$proc" == "" ]; then break; fi
            # Sleep for a longer period if the database is really big
            # as dumping will take longer.
            sleep 1
            echo $i
            i=$(expr $i + 1)
        done
        # If it is done then display 100%
        echo 100
        # Give it some time to display the progress to the user.
        sleep 2
     } | whiptail --title "Optimisation" --gauge "Merci de patienter, Optimisation de $pathselect en cours... " 0 0 0
       whiptail --yesno "Taille de $pathselect : $taille, Octets, Taille reduite : `du doc.pdf | awk '{print $1}'` Octets, Voulez vous imprimer ?;" 0 0
      status=$?
      if [ $status -ne 0 ]; then
	menu
      fi
    fi

  fi

  test -f doc.ps && mv doc.ps doc.ps.bak
  pdftops source.pdf $HOME/doc.ps&
  # not work if $pathselect contains spaces
  # pdftops $pathselect $HOME/doc.ps&

     # Keep checking if the process is running. And keep a count.
     {    i="0"
        while (true)
        do
            proc=$(ps aux | grep -v grep | grep -e "pdftops")
            if [[ "$proc" == "" ]]; then break; fi
            # Sleep for a longer period if the database is really big
            # as dumping will take longer.
            sleep 1
            echo $i
            i=$(expr $i + 1)
        done
        # If it is done then display 100%
        echo 100
        # Give it some time to display the progress to the user.
        sleep 2
     } | whiptail --title "$TITLE" --gauge "Patientez conversion de $pathselect en cours ...selon la taille du fichier" 0 0 0
    AskOptions
  elif [ $status -eq 0 -a "$type_f" == "PostScript" ]; then
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
  # il faut penser à gérer la sortie de la commande lpq
  imprimante_prete=`lpq | wc -l`

  # Il peut etre intressant de tester si une impression bloque la file depuis un certain temps 
  # Ici on teste juste si la file contient au moins un document
  #if [ "$imprimante_prete" == "4" ]; then
    whiptail --title "$TITLE"\
  --msgbox "Bonjour et bienvenue sur le module d'impression du SIF.\n\n\
  Pour imprimer vous devez avoir enregistré votre fichier au format PS (pour gagner du temps) ou PDF (conversion prise en charge par le script)\n\n\
  Si ce n'est pas le cas, allez sur un PC libre et convertissez le !\n\
  Cette application recherche et affiche tous les fichiers PDF ou PS dans votre dossier \n\n\
  Utilisez ensuite les touches flechées pour selectionner le fichier à imprimer\n\
  Plus d'explications dans /partage/procédure_impression.pdf sous linux\n\
  et sur le dossier "Partage" sur le bureau sous Windows\n\n\
  Avant d'imprimer, vérifiez l'état de la file d'impression, si des documents s'y trouvent\n\
  et qu'ils bloquent l'impression, vous ne pourrez pas imprimer et vous perdrez les pages sur votre crédit !\n\
  Un tuteur est là pour vous aider entre 12h00 et 14h00 puis entre 17h00 et 19h00\n\n\
  Si vous même vous n'obtenez pas vos impressions, après les avoir lancées, pensez à les annuler si non vous bloquerez les autres\n\
  Respectez la chartre\n\n\
  MERCI\n\
  Le Service Informatique des Formations\n\
  Apuyer sur "OK" pour continuer... " 0 0
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
  "2" "Imprimer (PDF ou PS)" \
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
	# et sur mon portable cela fonctionne : mettre la commande "imprimmer.sh && exit" dans /etc/profile
	# 
	#kill -HUP `pgrep -s 0 -o`
	# logout
	exit
        ### Or logout
        ;;
    esac
  else
	IFS=$' \t\n'
	exit
	#exit 0
  fi
}


### Launch welcoming and menu
Welcome
menu

exit 0
