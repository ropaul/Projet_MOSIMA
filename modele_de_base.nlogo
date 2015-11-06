;__includes[""] ;Discomment it and press the "Check" button to get the "include" dropbar

; necessaire pour utiliser des tableaux
extensions [array table]

; nos trois type d'agent : les PERSONS , les COMPANIES et les MATCHINGS (un seul matching pour l'instant)
breed[persons person]
breed[companies company]
breed[matchings matching]



; attribut des persons (la position est récuperable par des fonction de netlogo)
persons-own[
  haveJob
  skills
  salary
  employer
  
  time_unemployed ;; to count the frictional_unemployement
]


; atribut des compagnies (la position est récuperable par des fonction de netlogo)
companies-own[
  haveEmployee
  skills
  salary
  employee
]

; les différents variables du problème
globals[
  ; Statistic variables :
  labor_force ; definie dans l'artcle
  unemployment_level ;; definie dans l'artcle
  unemployement_rate ; definie dans l'artcle
  vacant_jobs ; definie dans l'artcle
  vacancy_rate ; definie dans l'artcle
  participation_rate  ; definie dans l'artcle
  frictional_unemployement_time ; definie dans l'artcle
  frictional_unemployement_rate ; definie dans l'artcle
  people_matched_this_turn ; nombre de matching par tour
  structural_unemployement ; ; definie dans l'artcle
  natural_unemployement ; definie dans l'artcle
  count_unemployed_total ; definie dans l'artcle
  unemployement_rate_list ; liste des valeurs de unemployement_rate
  vacancy_rate_list  ; liste des valeurs de vacancy_rate
 
 time_window ; WHAT THE FUCK IS THAT ?
 ; Multiple simulations variables
  maxNumberPerson  
  minNumberPerson 
  stepNumberPerson
  rangeNumberPerson
  maxNumberCompanies
  minNumberCompanies
  stepNumberCompanies
  rangeNumberCompanies
  n_ticks_max
  epsilon ; seuil
  VacancyRateList_simulations
  UnemployedRateList_simulations
  
 ;salaryMean ;; SLIDER
 salaryMax
 ;salaryMaxFluctu ;; SLIDER
 ;n_skills ;; SLIDER
 ;n_match ;; SLIDER
 ;matching_quality_threshold ;; SLIDER
 ;exceptional_matching ;; SLIDER
 ;unexpected_company_motivation ;; SLIDER
 ;unexpected_worker_motivation ;; SLIDER
 ;unexpected_firing ;; SLIDER
 ;firing_quality_threshold ;; SLIDER
 ;max_productivity_fluctuation ;; SLIDER
 distMax
 matchingAgentWhoNumber
 
 ;Person_Number
 ;Compagny_Number
 ;Rseed ;; INPUT
]

matchings-own [
   seekC   ; ça sert ?
   seekP  ; même question
]

;; =================================================================
;; SETUP PROCEDURES
;; =================================================================
   
to setup
  clear-all  ; efface tout dans l'interface
  
  random-seed Rseed  ; seed pour rendre tout reproductible 
  setup_globals ; 
  setup_persons
  setup_companies
  setup_matching
  reset-ticks ; mettre les ticks à zero
end 

; initialise les agents PERSONS
to setup_persons  
  set-default-shape persons "person" ; donne une superbe aparence de personne à nos PERSONS
  create-persons Person_Number  ;; création des agents PERSON
  [ set color white ; ils sont blanc
    set size 1.5  ; ils sont grand
    setxy random-xcor random-ycor ; ils sont partout
    set haveJob False  ; il commencent sans travail
    set employer nobody  ; personne ne les emploie
    setup_skills ; ils sont des skill (initialisé)
    setup_salary  ; ils veulent un salaire
    set time_unemployed 0 ; temps  pas employé
  ]
end

; Initialise les agents COMPANIES
to setup_companies  
  set-default-shape  companies "house" ; donne une aparence de maison
  create-companies Compagny_Number 
  [ set color grey ; gris
    set size 1.5 ; grand pareil
    setxy random-xcor random-ycor ; disperse les entreprises
    set haveEmployee False ; pas d'employer pour le moment
    set employee nobody ; personne n'est leurs employé
    setup_skills ; ont besoins de certainens compétences
    setup_salary  ; offre un certains salaire
  ]
end

