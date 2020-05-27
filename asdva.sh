#!/bin/bash
echo "Welcome to ASDVA (Android Software Design Violation Analyzer)"

echo "If you have an GIT repository, please enter clone address, if not, type n: "
read varname

echo -e "Do you have MVVM design class information ?\nIf yes, press 'y' and enter class information\nif not , press 'n' (Rule-1 processes only)\nif you would like to process default MVVM structure, press 'd'"
read classinfo

ANALYZER_PATH=/home/veyselo/Desktop/smalisca/smalisca

VISUALOUT=0
VISUALNAME="violation"

VIEW_TO_MODEL_1=false
VIEW_TO_MODEL_2=false

MODEL_TO_VIEW_1=false
MODEL_TO_VIEW_2=false

if [ $classinfo == "y" ]; then
 HASCLASSINFO=true
 gedit ./ClassInfo.txt
 date=$(stat -c %y ClassInfo.txt)
 echo $date
 while sleep 1; do date2=$(stat -c %y ClassInfo.txt)
   echo $date2
   if [[ $date2 != $date ]]; then echo "changed!"; break; fi
   # possibly exit [status] instead of break
   # or if you want to watch for another change, date=$date2
 done
 ##prepare Rule#2 cmds r2cmd


IFS=$'\n' read -d '' -r -a lines < ClassInfo.txt

  IFS=":" read var1 var2 <<< "${lines[0]}"
  VIEWCLASS=$var2
  echo $VIEWCLASS
  
  IFS=":" read var3 var4 <<< "${lines[1]}"
  VIEWMODELCLASS=$var4
  echo $VIEWMODELCLASShttps://github.com/veysel-o/MVVM-Sample.git

  IFS=":" read var5 var6 <<< "${lines[2]}"
  MODELCLASS=$var6
  echo $MODELCLASS

  sed -i "s/from_class_v/$VIEWCLASS/g" cmdr2-1.txt

  sed -i "s/to_class_m/$MODELCLASS/g" cmdr2-1.txt

  sed -i "s/from_class_m/$MODELCLASS/g" cmdr2-2.txt

  sed -i "s/to_class_v/$VIEWCLASS/g" cmdr2-2.txt

else
   echo "No class information available, Algorithm checks Rule#1 only"
fi

if [ $classinfo == "d" ]; then
   HASDEFAULTANALYZE=true;
   echo "default mvvm analyze on going"
fi

