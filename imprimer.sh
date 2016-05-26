#!/bin/bash
# imprimer.sh - User Friendly's menu to print in UPSUD's SIF
# Author : Lucas Ranc <lucas.ranc@gmail.com>, Mounir Aatif <mounir.aatif@free.fr>
# ------------------------------------
# Add function Eps2ps, convert eps to ps 
# Replace files with space by "_" caracter
#  
#--------------------------
# to work this script must use with /opt/imp/bin/verif.sh and majcredit.sh
# and /usr/local/etc/quota.sh quota.staff and quota.suid (bit suid)
# and /usr/local/bin/quota and lpr (bit suid) and optimise.sh

### Def some global vars
cd $HOME
# echo "Entre dans Script"
TITLE="SIF"
LPQ=`lpq`

# Pour info 
# DP="-o sides=two-sided-short-edge" # paysage
# DL="-o sides=two-sided-long-edge"  # portrait

# On SIF commande quota return quota user like that : 46/100
# if root "quota user" ask new page credit to add to the current quota user
# 

#################################################"
# FUNCTION HELP
function Aide(){
whiptail --title "$TITLE"\
     --msgbox "Pour pouvoir imprimer au SIF il faut au préalable avoir converti votre fichier au format PDF ou PS\n\
Pour cela ouvrez votre fichier sur un PC libre et allez dans le menu imprimer puis choisissez \n\
une imprimante virtuelle PDF_Creator ou Xerox (sous Windows) ou imprimer dans un fichier (sous Linux)\n\n\
Sous Windows vous devez enregistrer votre fichier sous le répertoire personnel (désigné par la lettre U:)\n\n\
Pour savoir comment convertir votre fichier au format PDF ou PS consultez le dossier /partage/procédure_impression.pdf\ sous linux\n\
Ce même dossier "Partage" se trouve aussi sur le bureau sous Windows\n\n\
LE SIF" 0 0

}

# SIF output quota : credit/total
QUOTA=`quota`
CREDIT=`echo $QUOTA | cut -d/ -f1`


QUOTA_DISQUE=`du -sh ~ | cut -f1`

#####################################################
# FUNCTION QUOTA Retun quota disk an quota print user
#
# echo "Entre dans Quota"
function Quota(){
### Print quota space and quota print user :
#

QUOTA=`quota`
CREDIT=`echo $QUOTA | cut -d/ -f1`
  if [ $CREDIT -gt 0 ]; then
     whiptail --title "$TITLE"\
     --msgbox "Vous êtes logué sous l'identité $USER\n\
     Vous coccupez actuellement : $QUOTA_DISQUE sur votre espace personel\n\
     Votre quota impresion est de : $QUOTA\n\n\
     Lorsque vous n'aurez plus de crédit impression, demandez au tuteur\n\
     qui en fera la demande, vous recevrez une notification par mail\n\
     vous informant de votre nouveau crédit\n\n\
     Attention vous avez droit à un seul renouvellement de 100 pages de crédit, si vous devez imprimer que
     quelque pages, faites le au moment d'exporter (enregistrer) votre fichier au format PDF " 0 0
  else
     whiptail --title "$TITLE"\
     --msgbox "Quota : $QUOTA ,Attention vous n'avez plus de crédit, veuillez en faire la demande à un tuteur\n\
     vous recevrez une notification par mail, vous informant de votre nouveau crédit\n\n\ " 0 0
     exit O
  fi
}

#####################################################
# FUNCTION Etat_imprimante Return printer status
#
# echo "Entre dans Etat_imprimante" 
function Etat_imprimante(){
  ###
  ### Check and show printer status
  ###
  ### 
  LPQ=$(lpq)
  imprimante_prete=`lpq | wc -l`
  if [ "$imprimante_prete" == "2" ]; then
     whiptail --title "$TITLE"\
     --msgbox "Etat de l'imprimante :\n\n $LPQ\n\n\
     Vous pouvez imprimer..." 0 0
  else
     whiptail --title "$TITLE"\
     --msgbox "Etat de l'imprimante :\n\n $LPQ\n\n\
     Attendez que l'impression se termine avant d'en lancer une autre" 0 0
  fi
 }

#####################################################
# FUNCTION PDF_PS_CHECK Search all pdf and postscript file, igonre hiden
# and put them in cherche with IFS=$'|\n' and stored in arrawy filepath  
#