; initialise les agents MATCHINGS
to setup_matching
  set-default-shape  matchings "target"
  create-matchings 1
  [ set color orange
    set size 2.
    setxy 0 0
    set seekP []
    set seekC []
    set matchingAgentWhoNumber who
    ]
end




;; =================================================================
;; GO PROCEDURES
;; =================================================================


; fonction go, tout se fait ici (normalement)
to go
  ask persons[
    go_person 
  ]
  ask companies[
    go_company
  ]  
  ask matchings [
    go_matching
  ]
  
  go_links
  go_color
  go_globals
  
  tick
end

; action de chaques personnes 
to go_person
  if not haveJob [  ; si n'as pas de job faire 
   ask matching matchingAgentWhoNumber [
     if not member? ([who] of myself) seekP [ ; si le matchings ne te connait pas faire
       set seekP lput ([who] of myself) seekP  ; être ajouter au matchings
     ]  
   ]
     set time_unemployed time_unemployed + 1; ADD 1 to the time of unemployement
  ]
end

; action pour chaque compagnies
to go_company
  ifelse not haveEmployee [ ; si n'a pas d'employé faire 
    ask matching matchingAgentWhoNumber [ ; si le matchings ne te connait pas faire
     if not member? ([who] of myself) seekC [
       set seekC lput ([who] of myself) seekC ; etre ajouter au matching
     ]
    ]
  ]
  [ ; sinon (le ifelse , ici c'est le else)
    let bad_productivity ((productivity skills ([skills] of employee)) < firing_quality_threshold) ; si l'employé n'est pas productif , le remercier
    let bad_luck (random-float 1 < unexpected_firing) ; si l'employé n'est pas chanceux , le remercier
    if (bad_productivity or bad_luck) [
      fire_employee(employee)
    ]
  ]
end

; action du matching
to go_matching
  set people_matched_this_turn 0
  set structural_unemployement 0
  set frictional_unemployement_rate 0
  set frictional_unemployement_time 0
  let n_treated (min (List (length seekP) (length seekC) n_match)) ; n_treated = la taille minimum entre seekP et seekC
  let unemployed_treated n-of n_treated (shuffle seekP)  ; shuffle : modifie aléatoirement la place des différents éléments dans le tableau seekP et prend n_treated du tableau seekP
  let recruitors_treated n-of n_treated (shuffle seekC) ; pareil avec seekC (pour plus de clareté , peut être le faire en 2 lignes)
  foreach (n-values n_treated [?])[  ; pour 1 a n_treated
    let a_person_number (item ? unemployed_treated) ;prende un numero d'agent PERSON sans emploie 
    let a_company_number (item ? recruitors_treated) ; pareil avec COMPANIES
    let a_person (person a_person_number) ;prende un agent PERSON sans emploie
    let a_company (company a_company_number) ; pareil 
    let simi_person (similarity_person_to_company a_person a_company) ; fonction pour calculer la similarité entre personne/compagnie pour personne
    let simi_company (similarity_company_to_person a_company a_person) ; fonction pour calculer la similarité entre compagnie/personne pour compagnie
    let close_enough ((abs (simi_person - simi_company)) <= exceptional_matching) ; regarde si les similarité sont proches
    let good_enough ( (simi_person + simi_company) / 2 >= matching_quality_threshold ) ; regarde si la moyenne des similarité sont assez haute pour etre satisfaisante
    ifelse (close_enough and good_enough) [ ; si les conditions sont bonnes , alors il y a matching
      ask a_company [hire_employee a_person] 
      set seekP (remove-item (position a_person_number seekP) seekP)
      set seekC (remove-item (position a_company_number seekC) seekC)
    ]
    [ ; sinon , il n'y a pas embouche et on augmente le structural_unemployement
      set structural_unemployement structural_unemployement + 1  ; UPDATE OF STRCUTURAL UNEMPLOYEMENT HERE  
    ]
  ]
end

; met a jour les liens , si on veut les voir au pas
to go_links
  if linksVisible [
    ask links [ set color white]
  ]
  if linksVIsible = false [
    ask links [ set color black]
  ]
end

; met a jour les couleurs, si on veut les voir ou pas (si couleur activé en cours de route, les couleurs ne se mettent pas automatiquement)
to go_color
  if colorVisible = false [
    ask companies [set color grey]
    ask persons [set color white]
  ]
end

; update des différentes variable de la simulation
to go_globals
  let working_force count persons with [haveJob]  ; compte le nombre de personne avec emploie
  set unemployment_level count persons with [not haveJob]  ;  compte le combre de personne sans emploie  
  set labor_force (working_force + unemployment_level) ; les nombre de personne avec un emploie et ceux sans emploie mais qui cherche un emploie
  if labor_force != 0[
    set unemployement_rate ( unemployment_level /   labor_force) ; calcul le unemployement_rate
    ]
  set vacant_jobs count companies with [not haveEmployee]
  if labor_force != 0 [
    set vacancy_rate (vacant_jobs / labor_force) ; calcul le vacancy_rate
    ] 
  if Person_Number != 0 [
    set participation_rate ( labor_force / Person_Number) ; calcul le particpation_rate
    ]
  set natural_unemployement ( frictional_unemployement_rate  + structural_unemployement) ; calcul le natural_unemplyement
  
  ifelse ticks < time_window [ ; un tableau avec les différente valeur de unemplyment_rate et vacancy_rate ?
    set unemployement_rate_list lput unemployement_rate unemployement_rate_list
    set vacancy_rate_list lput vacancy_rate vacancy_rate_list
  ]
  [ ; cette liste se vide peut a peut
   ; set unemployement_rate_list lput unemployement_rate but-first unemployement_rate_list
   ; set vacancy_rate_list lput vacancy_rate but-first  vacancy_rate_list
  ]
end
     

;; =================================================================
;; DYNAMICS PROCEDURES
;; =================================================================

; calcul la productivté d'un employé
to-report productivity [skills1 skills2]
  let basic_productivity (skillSimilarity skills1 skills2) ; calcul sa productivité de base
  let luck ((random-float (2 * max_productivity_fluctuation)) - max_productivity_fluctuation) ; variation selon la chance de l'employé
  report (basic_productivity + luck)
end

; comment virer son employé
to fire_employee [the_employee]
  set haveEmployee False 
  set employee nobody 
  set color grey   ; HERE CHANGE OF COLOR
  ask the_employee [ 
    set haveJob False
    set employer nobody
    set color white     ; HERE CHANGE OF COLOR
    ask my-links [die]  ; HERE TO DESTROY A LINK BETWEEN COMPAGY AND PERSON
    ]
end

; comment engager un emploié
to hire_employee [the_person]  
  set people_matched_this_turn (people_matched_this_turn + 1)
  set haveEmployee True
  set employee the_person
  if colorVisible [set color green]   ; HERE CHANGE OF COLOR
  ask the_person [    
    set haveJob True
    update_frictional_unemployment time_unemployed ; met à jour le frictional_unemployement 
    set time_unemployed 0 ; TO CALCUL THE FRICTIONAL UNEMPLOYEMENT
    if colorVisible [set color blue ] ; HERE CHANGE OF COLOR
    set employer myself
    create-link-with myself ; HERE TO CREATE A LINK BETWEEN COMPAGY AND PERSON
    ]  
end


;; =================================================================
;; SIMILARITY PROCEDURES
;; =================================================================


; calcul la similarité entre les skills
to-report skillSimilarity [skills1 skills2]
  let accu 0
  foreach (n-values n_skills [?]) [
   let skill_of_1 (array:item skills1 ?) 
   let skill_of_2 (array:item skills2 ?)
   if (skill_of_1 = skill_of_2) [
    set accu (accu + 1)  ; regarde si les skill demandé sont les même , si oui , +1
   ]
  ]  
  report (accu / n_skills)
end 

; calcul la similarité de distance (distance euclidienne)
to-report localisationSimilarity [x1 y1 x2 y2]
  let dist sqrt ((x1 - x2) ^ 2 + (y1 - y2) ^ 2)
  report 1. - dist / distMax
end

; calcul la similarité des salaire
to-report salarySimilarity [salary1 salary2]
  let diff (salary1 - salary2)
  let temp (1. + diff / salaryMax)
  report (temp / 2)
end

; calcul la similarité d'une personne pour une personne
to-report similarity_person_to_company[a_person a_company]
  let accu 0
  set accu (accu + skillSimilarity ([skills] of a_person) ([skills] of a_company))
  set accu (accu + localisationSimilarity ([xcor] of a_person) ([ycor] of a_person) ([xcor] of a_company) ([ycor] of a_company))
  set accu (accu + salarySimilarity ([salary] of a_person) ([salary] of a_company))
  let motivation (random-float unexpected_worker_motivation)
  report ( (accu + motivation) / (3 + unexpected_worker_motivation) )
end

; calcul la similarité pour une comagnie
to-report similarity_company_to_person[a_company a_person]
  let accu 0
  set accu (accu + skillSimilarity ([skills] of a_person) ([skills] of a_company))
  set accu (accu + localisationSimilarity ([xcor] of a_person) ([ycor] of a_person) ([xcor] of a_company) ([ycor] of a_company))
  set accu (accu + salarySimilarity ([salary] of a_company) ([salary] of a_person))
  let motivation (random-float unexpected_company_motivation)
  report ( (accu + motivation) / (3 + unexpected_company_motivation) )
end


;; =================================================================
;; MISCELLAENOUS VARIABLES SETTINGS
;; =================================================================


; initialise les variable global de la simulation
to setup_globals 
  ;; let's get sliders' values
 ;set time_window time_window_;; SLIDER
 ;set salaryMean salaryMean_;; SLIDER  
 ;set salaryMaxFluctu salaryMaxFluctu_ ;; SLIDER
; set n_skills n_skills_;; SLIDER
; set n_match n_match_ ;; SLIDER
; set matching_quality_threshold matching_quality_threshold_ ;; SLIDER
; set exceptional_matching exceptional_matching_ ;; SLIDER
; set unexpected_company_motivation unexpected_company_motivation_ ;; SLIDER
; set unexpected_worker_motivation unexpected_worker_motivation_ ;; SLIDER
; set unexpected_firing  unexpected_firing_ ;; SLIDER
; set firing_quality_threshold firing_quality_threshold_ ;; SLIDER
; set max_productivity_fluctuation max_productivity_fluctuation_ ;; SLIDER 
; set Person_Number Person_Number_;; SLIDER
; set Compagny_Number Compagny_Number_;; SLIDER
 
 
  set salaryMax ( salaryMean + salaryMaxFluctu)
  set distMax (world-width * world-width +  world-height *  world-height )
  
  set labor_force (count persons with [not haveJob] + count persons with [haveJob])
  set unemployment_level count persons with [not haveJob] 
   if Person_Number != 0[set unemployement_rate (unemployment_level /   Person_Number)]
  set vacant_jobs count companies with[not haveEmployee]
  if labor_force != 0[set vacancy_rate (vacant_jobs / labor_force)] 
  if Person_Number != 0[set participation_rate ( labor_force / Person_Number)]
  set frictional_unemployement_time 0
  set frictional_unemployement_rate 0
  set structural_unemployement 0
  set natural_unemployement 0
  set count_unemployed_total 0
  set people_matched_this_turn 0
 
  set unemployement_rate_list []
  set vacancy_rate_list []
end


; initialise les skills (utilisable par les agents PERSONS et COMPANIES)
to setup_skills
  set skills array:from-list n-values n_skills [0]
  foreach (n-values n_skills [?]) [
    array:set skills ? (random 2) 
  ]
end

; initalise les salaire (utilisable par les agents PERSONS et COMPANIES)
to setup_salary
  let random_variation (random salaryMaxFluctu)
  set salary (salaryMean + random_variation)
end


;; =================================================================
;; STATISTICS FUNCTIONS
;; =================================================================

;met a jour le frictional_unemployment
to update_frictional_unemployment [time]
  set frictional_unemployement_time (frictional_unemployement_time + time)
  if people_matched_this_turn != 0 [
    set frictional_unemployement_rate (frictional_unemployement_time / people_matched_this_turn)
  ]
end





;; =================================================================
;; FUNCTIONS TO HAVE THE BEVERIDGE PLOT
;; =================================================================

to SIMULATE
  let tab_vprime array:from-list n-values n_simulation [0]
  let tab_uprime array:from-list n-values n_simulation [0]
  set epsilon 0.5
  set Person_Number 0
  Set Compagny_Number 100
  foreach (n-values n_simulation [?]) [
    set Person_Number (Person_Number + delta)
    set Compagny_Number (Compagny_Number - delta)
    setup
    let oldmeanV  1000
    let newmeanV 0
    let oldmeanU  1000
    let newmeanU 0
    while [ ticks > 10 or abs( (oldmeanV / (ticks + 1)) - (newmeanV / (ticks + 1))) > epsilon or abs( oldmeanU / (ticks + 1) - newmeanU / (ticks + 1) ) > epsilon]   
    [
     go
     set oldmeanV newmeanV
     set oldmeanU newmeanU
     if (ticks = 1)
     [
      set newmeanV vacancy_rate
      set newmeanU unemployement_rate
     ]
     if (ticks > 1)
     [
       set newmeanV (newmeanV + vacancy_rate) 
       set newmeanU (newmeanU + unemployement_rate)
       ]
    ]  
    array:set tab_vprime ?  (vacancy_rate  * 100) 
    array:set tab_uprime ?  (unemployement_rate * 100)
  ]
  ;set tab_v tab_vprime
  ;set tab_u tab_uprime
  update-plots
  
end




@#$#@#$#@
GRAPHICS-WINDOW
238
10
677
470
16
16
13.0
1
10
1
1
1
0
1
1
1
-16
16
-16
16
1
1
1
ticks
30.0

SLIDER
23
32
195
65
Person_Number
Person_Number
0
500
10
1
1
NIL
HORIZONTAL

SLIDER
23
78
195
111
Compagny_Number
Compagny_Number
0
500
90
1
1
NIL
HORIZONTAL

BUTTON
24
125
87
158
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
102
125
165
158
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

PLOT
300
499
676
673
Stat1
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Unemployed" 1.0 0 -13345367 true "" "plot count persons with [not haveJob]"
"Vacant job" 1.0 0 -2674135 true "" "plot count companies with [not haveEmployee]"
"seekC" 1.0 0 -7500403 true "" "plot 0;;length [seekC] of matching matchingAgentWhoNumber"
"seekP" 1.0 0 -955883 true "" "plot 0;;length [seekP] of matching matchingAgentWhoNumber"

SLIDER
11
268
183
301
salaryMean
salaryMean
0
100
50
1
1
NIL
HORIZONTAL

SLIDER
10
301
182
334
salaryMaxFluctu
salaryMaxFluctu
0
100
17
1
1
NIL
HORIZONTAL

SLIDER
10
226
182
259
n_skills
n_skills
1
10
5
1
1
NIL
HORIZONTAL

SLIDER
9
480
181
513
n_match
n_match
0
100
7
1
1
NIL
HORIZONTAL

SLIDER
8
521
262
554
matching_quality_threshold
matching_quality_threshold
0
1
0.4
0.1
1
NIL
HORIZONTAL

SLIDER
8
553
262
586
exceptional_matching
exceptional_matching
0
1
0.5
0.1
1
NIL
HORIZONTAL

SLIDER
9
638
258
671
unexpected_company_motivation
unexpected_company_motivation
0
1
0.1
0.1
1
NIL
HORIZONTAL

SLIDER
10
604
258
637
unexpected_worker_motivation
unexpected_worker_motivation
0
1
0.1
0.1
1
NIL
HORIZONTAL

SLIDER
11
417
234
450
unexpected_firing
unexpected_firing
0
0.1
0.0010
0.001
1
NIL
HORIZONTAL

SLIDER
11
351
234
384
firing_quality_threshold
firing_quality_threshold
0
1
0.1
0.1
1
NIL
HORIZONTAL

SLIDER
11
384
234
417
max_productivity_fluctuation
max_productivity_fluctuation
0
1
0
0.1
1
NIL
HORIZONTAL

INPUTBOX
689
69
753
129
Rseed
1
1
0
Number

SWITCH
685
147
797
180
linksVisible
linksVisible
0
1
-1000

SWITCH
685
180
798
213
colorVisible
colorVisible
0
1
-1000

MONITOR
721
424
810
469
vacancy_rate
vacancy_rate
17
1
11

MONITOR
817
424
948
469
unemployement_rate
unemployement_rate
17
1
11

PLOT
695
500
1074
740
unemployement
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"natural_unemployement" 1.0 0 -16777216 true "" "plot natural_unemployement"
"structural_unemployement" 1.0 0 -11033397 true "" "plot structural_unemployement / (ticks + 1 )"
"frictional_unemployement" 1.0 0 -2064490 true "" "if ( count_unemployee_total > 0) [plot (frictional_unemployement / count_unemployee_total)]"

SLIDER
677
281
849
314
n_simulation
n_simulation
0
100
10
1
1
NIL
HORIZONTAL

SLIDER
676
318
848
351
delta
delta
1
20
5
1
1
NIL
HORIZONTAL

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270

@#$#@#$#@
NetLogo 5.2.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180

@#$#@#$#@
0
@#$#@#$#@
