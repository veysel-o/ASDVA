# ASDVA
Android MVVM architecture analyzer

To be able to use ADSVA, please install and run smalisca tool:

https://github.com/dorneanu/smalisca 

Also apktool is required: 

https://ibotpeaches.github.io/Apktool/

DESCRIPTION: 
ADSVA analyzes GIT repositories based on pre-defined MVVM rules: There are currently two rules supported:

Rule-1: No business logic in UI ( Detection of Threads & Handlers that are targeted to do network, database or some other logic behind)
Rule-2: There must be no function calls between View & Model classes.

ADSVA chekcouts the GIT repository, compiles the project, and then disassamble the .apk file into dex files and creates related smali files.

Generated smalis files are injected to smalisca tool to cross-check pre-defined rule-1 and rule-2.

At first, ADSVA asks if there is a repository to analyze or not. If yes, it gets the repo address and analyzes repo for pre-defined rules.
If there is no repository but only compiled application (.apk), ADSVA is able to analyze directly .apk files for rule-1.

HOW IT WORKS:

Open your terminal and go to the directory which is ADSVA is located.

Type "bash adsva.sh"