function Pdf_Ps_Check(){
# echo "Entre dans Pdf_Ps_Check"
###
### Search pdf and postscript files, ignore hidden folders
### 
### Result into $filepath
###

QUOTA=`quota`
CREDIT=`echo $QUOTA | cut -d/ -f1`
if [ $CREDIT -le 0 ]; then  
     whiptail --title "$TITLE"\
     --msgbox "Quota : $QUOTA ,Attention vous n'avez plus de crédit, veuillez en faire la demande à un tuteur\n\
     vous recevrez une notification par mail, vous informant de votre nouveau crédit\n " 0 0
     exit O
fi
cherche=`find $HOME \( ! -regex '.*/\..*' \) -type f \( -name "*.ps" -o -name "*.pdf" \) | while read i;do du -s "$i";  done | sort -n -r | awk -F"\t" '{print $2"|"$1}'`

# If no files found, put message and return to menu
if [ -z $cherche ]; then
    whiptail --msgbox "Aucun fichier PDF ou PS trouvé" 0 0
    menu
fi
    # This for whiptail input see function Procedure
    IFS=$'|\n'
    filepath=($cherche)
    IFS=$' \t\n'
}

#####################################################
# FUNCTION Suppr_file_impression, cancel jobs
#

function Suppr_file_impression(){
  # echo "Entre dans Suppr_file_impression"
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
            		elif [ $numero_job == "0" ]; then
				whiptail --msgbox "Le job $numero_job ne peut être annulé" 0 0
			else
               			whiptail --msgbox "Le job $numero_job a bien été annulé" 0 0
            		fi
          	else
            		whiptail --msgbox "La tache $numero_job n'existe pas, ne vous appartient pas ou à déjà été annulée" 0 0
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
# in output.ps and send to print 
#

function Print(){
  # echo "Entre dans print" 
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
	Menu
      fi
      
      # whiptail --msgbox "Impression envoyée" 0 0
      
      # For custom scrip lpr in SIF replace by this :
      echo "o" | lpr $1 -#$CopyNumber $HOME/output.ps
      # lpr $1 -#$CopyNumber $HOME/output.ps
      Menu
    else
      whiptail --title "$TITLE"\
      --msgbox "Attention : \n Vous n'avez pas spécifié de nombre" 0 0
    fi
  else
    Menu
  fi
}

#############################################################################
# FUNCTION ASKOPTIONS Ask print options before printing 
#

function AskOptions(){

  # echo "Entre dans AskOptions"
  choice=$(whiptail --title "$TITLE" --menu "Choisir une option" 0 0 0 \
  "1" "Imprimer recto ?" \
  "2" "Imprimer en recto-verso ?" \
  "3" "Retour au menu" 3>&1 1>&2 2>&3)
  status=$?
  if [ $status -eq 0 ]; then
    case $choice in
      1 )
      Print
      ;;
      2 )
      Print -DP
      ;;
      3 )
      Menu
      ;;
    esac
  else
      Menu
  fi
}

#############################################################################
# FUNCTION PROCEDURE Test file type selected, and proced to optimization if necessary 
# then convert to postscript fo print


