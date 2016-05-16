#!/bin/bash
# imprimer.sh - User Friendly's menu to print in UPSUD's SIF
# Author : Lucas Ranc <lucas.ranc@gmail.com>, Mounir Aatif <mounir.aatif@free.fr>

### Def some global vars
echo "Debut Script"
TITLE="SIF"
LPQ=`lpq`
# On SIF commande quota return quota user like that : 46/100
# if root "quota user" ask new page credit to add to the current quota user
# On my laptop I créate srcipt quota  
# QUOTA=$(tail -1 /commun/quota/$USER | awk -F":" '{print $3}')
# QUOTA=$(echo $ancien_quota | tr -d "\t")

# Save olds files
  test -f source.pdf && mv source.pdf source.pdf.bak
#  test -f doc.ps && mv doc.ps doc.ps.bak

# SIF
QUOTA=`quota`

QUOTA_DISQUE=`du -sh ~ | cut -f1`

#####################################################
# FUNCTION QUOTA Retun quota disk an quota print user
#
echo "Debut Quota"
function Quota(){
### Print quota space and quota print user :
#
 
QUOTA=`quota`
  whiptail --title "$TITLE"\
  --msgbox "Vous êtes logué sous l'identité $USER, Vous coccupez actuellement : $QUOTA_DISQUE .\n\
    Votre quota impresion est de : $QUOTA\n\n\
    Si vous n'avez plus de crédit impression, demandez au tuteur\n\
    qui en fera la demande, vous recevrez une notification par mail\n\
    Vous informant de votre nouveau crédit\n\n\
    Attention vous avez droit à un seul renouvellement de 100 " 0 0
}


#####################################################
# FUNCTION ETAT_IMPRIMANTE Return printer status
#
echo "Debut etat_imprimante" 
function etat_imprimante(){
  ###
  ### Check and show printer status
  ###
  ### 
  LPQ=$(lpq)
  whiptail --title "$TITLE"\
  --msgbox "Etat de l'imprimante :\n\n $LPQ" 0 0
 }

#####################################################
# FUNCTION PDF_PS_CHECK Search all pdf and postscript file, igonre hiden
# and put them in cherche with IFS=$'|\n' and stored in arrawy filepath  
#
echo "Debut Pdf_Ps_Check"
function Pdf_Ps_Check(){
  ###
  ### Search pdf and postscript files, ignore hidden folders
  ### 
  ### Result into $filepath
  ###
  cherche=$(find $HOME \( ! -regex '.*/\..*' \) -type f \( -name "*.ps" -o -name "*.pdf" \) | while read i;do taille=$((du -sh "$(dirname "$i")/$(basename "$i")")| cut -f1);echo -e "$i""|""$taille";  done)
    oldIFS="$IFS"
    IFS=$'|\n'
    filepath=($cherche)
    IFS=$' \t\n'
}

#####################################################
# FUNCTION SUPPR_FILE_IMPRESSION, cancel jobs
#
echo "Debut suppr_file_impression"
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
      	
	# Not work, lpq return truncated uid
	# proprietaire=`lpq | grep $numero_job | awk -F " " '{print $2}'`
	# if [ "$USER" != "$proprietaire" ]; then
	#	whiptail --msgbox "Ce job ne vous appartien pas" 0 0
	# fi

        if [ $status = 0 ] && [ ! -z $numero_job ] || [ $numero_job == "-" ]; then
      		num_job=`lprm $numero_job 2>&1`
          	if [ -z "$num_job" ]; then
            		if [ $numero_job == "-" ]; then
               			whiptail --msgbox "Tous vos jobs ont été annulés" 0 0
            		else
               			whiptail --msgbox "Le job $numero_job a bien été annulé" 0 0
            		fi
          	else
            		whiptail --msgbox "La tache $numero_job n'existe, ne vous appartient pas ou à déjà été annulée" 0 0
          	fi
        else
            whiptail --msgbox "Le numéro entré ne correspond pas à un numéro de tache, vérifier la file" 0 0
        fi
      else
        whiptail --msgbox "Uniquement des chiffres, repérez le numéro du job dans la file !" 0 0
      fi
     else
      whiptail --msgbox "Pas de file d'impression" 0 0
   fi
}

#############################################################################
# FUNCTION PRINT Ask how copy's to print "CopyNumber" if postscript copy them
# in doc.ps and send to print 
#
echo "Debut print" 
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
      
      whiptail --msgbox "Impression envoyée" 0 0
      
      # For custom scrip lpr in SIF replace by this :
      # echo "o" | lpr -U $USER -#$CopyNumber $HOME/doc.ps
      lpr -U $USER -#$CopyNumber $HOME/doc.ps
      menu
    else
      whiptail --title "$TITLE"\
      --msgbox "Attention : \n Vous n'avez pas spécifié de nombre" 0 0
    fi
  else
    menu
  fi
}