if [ $varname != "n" ]; then
   echo "GIT REPO"
   cd clone
   git clone $varname
   
   chmod -R 777 ./
   #re-format on unix base
   find . -type f -print0 | xargs -0 dos2unix

   IN="$(cut -d'/' -f5 <<<"$varname")"
   PNAME="$(cut -d'.' -f1 <<<"$IN")"
   echo "$PNAME"
   cd $PNAME

   #check incompatible gradle jar issue
   if [ -f "./gradle/wrapper/gradle-wrapper.jar" ]; then
    echo "gradle JAR exist - Keep on building!"
   else
    cp -rfv ../../gradle-wrapper.jar ./gradle/wrapper/
    echo "gradle JAR support implemented"
   fi
   #

   export ANDROID_HOME=/home/veyselo/Android/Sdk
   ./gradlew assembleDebug
   APPLOC="$(find "$(pwd)" -name "*.apk*")"
   cd ../../de-compilation
   apktool d $APPLOC

   echo $APPLOC
   dcloc="$(cut -d'/' -f13 <<<"$APPLOC")"
   dcloc2=${dcloc%.apk}

   if [ $dcloc2 = "debug" ]; then
   	dcloc="$(cut -d'/' -f14 <<<"$APPLOC")"
   	dcloc2=${dcloc%.apk}
   fi

   echo "$dcloc2"   
   #cd app-debug
   cd $dcloc2
   
   #START Get package information

   PACKAGE=$(xmlstarlet sel -t -v '//manifest/@package' AndroidManifest.xml)
   #echo $PACKAGE
   TAG="$(cut -d'.' -f1 <<<"$PACKAGE")"
   echo $TAG
   
   mkdir smaliProcess

   #if [ -d "./smali_classes3" ]; then

   if [ -d "./smali_classes2" ]; then
    echo "smali files overflow detected - optimize!"
    cp -rfv ./smali/android ./smaliProcess/
    cp -rfv ./smali_classes2/$TAG ./smaliProcess/
   else
    echo "smali files are safe - no need to optimize!"
    cp -rfv ./smali/android ./smaliProcess/
    cp -rfv ./smali/$TAG ./smaliProcess/
   fi

   cd smaliProcess
   ls -l
   #optimize smali inputs
   #shopt -s extglob
   cd ..  
   #exit 0 
   # END

   SMALI_LOC="$(find "$(cd ..; pwd)" -name "smaliProcess")"

   UICOMP=$(xmlstarlet sel -t -v '//activity/@android:name' AndroidManifest.xml)

   stringarray=($UICOMP)
   echo "UI component size = ${#stringarray[@]}"

   echo "list of UI components"
   for each in "${stringarray[@]}"
   do
     echo "$each"
   done

   cd ../../

   #PARSE STARTS -- veyselo	
   smalisca parser -l $SMALI_LOC -s smali -f sqlite -o $PNAME.sqlite

   #PREPARE CMDs AND PROCESS INDUVIDUALLY
   #RULE NO:1

   for each in "${stringarray[@]}"
   do
     > cmd.txt
     echo $'scl -fc from_class -tc Handler
     dcl -fc from_class -tc Handler -f png -o violation
     quit' > cmd.txt

     TRIMMED="$(echo $each | rev | cut -d. -f1 | rev)"
     echo $TRIMMED
     sed -i "s/from_class/$TRIMMED/g" cmd.txt

     smalisca analyzer -i $PNAME.sqlite -f sqlite -c cmd.txt | grep 'No results!' &> /dev/null
     if [ $? == 0 ]; then
       echo "Violation NOT found! for R1"
     else
       echo "Violation found! for R1"
       smalisca analyzer -i $PNAME.sqlite -f sqlite -c cmd.txt > results.txt
       grep -r '| ' ./results.txt > filtered.txt
       #grep -r '| [[:digit:]]' ./results.txt >> filtered.txt
       #rm -rf results.txt
       #sed -i '/init/d' ./filtered.txt
       #tail -n +2 filtered.txt
       VISUALOUT=$((VISUALOUT+1))
       mv filtered.txt $"fResult__${VISUALOUT}".txt
       mv violation.png "${VISUALNAME}_${VISUALOUT}".png 
       feh "${VISUALNAME}_${VISUALOUT}".png &
fi
   done