function Procedure(){


  # Search pdf and ps files
  # echo "Entre dans Procedure"
  # serarch and get files
  Pdf_Ps_Check
  ### Ask which file to use and stored in $pathselect
  pathselect=$(whiptail --menu "Selectionnez un fichier à imprimer" 0 0 0 \
    --cancel-button Retour --ok-button Select "${filepath[@]}" 3>&1 1>&2 2>&3)
  status=$?

  # If cancel-button then return to menu
  if [ $status -ne 0 ]; then
   Menu
  fi  

  # Replace space by "_" in pathselect, to shell commands
  [[ "$pathselect" =~ " " ]] && mv "$pathselect" "${pathselect// /_}" && pathselect="${pathselect// /_}" \
  && whiptail --title "$TITLE" --msgbox "Votre fichier: `basename $pathselect` contenait des espaces ils ont étés remplacés par des "_" " 0 0
  # Determine type file PDF or PostScript, and size
  type_f=`file "$pathselect" | cut -d: -f2 | cut -d" " -f2` 
  taille_source=`du "$pathselect" | awk -F " " '{print $1}'`

  #Case PDF
  if [ "$type_f" == "PDF" ]; then
      # whiptail --title "$TITLE" --msgbox "PDF : $type_f" 0 0
      # Prudently we copy the file in source.pdf to eliminate special caracteres ans spaces  
      # the commande pdfinfo not accept files with spaces
      # cp -f $pathselect $HOME/source.pdf
      # Determine numbers of pages in  the document
      pages=`pdfinfo $pathselect | grep Pages | awk -F " " '{print $2}'`
     
      # ( at this step we can test quota user to compare and tel them if $pages grant to quota )
      # Confirm to print all pages
      whiptail --yesno "Vous allez imprimer: $pages pages" 0 0
      status=$?
      
      # If no return to menu 
      if [ $status -ne 0 ];then
         Menu
      fi
      
      # If size grant to 40 Mo, we ask for optimization, Warning : require Optimise.sh script
      if [ $taille_source -gt "40000" ]; then
         whiptail --yesno "Attention le fichier: $pathselect occupe : $taille_source Kiloctets, l'impression risque d'être lente, si vous le souhaitez nous allons de tenter de le reduire, si toute fois le resultat obtenu n'est pas satifaisant, repondez non pour l'imprimer tel quel" 0 0
      status=$?
         # If yes, then go Optimise 
         if [ $status -eq 0 ];then
            Optimise
	    # if optimized copy in source.pdf (only source.pdf is printed)
            taille_doc=$(du doc.pdf | awk -F " " '{print $1}')
            
	      if [ "$taille_doc" -lt "$taille_source" ]; then
		cp doc.pdf source.pdf
	     fi

         whiptail --yesno "Taille de $pathselect : $taille, Octets, Taille reduite : `du doc.pdf | awk '{print $1}'` Octets, Voulez vous imprimer ?;" 0 0
      
            # If no return Menu
            status=$?
              if [ $status -ne 0 ]; then
	       Menu
              fi

           # Send to convert ps and printing 
	   Conversion
        # End optimize
        fi
     
     # End if $taille -gt 10 Mo 
     fi     
     Conversion
  # End PDF file
  fi

  # Case postScript
  if [ "$type_f" == "PostScript" -o "$type_f" == "HP" ]; then

      # whiptail --title "$TITLE" --msgbox "PostScrip : $type_f" 0 0
      # Eliminate spaces and special car, custom lpr script don't accept them
      #test -f output.ps && cp output.ps output.ps.bak
      cp "$pathselect" /$HOME/output.ps

      # Calculate pages
      # nb = nb occurences of Pages ps
      nb=`grep Pages $pathselect | awk -F " " '{print $2}' | wc -l`
      if [ $nb -gt 1 ]; then
	pages=`grep Pages $pathselect | awk -F " " '{print $2}' | tail -1`
      else
	pages=`grep Pages $pathselect | awk -F " " '{print $2}'`
      fi
      #  at this point we can test quota user to compare and tel them if $pages grant to quota
      
      whiptail --yesno "Vous allez imprimer: $pages pages" 0 0
      status=$?
      # If no, return to Menu, else AskOption for print
      if [ $status -ne 0 ];then
         Menu
      fi

      # Ask for print

      if [ $pages = 1 ]; then
	Print
      fi

      AskOptions
  elif [ "$type_f" == "PJL" ]; then
      whiptail --title "$TITLE" --yesno "Fichier PS Encapsulé : $type_f, voulez vous le convertir pour impression ?" 0 0
      status=$?
      # If no, return to Menu, else function epstops
      if [ $status -ne 0 ];then
         Menu
      fi
      Eps2ps
  # No files selected, or other... 
  else
      whiptail --title "$TITLE" --msgbox "Attention : \n Seul des pdf ou des ps peuvent être imprimés :\nfichier : $pathselect \n Type : `file $pathselect`\n Recreez le fichier PDF ou adressez-vous à un tuteur pendant ses heures de bureau." 0 0

  fi

}


#############################################################################
# FUNCTION Optimise, use script Optimise.sh very slow if pdf contain vectorized images
# echo "Entre dans Optimise"
function Optimise(){
	    optimise.sh -s $pathselect -o doc.pdf & 3>&1 1>&2 2>&3
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



#############################################################################
# FUNCTION Conversion Convert source.pdf to output.ps (needed by custom lpr script)
# echo "Entre dans Conversion"
function Conversion(){
     
      # whiptail --title "$TITLE" --msgbox "Impression directe...de $pathselect" 0 0
      pdftops $pathselect $HOME/output.ps & 3>&1 1>&2 2>&3

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
      } | whiptail --title "$TITLE" --gauge "Patientez Conversion de $pathselect en cours ...selon la taille du fichier" 0 0 0


      if [ $pages = 1 ]; then
	Print
      fi
      # Ask for print
      AskOptions
}

#################################################"
# FUNCTION EPS2PS, convert to ps if encapsuled ps
function Eps2ps(){
# echo "Entre dans Eps2ps"
ps2ps $pathselect $HOME/output.ps & > /dev/null
# Keep checking if the process is running. And keep a count.
      {    i="0"
      while (true)
      do
            proc=$(ps aux | grep -v grep | grep -e "/usr/bin/gs" | awk '{print $1}')
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
      } | whiptail --title "$TITLE" --gauge "Patientez Conversion de $pathselect qui est un fichier PostScript Encapsulé en cours ...selon la taille du fichier" 0 0 0


      if [ $pages = 1 ]; then
	Print
      fi
AskOptions

}