#############################################################################
# FUNCTION ASKOPTIONS Ask print options before printing 
#
echo "Debut AskOptions"
function AskOptions(){
  choice=$(whiptail --title "$TITLE" --menu "Choisir une option" 0 0 0 \
  "1" "Imprimer en recto-verso ?" \
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

#############################################################################
# FUNCTION PROCEDURE Test file type selected, and proced to optimization if necessary 
# then convert to postscript fo print
echo "Debut Procedure"

function Procedure(){
  
  
  # Search pdf and ps files
  Pdf_Ps_Check
  
  ### Ask which file to use and stored in $pathselect
  pathselect=$(whiptail --menu "Selectionnez un fichier à imprimer" 0 0 0 \
    --cancel-button Retour --ok-button Select "${filepath[@]}" 3>&1 1>&2 2>&3)
  status=$?
 
  # If cancel-button then return to menu
  if [ $status -ne 0 ]; then
   menu
  fi  
  
  # Replace space by "_" in pathselect, to shell commands
  [[ "$pathselect" =~ " " ]] && cp "$pathselect" "${pathselect// /_}"
  pathselect="${pathselect// /_}"
  # Determine type file PDF or PostScript, and size
  type_f=`file "$pathselect" | cut -d: -f2 | cut -d" " -f2` 
  taille=`du "$pathselect" | awk -F " " '{print $1}'`

  #Case PDF
  if [ "$type_f" == "PDF" ]; then

      # Prudently we copy the file in source.pdf to eliminate special caracteres ans spaces  
      # the commande pdfinfo not accept files with spaces
      cp -f $pathselect $HOME/source.pdf
      # Determine numbers of pages in  the document
      pages=`pdfinfo source.pdf | grep Pages | awk -F " " '{print $2}'`
      
      # ( at this step we can test quota user to compare and tel them if $pages grant to quota )
      # Confirm to print all pages
      whiptail --yesno "Vous allez imprimer: $pages pages" 0 0
      status=$?
      
      # If no return to menu 
      if [ $status -ne 0 ];then
         menu
      fi
      
      # If size grant to 40 Mo, we ask for optimization, Warning : require optimise.sh script
      if [ $taille -gt "40000" ]; then
         whiptail --yesno "Attention le fichier: $pathselect occupe : $taille Kiloctets, l'impression risque d'être lente, si vous le souhaitez nous allons de tenter de le reduire, si toute fois le resultat obtenu n'est pas satifaisant, repondez non pour l'imprimer tel quel" 0 0
      status=$?
         # If yes, then go optimise 
         if [ $status -eq 0 ];then
            optimise
	    # if optimized copy in source.pdf (only source.pdf is printed)
            taille_source=$(du source.pdf | awk -F " " '{print $1}')
	    taille_doc=$(du doc.pdf | awk -F " " '{print $1}')
            
	      if [ "$taille_doc" -lt "$taille_source" ]; then
		cp doc.pdf source.pdf
	     fi

         whiptail --yesno "Taille de $pathselect : $taille, Octets, Taille reduite : `du doc.pdf | awk '{print $1}'` Octets, Voulez vous imprimer ?;" 0 0
      
            # If no return menu
            status=$?
              if [ $status -ne 0 ]; then
	       menu
              fi

           # Send to convert ps and printing 
	   conversion
        # End optimize
        fi
     
     # End if $taille -gt 10 Mo 
     fi     
     conversion
  # End PDF file
  fi

  # Case postScript
  if [ "$type_f" == "PostScript" ]; then

      # Eliminate spaces and special car, custom lpr script don't accept them
      test -f doc.ps && cp doc.ps doc.ps.bak
      cp "$pathselect" /$HOME/doc.ps

      # Calculate pages
      # nb = nb occurences of Pages ps
      nb=`grep Pages doc.ps | awk -F " " '{print $2}' | wc -l`
      if [ $nb -gt 1 ]; then
	pages=`grep Pages doc.ps | awk -F " " '{print $2}' | tail -1`
      else
	pages=`grep Pages doc.ps | awk -F " " '{print $2}'`
      fi
      #  at this point we can test quota user to compare and tel them if $pages grant to quota
      
      # If no, return to menu
      whiptail --yesno "Vous allez imprimer: $pages pages" 0 0
      status=$?
      if [ $status -ne 0 ];then
         menu
      fi

      # Ask for print
      AskOptions
  
  # No files selected, or other... 
  else
      whiptail --title "$TITLE" --msgbox "Attention : \n Seul des pdf ou des ps peuvent être imprimés :\nfichier : $pathselect \n Type : `file $pathselect`\n Recreez le fichier PDF ou adressez-vous à un tuteur pendant ses heures de bureau." 0 0

  fi

}

echo "Debut optimise"
#############################################################################
# FUNCTION optimise, use script optimise.sh very slow if pdf contain vectorized images
function optimise(){
	    test -f doc.pdf && mv doc.pdf doc.pdf.bak
            optimise.sh -s source.pdf -o doc.pdf & 3>&1 1>&2 2>&3
	    proc=$(ps aux | grep -v grep | grep "/usr/bin/gs" | awk '{print $1}')
            # Keep checking if the process is running. And keep a count.
            {    i="0"
            while [ true ]
            do
                # Warning conflicts with lp qeu, then grep $USER
		# Sleep for a longer period if the pdf is really big
		sleep 1
		echo $i
		i=$(expr $i + 1)
		proc=$(ps aux | grep -v grep | grep "/usr/bin/gs" | awk '{print $1}' | grep $USER)
		if [ "$proc" == "" ]; then break; fi
		
	    done
            # If it is done then display 100%
            echo 100
            # Give it some time to display the progress to the user.
            sleep 2
	    } | whiptail --title "Optimisation" --gauge "Merci de patienter, Optimisation de $pathselect en cours... " 0 0 0
}


echo "Debut conversion"
#############################################################################
# FUNCTION CONVERSION Convert source.pdf to doc.ps (needed by custom lpr script)
function conversion(){
     
      # whiptail --title "$TITLE" --msgbox "Impression directe...de $pathselect" 0 0
      pdftops source.pdf $HOME/doc.ps & 3>&1 1>&2 2>&3

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

      # Ask for print
      AskOptions
}

echo "Debut Welcom"
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

echo "Debut menu"
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