if [ "$HASDEFAULTANALYZE" = true ] ; then
    echo 'Check DEFAULT 3-class MVVM structure'
    cd ./clone/$PNAME
    pwd
    #this indicates view-1 directly
    echo ${stringarray[0]}
    TRIMMED_VIEW="$(echo ${stringarray[0]} | rev | cut -d. -f1 | rev)"
    echo $TRIMMED_VIEW
    TRIMMED_VIEW+=".java" 
    CLASS_LOCS="$(find . -name ""*$TRIMMED_VIEW*"")"
    echo $CLASS_LOCS
    echo ${CLASS_LOCS%$TRIMMED_VIEW}
    cd ${CLASS_LOCS%$TRIMMED_VIEW}
    cd ..
    pwd
    CLASS_PATHS="$(find . -name ""*.java*"")"
    echo $CLASS_PATHS
    C_INFO=(${CLASS_PATHS// / })
    C_INFO[0]="$(cut -d'/' -f3 <<<"${C_INFO[0]}")"
    C_INFO[0]="$(cut -d'.' -f1 <<<"${C_INFO[0]}")"

    C_INFO[1]="$(cut -d'/' -f3 <<<"${C_INFO[1]}")"
    C_INFO[1]="$(cut -d'.' -f1 <<<"${C_INFO[1]}")"

    C_INFO[2]="$(cut -d'/' -f3 <<<"${C_INFO[2]}")"
    C_INFO[2]="$(cut -d'.' -f1 <<<"${C_INFO[2]}")"
    
    echo ${C_INFO[0]}
    echo ${C_INFO[1]}
    echo ${C_INFO[2]}

    #switch to process analyzer
    cd $ANALYZER_PATH

    if [ "${C_INFO[0]}" = "${TRIMMED_VIEW%.java}" ] ; then
    	echo "C_INFO index 0 is view, process 1&2"

        
	#check FROM view
  	sed -i "s/from_class_v/${C_INFO[0]}/g" cmdr2-1.txt

  	sed -i "s/to_class_m/${C_INFO[1]}/g" cmdr2-1.txt

     #Analyze first call
     smalisca analyzer -i $PNAME.sqlite -f sqlite -c cmdr2-1.txt | grep 'No results!' &> /dev/null
     if [ $? == 0 ]; then
       echo "Violation NOT found! for R2"
     else
       VISUALOUT=$((VISUALOUT+1))
       mv filtered.txt $"fResult__${VISUALOUT}".txt
       mv violation.png "${VISUALNAME}_${VISUALOUT}".png 
       feh "${VISUALNAME}_${VISUALOUT}".png &
       VIEW_TO_MODEL_1=true
     fi

     echo $'scl -fc from_class_v -tc to_class_m
     dcl -fc from_class_v -tc to_class_m -f png -o violation
     quit' > cmdr2-1.txt


  	sed -i "s/from_class_v/${C_INFO[0]}/g" cmdr2-1.txt

  	sed -i "s/to_class_m/${C_INFO[2]}/g" cmdr2-1.txt
        
     #Analyze second call
     smalisca analyzer -i $PNAME.sqlite -f sqlite -c cmdr2-1.txt | grep 'No results!' &> /dev/null
     if [ $? == 0 ]; then
       echo "Violation NOT found! for R2"
     else
       VISUALOUT=$((VISUALOUT+1))
       mv filtered.txt $"fResult__${VISUALOUT}".txt
       mv violation.png "${VISUALNAME}_${VISUALOUT}".png 
       feh "${VISUALNAME}_${VISUALOUT}".png &
       VIEW_TO_MODEL_2=true
     fi
 
     if [ $VIEW_TO_MODEL_1 ] && [ $VIEW_TO_MODEL_2 ]; then
     	echo "Violation FOUND for auto detection: view to model!"
     fi

	#chek  TO  view
  
  	sed -i "s/from_class_m/${C_INFO[1]}/g" cmdr2-2.txt

 	sed -i "s/to_class_v/${C_INFO[0]}/g" cmdr2-2.txt

    #Analyze first call (to VIEW)
     smalisca analyzer -i $PNAME.sqlite -f sqlite -c cmdr2-2.txt | grep 'No results!' &> /dev/null
     if [ $? == 0 ]; then
       echo "Violation NOT found! for R2"
     else
       VISUALOUT=$((VISUALOUT+1))
       mv filtered.txt $"fResult__${VISUALOUT}".txt
       mv violation.png "${VISUALNAME}_${VISUALOUT}".png 
       feh "${VISUALNAME}_${VISUALOUT}".png &
       MODEL_TO_VIEW_1=true
     fi


     echo $'scl -fc from_class_m -tc to_class_v
     dcl -fc from_class_m -tc to_class_v -f png -o violation
     quit' > cmdr2-2.txt
 

  	sed -i "s/from_class_m/${C_INFO[2]}/g" cmdr2-2.txt

  	sed -i "s/to_class_v/${C_INFO[0]}/g" cmdr2-2.txt

    #Analyze second call (to VIEW)
     smalisca analyzer -i $PNAME.sqlite -f sqlite -c cmdr2-2.txt | grep 'No results!' &> /dev/null
     if [ $? == 0 ]; then
       echo "Violation NOT found! for R2"
     else
       VISUALOUT=$((VISUALOUT+1))
       mv filtered.txt $"fResult__${VISUALOUT}".txt
       mv violation.png "${VISUALNAME}_${VISUALOUT}".png 
       feh "${VISUALNAME}_${VISUALOUT}".png &
       MODEL_TO_VIEW_2=true
     fi

     if [ $MODEL_TO_VIEW_1 ] && [ $MODEL_TO_VIEW_2 ]; then
     	echo "Violation FOUND for auto detection: model to view!"
     fi


    fi

    if [ "${C_INFO[1]}" = "${TRIMMED_VIEW%.java}" ] ; then
    	echo "C_INFO index 1 is view, process 0&2"
        
	#check FROM view
  	sed -i "s/from_class_v/${C_INFO[1]}/g" cmdr2-1.txt

  	sed -i "s/to_class_m/${C_INFO[0]}/g" cmdr2-1.txt

     #Analyze first call
     smalisca analyzer -i $PNAME.sqlite -f sqlite -c cmdr2-1.txt | grep 'No results!' &> /dev/null
     if [ $? == 0 ]; then
       echo "Violation NOT found! for R2"
     else
       VISUALOUT=$((VISUALOUT+1))
       mv filtered.txt $"fResult__${VISUALOUT}".txt
       mv violation.png "${VISUALNAME}_${VISUALOUT}".png 
       feh "${VISUALNAME}_${VISUALOUT}".png &
       VIEW_TO_MODEL_1=true
     fi

     echo $'scl -fc from_class_v -tc to_class_m
     dcl -fc from_class_v -tc to_class_m -f png -o violation
     quit' > cmdr2-1.txt


  	sed -i "s/from_class_v/${C_INFO[1]}/g" cmdr2-1.txt

  	sed -i "s/to_class_m/${C_INFO[2]}/g" cmdr2-1.txt
        
     #Analyze second call
     smalisca analyzer -i $PNAME.sqlite -f sqlite -c cmdr2-1.txt | grep 'No results!' &> /dev/null
     if [ $? == 0 ]; then
       echo "Violation NOT found! for R2"
     else
       VISUALOUT=$((VISUALOUT+1))
       mv filtered.txt $"fResult__${VISUALOUT}".txt
       mv violation.png "${VISUALNAME}_${VISUALOUT}".png 
       feh "${VISUALNAME}_${VISUALOUT}".png &
       VIEW_TO_MODEL_2=true
     fi
 
     if [ $VIEW_TO_MODEL_1 ] && [ $VIEW_TO_MODEL_2 ]; then
     	echo "Violation FOUND for auto detection: view to model!"
     fi

	#chek  TO  view
  
  	sed -i "s/from_class_m/${C_INFO[0]}/g" cmdr2-2.txt

 	sed -i "s/to_class_v/${C_INFO[1]}/g" cmdr2-2.txt

    #Analyze first call (to VIEW)
     smalisca analyzer -i $PNAME.sqlite -f sqlite -c cmdr2-2.txt | grep 'No results!' &> /dev/null
     if [ $? == 0 ]; then
       echo "Violation NOT found! for R2"
     else
       VISUALOUT=$((VISUALOUT+1))
       mv filtered.txt $"fResult__${VISUALOUT}".txt
       mv violation.png "${VISUALNAME}_${VISUALOUT}".png 
       feh "${VISUALNAME}_${VISUALOUT}".png &
       MODEL_TO_VIEW_1=true
     fi


     echo $'scl -fc from_class_m -tc to_class_v
     dcl -fc from_class_m -tc to_class_v -f png -o violation
     quit' > cmdr2-2.txt
 

  	sed -i "s/from_class_m/${C_INFO[2]}/g" cmdr2-2.txt

  	sed -i "s/to_class_v/${C_INFO[1]}/g" cmdr2-2.txt

    #Analyze second call (to VIEW)
     smalisca analyzer -i $PNAME.sqlite -f sqlite -c cmdr2-2.txt | grep 'No results!' &> /dev/null
     if [ $? == 0 ]; then
       echo "Violation NOT found! for R2"
     else
       VISUALOUT=$((VISUALOUT+1))
       mv filtered.txt $"fResult__${VISUALOUT}".txt
       mv violation.png "${VISUALNAME}_${VISUALOUT}".png 
       feh "${VISUALNAME}_${VISUALOUT}".png &
       MODEL_TO_VIEW_2=true
     fi

     if [ $MODEL_TO_VIEW_1 ] && [ $MODEL_TO_VIEW_2 ]; then
     	echo "Violation FOUND for auto detection: model to view!"
     fi

    fi





    if [ "${C_INFO[2]}" = "${TRIMMED_VIEW%.java}" ] ; then
    	echo "C_INFO index 2 is view, process 0&1"
        
	#check FROM view
  	sed -i "s/from_class_v/${C_INFO[2]}/g" cmdr2-1.txt

  	sed -i "s/to_class_m/${C_INFO[0]}/g" cmdr2-1.txt

     #Analyze first call
     smalisca analyzer -i $PNAME.sqlite -f sqlite -c cmdr2-1.txt | grep 'No results!' &> /dev/null
     if [ $? == 0 ]; then
       echo "Violation NOT found! for R2"
     else
       VISUALOUT=$((VISUALOUT+1))
       mv filtered.txt $"fResult__${VISUALOUT}".txt
       mv violation.png "${VISUALNAME}_${VISUALOUT}".png 
       feh "${VISUALNAME}_${VISUALOUT}".png &
       VIEW_TO_MODEL_1=true
     fi

     echo $'scl -fc from_class_v -tc to_class_m
     dcl -fc from_class_v -tc to_class_m -f png -o violation
     quit' > cmdr2-1.txt


  	sed -i "s/from_class_v/${C_INFO[2]}/g" cmdr2-1.txt

  	sed -i "s/to_class_m/${C_INFO[1]}/g" cmdr2-1.txt
        
     #Analyze second call
     smalisca analyzer -i $PNAME.sqlite -f sqlite -c cmdr2-1.txt | grep 'No results!' &> /dev/null
     if [ $? == 0 ]; then
       echo "Violation NOT found! for R2"
     else
       VISUALOUT=$((VISUALOUT+1))
       mv filtered.txt $"fResult__${VISUALOUT}".txt
       mv violation.png "${VISUALNAME}_${VISUALOUT}".png 
       feh "${VISUALNAME}_${VISUALOUT}".png &
       VIEW_TO_MODEL_2=true
     fi
 
     if [ $VIEW_TO_MODEL_1 ] && [ $VIEW_TO_MODEL_2 ]; then
     	echo "Violation FOUND for auto detection: view to model!"
     fi

	#chek  TO  view
  
  	sed -i "s/from_class_m/${C_INFO[0]}/g" cmdr2-2.txt

 	sed -i "s/to_class_v/${C_INFO[2]}/g" cmdr2-2.txt

    #Analyze first call (to VIEW)
     smalisca analyzer -i $PNAME.sqlite -f sqlite -c cmdr2-2.txt | grep 'No results!' &> /dev/null
     if [ $? == 0 ]; then
       echo "Violation NOT found! for R2"
     else
       VISUALOUT=$((VISUALOUT+1))
       mv filtered.txt $"fResult__${VISUALOUT}".txt
       mv violation.png "${VISUALNAME}_${VISUALOUT}".png 
       feh "${VISUALNAME}_${VISUALOUT}".png &
       MODEL_TO_VIEW_1=true
     fi


     echo $'scl -fc from_class_m -tc to_class_v
     dcl -fc from_class_m -tc to_class_v -f png -o violation
     quit' > cmdr2-2.txt
 

  	sed -i "s/from_class_m/${C_INFO[1]}/g" cmdr2-2.txt

  	sed -i "s/to_class_v/${C_INFO[2]}/g" cmdr2-2.txt

    #Analyze second call (to VIEW)
     smalisca analyzer -i $PNAME.sqlite -f sqlite -c cmdr2-2.txt | grep 'No results!' &> /dev/null
     if [ $? == 0 ]; then
       echo "Violation NOT found! for R2"
     else
       VISUALOUT=$((VISUALOUT+1))
       mv filtered.txt $"fResult__${VISUALOUT}".txt
       mv violation.png "${VISUALNAME}_${VISUALOUT}".png 
       feh "${VISUALNAME}_${VISUALOUT}".png &
       MODEL_TO_VIEW_2=true
     fi

     if [ $MODEL_TO_VIEW_1 ] && [ $MODEL_TO_VIEW_2 ]; then
     	echo "Violation FOUND for auto detection: model to view!"
     fi
    fi

fi

if [ "$HASCLASSINFO" = true ] ; then
    echo 'Check RULE#2'

     #R2 PART 1
     smalisca analyzer -i $PNAME.sqlite -f sqlite -c cmdr2-1.txt | grep 'No results!' &> /dev/null
     if [ $? == 0 ]; then
       echo "Violation NOT found! for R2"
     else
       echo "Violation found! for R2"
       smalisca analyzer -i $PNAME.sqlite -f sqlite -c cmdr2-1.txt > results.txt
       grep -r '| ' ./results.txt > filtered.txt
       grep -r '| [[:digit:]]' ./results.txt > filtered.txt
       VISUALOUT=$((VISUALOUT+1))
       mv filtered.txt $"fResult__${VISUALOUT}".txt
       mv violation.png "${VISUALNAME}_${VISUALOUT}".png 
       feh "${VISUALNAME}_${VISUALOUT}".png &

     #R2 PART 2
     smalisca analyzer -i $PNAME.sqlite -f sqlite -c cmdr2-2.txt | grep 'No results!' &> /dev/null
     if [ $? == 0 ]; then
       echo "Violation NOT found! for R2"
     else
       echo "Violation found! for R2"
       smalisca analyzer -i $PNAME.sqlite -f sqlite -c cmdr2-2.txt > results.txt
       grep -r '| ' ./results.txt > filtered.txt
       grep -r '| [[:digit:]]' ./results.txt > filtered.txt
       VISUALOUT=$((VISUALOUT+1))
       mv filtered.txt $"fResult__${VISUALOUT}".txt
       mv violation.png "${VISUALNAME}_${VISUALOUT}".png 
       feh "${VISUALNAME}_${VISUALOUT}".png &
fi 
fi
fi

else
   echo "standalone, enter apk location on filesystem"
   read standaloneLocation

   cd de-compilation
   apktool d $standaloneLocation

   cd app-debug

   SMALI_LOC="$(find "$(cd ..; pwd)" -name "smali")"

   UICOMP=$(xmlstarlet sel -t -v '//activity/@android:name' AndroidManifest.xml)

   stringarray=($UICOMP)
   echo "UI component size = ${#stringarray[@]}"

   echo "list of UI components"
   for each in "${stringarray[@]}"
   do
     echo "$each"
   done

   cd ../../

   #PARSE STARTS -- veyselo	
   smalisca parser -l $SMALI_LOC -s smali -f sqlite -o prebuilt.sqlite

   for each in "${stringarray[@]}"
   do

     > cmd.txt
     echo $'scl -fc from_class -tc Handler
     dcl -fc from_class -tc Handler -f png -o violation
     quit' > cmd.txt

     TRIMMED="$(echo $each | rev | cut -d. -f1 | rev)"
     echo $TRIMMED
     sed -i "s/from_class/$TRIMMED/g" cmd.txt

     smalisca analyzer -i prebuilt.sqlite -f sqlite -c cmd.txt | grep 'No results!' &> /dev/null
     if [ $? == 0 ]; then
       echo "Violation NOT found! for R1"
     else
       echo "Violation found! for R1"
       smalisca analyzer -i prebuilt.sqlite -f sqlite -c cmd.txt > results.txt
       grep -r '| ' ./results.txt > filtered.txt
       #grep -r '| [[:digit:]]' ./results.txt >> filtered.txt
       #rm -rf results.txt
       #sed -i '/init/d' ./filtered.txt
       #tail -n +2 filtered.txt
       VISUALOUT=$((VISUALOUT+1))
       mv filtered.txt $"fResult__${VISUALOUT}".txt
       mv violation.png "${VISUALNAME}_${VISUALOUT}".png 
       feh "${VISUALNAME}_${VISUALOUT}".png &
fi
   done

   #PREPARE CMDs AND PROCESS INDUVIDUALLY
   #RULE NO:1
fi

#RECOVER COMMAND FILES
> cmd.txt
> cmdr2.txt

echo $'scl -fc from_class -tc Handler
dcl -fc from_class -tc Handler -f png -o violation
quit' > cmd.txt

echo $'scl -fc from_class_v -tc to_class_m
dcl -fc from_class_v -tc to_class_m -f png -o violation
quit' > cmdr2-1.txt

echo $'scl -fc from_class_m -tc to_class_v
dcl -fc from_class_m -tc to_class_v -f png -o violation
quit' > cmdr2-2.txt

VISUALOUT=0


mkdir ./report
cp -rfv violation* ./report/
cp -rfv fResult* ./report/

rm -rf ./de-compilation/*

#rm -rf prebuilt.sqlite
#rm -rf $PNAME.sqlite

rm -rfv violation*
rm -rfv fResult*

#> cmd.txt
#> cmdr2.txt