#################################################"
# FUNCTION WELCOME
function Welcome(){
# echo "Entre dans Welcom"
  ### Welcome :
  # il faut penser à gérer la sortie de la commande lpq

  # Il peut etre intressant de tester si une impression bloque la file depuis un certain temps 
  # Ici on teste juste si la file contient un document ou plus on demande d'attendre que l'impression de termine
  # on évite ainsi la perte de crédit

# Avant d'aller plus loin on teste s'il y a du crédit
  if [ $CREDIT -le 0 ]; then  
     whiptail --title "$TITLE"\
     --msgbox "Quota : $QUOTA ,Attention vous n'avez plus de crédit, veuillez en faire la demande à un tuteur\n\
     vous recevrez une notification par mail, vous informant de votre nouveau crédit\n " 0 0
     exit O
  fi

  lpq 2>/dev/null
  
  if [ $? = 1 ]; then
	whiptail --title "$TITLE" --msgbox "Imprimante non prête, le service CUPS est il lancé?\n\
	y a il une imprimante declarée par défaut ?" 0 0
	exit
  fi

  # print is ready
  imprimante_prete=`lpq | wc -l`
  if [ "$imprimante_prete" -gt "2" ]; then

  whiptail --title "$TITLE"\
  --msgbox "Bienvenue sur le module d'impression du SIF.\n\n\n\
  ATTENTION Une impression est en cours, attendez qu'elle se termine,\n\n\
  Si c'est votre impression qui bloque, allez dans le menu : Annuler les impressions envoyées \n\
  et supprimez les\n\n\
  Si l'impression est bloquée par un autre utilisateur, assurez vous qu'il n'attend pas l'impression, puis redémarrer\n\
  le PC pour supprimer la file d'impression et reconnectez vous et tapez imprimer à nouveau\n\n\
  Pour redémarrer, appuyez en même temps sur les touches Ctrl+Alt+Suppr\n\
  Ou bien demandez l'aide à un tuteur\n\n\
  Voici l'état de imprimante: $LPQ" 0 0

  fi

    whiptail --title "$TITLE"\
  --msgbox "Bonjour et bienvenue sur le module d'impression du SIF.\n\n\
  Pour imprimer vous devez avoir enregistré votre fichier au format PS (pour gagner du temps) ou PDF (Conversion prise en charge par le script)\n\n\
  Si ce n'est pas le cas, allez sur un PC libre et convertissez le !\n\
  Cette application recherche et affiche tous les fichiers PDF ou PS dans votre dossier \n\n\
  Utilisez ensuite les touches flechées pour selectionner le fichier à imprimer\n\
  Plus d'explications dans /partage/procédure_impression.pdf sous linux\n\
  Ce même dossier "Partage" se trouve sur le bureau sous Windows\n\n\
  Avant d'imprimer, n'hesitez pas à vérifiez l'état de la file d'impression, si des documents s'y trouvent\n\
  et qu'ils bloquent l'impression, vous ne pourrez pas imprimer et vous perdrez les pages sur votre crédit !\n\
  Un tuteur est là pour vous aider entre 12h00 et 14h00 puis entre 17h00 et 19h00\n\n\
  Si vous même vous n'obtenez pas vos impressions, après les avoir lancées, pensez à les annuler si non vous bloquerez les autres\n\
  Respectez la chartre\n\n\
  MERCI\n\
  Le Service Informatique des Formations\n\
  Apuyer sur "OK" pour continuer... " 0 0
    
}

#################################################"
# FUNCTION MENU
function Menu(){
# echo "Entre dans Menu"  
  ### Menu
  choice=$(whiptail --title "$TITLE" --menu "Votre quota impression: $QUOTA Pages\nVous occupez $QUOTA_DISQUE\nEtat de l'imprimante :`lpq` \n\n Que voulez vous faire ? " 0 0 0 \
  "1" "Afficher l'aide" \
  "2" "Imprimer (PDF ou PS)" \
  "3" "Annuler les impressions envoyées" \
  "4" "Afficher le quota d'impression et l'espace disque occupé" \
  "5" "Rafraichir l'état de la file d'impression" \
  "6" "Quiter" 3>&1 1>&2 2>&3)
  status=$?
  if [ $status -eq 0 ]; then
    case $choice in
      1 )
        Aide
        Menu
        ;;
      2 )
        Procedure
        Menu
        ;;
      3 )
	Suppr_file_impression
        Menu
        ;;
      4)
	Quota
	Menu
	;;
      5)
        Menu
	;;
      6)
	whiptail --title "$TITLE" --msgbox "N'oubliez pas de vous deconnecter en tapant exit ou Ctrl+d\n\n\
        A bientôt..." 0 0
	clear
	exit
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
Menu
exit 0
