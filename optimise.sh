# Posted by azerttyu at 2010-05-07 15:24
#Bonjour

# Ayant du faire face à une problématique similaire, je suis tombé sur cette page. Du coup je propose ces petits ajustement pour en faire un script pret à l'emploi.

#!/bin/bash

DPI=150
PDF_DESTINATION=""

help() {
echo "Aide de optimize_pdf"
echo "-h : aide ci présente"
echo "-d : (optionnel) résolution du pdf final, par defaut : 150"
echo "-s : fichier source, le fichier doit exister"
echo "-o : fichier cible"
}

full_path() {
if [ -z $1 ]; then
exit;
else
if [ `expr substr ${1:-a} 1 2` != "/" ]; then
FULL_FILE=`pwd`"/"$1
fi
fi
echo $FULL_FILE
}

isNumeric(){ echo "$@" | grep -q -v "[^0-9]" ;}

while getopts "s:o:d:h" flag
do
case $flag in
#Source : fichier source
"s")
PDF_FILE=`full_path $OPTARG`
if [ ! -e $PDF_FILE ]; then
echo "Veuillez donner une source valide"
exit=1
fi
;;
#Output : fichier de destination
"o")
PDF_DESTINATION=$OPTARG
;;
#Dpi : resolution voulue
"d")
if [ -z `isNumeric $OPTARG` ]; then
DPI=$OPTARG
else
echo "Veuillez donner une valeur numerique a votre DPI"
exit=1
fi
;;
"h")
exit=1
;;
esac
done

#Une valeur cible est elle presente ?
if [ -z $PDF_DESTINATION ]; then
echo "Veuillez donner un chemin cible"
exit=1
fi

#Au moins une erreur on ne va plus loin
if [ $exit ]; then
help
exit
fi

pdftops \
-paper match \
-nocrop \
-noshrink \
-nocenter \
-level3 \
-q \
"$PDF_FILE" - \
| ps2pdf14 \
-dEmbedAllFonts=true \
-dUseFlateCompression=true \
-dOptimize=true \
-dProcessColorModel=/DeviceRGB \
-dUseCIEColor=true \
-r72 \
-dDownsampleGrayImages=true \
-dGrayImageResolution=$DPI \
-dAutoFilterGrayImages=false \
-dGrayImageDownsampleType=/Bicubic \
-dDownsampleMonoImages=true \
-dMonoImageResolution=$DPI \
-dMonoImageDownsampleType=/Bicubic \
-dDownsampleColorImages=true \
-dColorImageResolution=$DPI \
-dAutoFilterColorImages=false \
-dColorImageDownsampleType=/Bicubic \
-dPDFSETTINGS=/prepress \
- "$PDF_DESTINATION"

