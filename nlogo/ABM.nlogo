globals
[
  ;; hour counter
  home-when
  work-when
  commute-when
  alarm-reset-when

  ;; contact rate (transportation)
  contact_rate_bus
  contact_rate_car
  contact_rate_walk
  contact_rate_tube
  contact_rate_train

  ;; contact rate (company)
  contact_rate_big_workplace
  contact_rate_mid_workplace
  contact_rate_small_workplace

  ;; infection rate (mask & cardiovascular disease)
  infection_rate_ymask_ycardio
  infection_rate_nmask_ncardio
  infection_rate_ymask_ncardio
  infection_rate_nmask_ycardio

  ;; output parameters
  cumulative_sick
  cumulative_susceptible
  cumulative_immune
  cumulative_vaccinated

  ;; lists of transportation and company
  modes_of_transportation
  company_list
  big_sized_companies
  mid_sized_companies
  small_sized_companies
  cardiovascular_disease_list
  mask_list

  ;; phase and days counter
  phase
  days
  days-track
  hour-counter
  cumulative-hour-counter
]

turtles-own
[
  sick? ;;if true, the turtle is infectious
  immune? ;;if true, the turtle is immune
  susceptible? ;;if true, the turtle can be infected
  vaccinated? ;;if true, the turtle is permanently immune
  mask? ;;is an agent wearing a mask?
  cardiovascular-disease? ;;is an agent suffering from cardiovascular disease?
  sick-count ;;how long the turtle has been infected
  natural-immune-count ;;how long the turtle has been naturally immune
  vaccine-immune-count
  transportation ;;what type of transportation (tube, car, train, walk, bus)
  company ;;what company is the agent working
]

patches-own
[
  sick-population ;;number of turtles on a patch that are sick
  total-population ;;total number of turtles on a patch
]

;;--------------------------------------------------------------------------------------------

to setup
  ca
  reset-ticks
  setup-globals
  set-commute-area
  setup-turtles
  set-transportation
  set-company
  set-mask
  set-cardiovascular-disease
  set-cumulative-counts
  ask patches [calculate-sick-population]
  ask patches [calculate-total-population]
end

to setup-turtles
  ;;ask n-of initial-population patches with [pcolor = black]
  ;;[sprout 2 [get-susceptible]] ;;set up turtles and make them all susceptible.
  crt initial-population [get-susceptible]
  ask turtles [
  setxy random-xcor random-ycor
  ]
end

to setup-globals
  set hour-counter 0
  set cumulative-hour-counter 0

  set home-when 2
  set commute-when 14
  set work-when 16
  set alarm-reset-when 24

  set contact_rate_bus 40
  set contact_rate_tube 35
  set contact_rate_train 30
  set contact_rate_walk 10
  set contact_rate_car 0

  set contact_rate_big_workplace 40
  set contact_rate_mid_workplace 35
  set contact_rate_small_workplace 30

  set infection_rate_nmask_ycardio 50
  set infection_rate_nmask_ncardio 45
  set infection_rate_ymask_ycardio 15
  set infection_rate_ymask_ncardio 10

  set mask_list [true false]
  set cardiovascular_disease_list [true false]
  set modes_of_transportation ["car" "tube" "train" "walk" "bus"]
  set company_list ["tesla" "apple" "google" "amazon" "facebook" "samsung" "toyota" "nhs" "yahoo" "dell" "sainsbury" "cocacola" "h&m" "zara" "gap"]
  set big_sized_companies ["apple" "google" "amazon" "facebook" "samsung" "toyota" "cocacola"]
  set mid_sized_companies ["yahoo" "dell" "zara" "tesla"]
  set small_sized_companies ["nhs" "sainsbury" "gap" "h&m"]

  set phase "commuting hour"
end

to set-transportation
  ask turtles [set transportation one-of modes_of_transportation]
end

to set-company
  if any? turtles with [company = 0]
  [
    ask n-of (count turtles * 0.5) turtles with [company = 0][set company one-of big_sized_companies]
    ask n-of (count turtles * 0.3) turtles with [company = 0][set company one-of mid_sized_companies]
    ask n-of (count turtles * 0.2) turtles with [company = 0][set company one-of small_sized_companies]
  ]
end

to set-mask
  ask turtles [set mask? one-of mask_list]
end

to set-cardiovascular-disease
  ask turtles [set cardiovascular-disease? one-of cardiovascular_disease_list]
end

to set-cumulative-counts
  set cumulative_sick 0
  set cumulative_susceptible initial-population
  set cumulative_immune 0
  set cumulative_vaccinated 0
  set days 0
  set days-track -1
end


;;--------------------------------------------------------------------------------------------

to go
  tick ;;one time-step passes
  set hour-counter hour-counter + 1
  set cumulative-hour-counter cumulative-hour-counter + 1
  count-sick-immune-time
  calculate-days
  become-immune ;;become immune if the sick-count exceeded the infectious-period
  become-susceptible ;;become susceptible if the natural-immune-count exceeded the immunity-period
  (ifelse 0 < hour-counter and hour-counter < home-when
  [
      set phase "commuting hour"
      set-commute-area
  ] hour-counter > home-when and hour-counter < commute-when
  [
      set phase "home hour"
      remove-commute-label
      set-home-area
  ] hour-counter > commute-when and hour-counter < work-when
  [
      set phase "commuting hour"
      remove-home-label
      set-commute-area
  ] hour-counter > work-when and hour-counter < alarm-reset-when
  [
      set phase "working hour"
      remove-commute-label
      set-workplace-area
  ] hour-counter > alarm-reset-when
  [
      setup-globals
      remove-workplace-label
      set-commute-area
  ][])

  ask patches [calculate-sick-population]
  ask patches [calculate-total-population]

  carefully[
    if (phase = "commuting hour") and not (days-track = days)
    [
      ask n-of (vaccination-rate * report-current-susceptible) turtles with [susceptible?][get-vaccinated]
      set days-track days
    ]
  ][]

  if ticks < 720
  [
    ask one-of patches
    [
      sprout 1
      [
        get-infected
        set transportation one-of modes_of_transportation
        set company one-of company_list
        set mask? one-of mask_list
        set cardiovascular-disease? one-of cardiovascular_disease_list
      ]
    ]
  ]

  if ticks mod 24 = 0
  [
    let current-pop report-current-population
    ask n-of ((precision (random-float 0.01) 2) * current-pop) turtles
    [
      die
    ]
    create-turtles ((precision (random-float 0.01) 2) * current-pop)
    [
      let choice one-of [0 1 2 3]

      (ifelse choice = 0
      [
          get-infected
      ] choice = 1
      [
          get-immune
      ] choice = 2
      [
          get-susceptible
      ] choice = 3
      [
          get-vaccinated
      ])

      set transportation one-of modes_of_transportation
      set company one-of company_list
      set mask? one-of mask_list
      set cardiovascular-disease? one-of cardiovascular_disease_list
      move-to one-of patches
    ]
  ]

  ask patches with [pcolor = black][infect] ;;allows turtles to infect that are in contact
  ask patches with [pcolor = cyan][infect] ;;allows turtles to infect that are in contact
  ask turtles [move]

  if days >= 365 [stop]
end

;;--------------------------------------------------------------------------------------------

to set-home-area
  ask patches [set pcolor orange]
  ask patch 1 0 [set plabel "Home Area"]
end

to set-workplace-area
  ask patches [set pcolor cyan]
  ask patch 2 0 [set plabel "Workplace Area"]
end

to set-commute-area
  ask patches [set pcolor black]
  ask patch 2 0 [set plabel "Commute Area"]
end

to remove-home-label
  ask patch 1 0 [set plabel ""]
end

to remove-workplace-label
  ask patch 2 0 [set plabel ""]
end

to remove-commute-label
  ask patch 2 0 [set plabel ""]
end

;;--------------------------------------------------------------------------------------------


to infect
  carefully
  [
  (ifelse sick-population > 0 and (phase = "commuting hour")
  [
      if (any? turtles-here with [sick? and transportation = "tube"])
      [
        let sick-proportion count turtles-here with [transportation = "tube"] / count turtles-here with [sick? and transportation = "tube"]
        let potential-infection-rate (sick-proportion * contact_rate_tube) - (social-distancing-levels * 5)
        ask turtles-here with [susceptible? and transportation = "tube"][get-infected-main potential-infection-rate]
      ]
      if (any? turtles-here with [sick? and transportation = "walk"])
      [
        let sick-proportion count turtles-here with [transportation = "walk"] / count turtles-here with [sick? and transportation = "walk"]
        let potential-infection-rate (sick-proportion * contact_rate_walk) - (social-distancing-levels * 5)
        ask turtles-here with [susceptible? and transportation = "walk"][get-infected-main potential-infection-rate]
      ]
      if (any? turtles-here with [sick? and transportation = "train"])
      [
        let sick-proportion count turtles-here with [transportation = "train"] / count turtles-here with [sick? and transportation = "train"]
        let potential-infection-rate (sick-proportion * contact_rate_train) - (social-distancing-levels * 5)
        ask turtles-here with [susceptible? and transportation = "train"][get-infected-main potential-infection-rate]
      ]
      if (any? turtles-here with [sick? and transportation = "bus"])
      [
        let sick-proportion count turtles-here with [transportation = "bus"] / count turtles-here with [sick? and transportation = "bus"]
        let potential-infection-rate (sick-proportion * contact_rate_bus) - (social-distancing-levels * 5)
        ask turtles-here with [susceptible? and transportation = "bus"][get-infected-main potential-infection-rate]
      ]
   ] sick-population > 0 and (phase = "working hour")
   [
      if (any? turtles-here with [sick? and company = "apple"])
      [
        let sick-proportion count turtles-here with [company = "apple"] / count turtles-here with [sick? and company = "apple"]
        let potential-infection-rate (sick-proportion * contact_rate_big_workplace) - (social-distancing-levels * 5)
        ask turtles-here with [susceptible? and company = "apple"][get-infected-main potential-infection-rate]
      ]
      if (any? turtles-here with [sick? and company = "google"])
      [
        let sick-proportion count turtles-here with [company = "google"] / count turtles-here with [sick? and company = "google"]
        let potential-infection-rate (sick-proportion * contact_rate_big_workplace) - (social-distancing-levels * 5)
        ask turtles-here with [susceptible? and company = "google"][get-infected-main potential-infection-rate]
      ]
      if (any? turtles-here with [sick? and company = "amazon"])
      [
        let sick-proportion count turtles-here with [company = "amazon"] / count turtles-here with [sick? and company = "amazon"]
        let potential-infection-rate (sick-proportion * contact_rate_big_workplace) - (social-distancing-levels * 5)
        ask turtles-here with [susceptible? and company = "amazon"][get-infected-main potential-infection-rate]
      ]
      if (any? turtles-here with [sick? and company = "facebook"])
      [
        let sick-proportion count turtles-here with [company = "facebook"] / count turtles-here with [sick? and company = "facebook"]
        let potential-infection-rate (sick-proportion * contact_rate_big_workplace) - (social-distancing-levels * 5)
        ask turtles-here with [susceptible? and company = "facebook"][get-infected-main potential-infection-rate]
      ]
      if (any? turtles-here with [sick? and company = "cocacola"])
      [
        let sick-proportion count turtles-here with [company = "cocacola"] / count turtles-here with [sick? and company = "cocacola"]
        let potential-infection-rate (sick-proportion * contact_rate_big_workplace) - (social-distancing-levels * 5)
        ask turtles-here with [susceptible? and company = "cocacola"][get-infected-main potential-infection-rate]
      ]
      if (any? turtles-here with [sick? and company = "samsung"])
      [
        let sick-proportion count turtles-here with [company = "samsung"] / count turtles-here with [sick? and company = "samsung"]
        let potential-infection-rate (sick-proportion * contact_rate_big_workplace) - (social-distancing-levels * 5)
        ask turtles-here with [susceptible? and company = "samsung"][get-infected-main potential-infection-rate]
      ]
      if (any? turtles-here with [sick? and company = "toyota"])
      [
        let sick-proportion count turtles-here with [company = "toyota"] / count turtles-here with [sick? and company = "toyota"]
        let potential-infection-rate (sick-proportion * contact_rate_big_workplace) - (social-distancing-levels * 5)
        ask turtles-here with [susceptible? and company = "toyota"][get-infected-main potential-infection-rate]
      ]
      if (any? turtles-here with [sick? and company = "tesla"])
      [
        let sick-proportion count turtles-here with [company = "tesla"] / count turtles-here with [sick? and company = "tesla"]
        let potential-infection-rate (sick-proportion * contact_rate_mid_workplace) - (social-distancing-levels * 5)
        ask turtles-here with [susceptible? and company = "tesla"][get-infected-main potential-infection-rate]
      ]
      if (any? turtles-here with [sick? and company = "zara"])
      [
        let sick-proportion count turtles-here with [company = "zara"] / count turtles-here with [sick? and company = "zara"]
        let potential-infection-rate (sick-proportion * contact_rate_mid_workplace) - (social-distancing-levels * 5)
        ask turtles-here with [susceptible? and company = "zara"][get-infected-main potential-infection-rate]
      ]
      if (any? turtles-here with [sick? and company = "yahoo"])
      [
        let sick-proportion count turtles-here with [company = "yahoo"] / count turtles-here with [sick? and company = "yahoo"]
        let potential-infection-rate (sick-proportion * contact_rate_mid_workplace) - (social-distancing-levels * 5)
        ask turtles-here with [susceptible? and company = "yahoo"][get-infected-main potential-infection-rate]
      ]
      if (any? turtles-here with [sick? and company = "dell"])
      [
        let sick-proportion count turtles-here with [company = "dell"] / count turtles-here with [sick? and company = "dell"]
        let potential-infection-rate (sick-proportion * contact_rate_mid_workplace) - (social-distancing-levels * 5)
        ask turtles-here with [susceptible? and company = "dell"][get-infected-main potential-infection-rate]
      ]
      if (any? turtles-here with [sick? and company = "nhs"])
      [
        let sick-proportion count turtles-here with [company = "nhs"] / count turtles-here with [sick? and company = "nh"]
        let potential-infection-rate (sick-proportion * contact_rate_small_workplace) - (social-distancing-levels * 5)
        ask turtles-here with [susceptible? and company = "nhs"][get-infected-main potential-infection-rate]
      ]
      if (any? turtles-here with [sick? and company = "sainsbury"])
      [
        let sick-proportion count turtles-here with [company = "sainsbury"] / count turtles-here with [sick? and company = "sainsbury"]
        let potential-infection-rate (sick-proportion * contact_rate_small_workplace) - (social-distancing-levels * 5)
        ask turtles-here with [susceptible? and company = "sainsbury"][get-infected-main potential-infection-rate]
      ]
      if (any? turtles-here with [sick? and company = "h&m"])
      [
        let sick-proportion count turtles-here with [company = "h&m"] / count turtles-here with [sick? and company = "h&m"]
        let potential-infection-rate (sick-proportion * contact_rate_small_workplace) - (social-distancing-levels * 5)
        ask turtles-here with [susceptible? and company = "h&m"][get-infected-main potential-infection-rate]
      ]
      if (any? turtles-here with [sick? and company = "gap"])
      [
        let sick-proportion count turtles-here with [company = "gap"] / count turtles-here with [sick? and company = "gap"]
        let potential-infection-rate (sick-proportion * contact_rate_small_workplace) - (social-distancing-levels * 5)
        ask turtles-here with [susceptible? and company = "gap"][get-infected-main potential-infection-rate]
      ]
  ][])
  ][]
end

to get-infected-main [potential-infection-rate]
  if random-float 100 < potential-infection-rate
  [
    (ifelse mask? and cardiovascular-disease? and random 100 < infection_rate_ymask_ycardio
    [
      get-infected
    ] not mask? and cardiovascular-disease? and random 100 < infection_rate_nmask_ycardio
    [
      get-infected
    ] mask? and not cardiovascular-disease? and random 100 < infection_rate_ymask_ncardio
    [
      get-infected
    ] not mask? and not cardiovascular-disease? and random 100 < infection_rate_nmask_ncardio
    [
      get-infected
    ][])
  ]
end

to get-infected
  set sick? true
  set immune? false
  set susceptible? false
  set vaccinated? false
  set color red
  set sick-count 0
  set natural-immune-count 0
  set vaccine-immune-count 0
  set cumulative_sick cumulative_sick + 1
end

to get-immune
  set sick? false
  set immune? true
  set vaccinated? false
  set color green
  set sick-count 0
  set natural-immune-count 0
  set susceptible? false
  set cumulative_immune cumulative_immune + 1
end

to get-vaccinated
  set sick? false
  set immune? false
  set susceptible? false
  set vaccinated? true
  set color cyan
  set sick-count 0
  set vaccine-immune-count 0
  set cumulative_vaccinated cumulative_vaccinated + 1
end

to get-susceptible
  set sick? false
  set immune? false
  set vaccinated? false
  set color blue
  set sick-count 0
  set natural-immune-count 0
  set vaccine-immune-count 0
  set susceptible? true
  set cumulative_susceptible cumulative_susceptible + 1
end

;;--------------------------------------------------------------------------------------------

to count-sick-immune-time
  ask turtles
  [
    if sick? [set sick-count (sick-count + 1)] ;;increment the sick-count by 1.
    if immune? [set natural-immune-count (natural-immune-count + 1)] ;;increment the natural-immune-count by 1.
    if vaccinated? [set vaccine-immune-count (vaccine-immune-count + 1)] ;;increment the immune-count by 1.
  ]
end

to become-immune
  ask turtles with [sick?][if (sick-count) > (infectious-period * 168) [get-immune]] ;;if the sick-count exceeds the infectious-period, become immune
end

to become-susceptible
  ask turtles with [immune?][if (natural-immune-count) > (immunity-period * 720) [get-susceptible]] ;;if the immune-count exceeds the immunity-period, become susceptible
  ask turtles with [vaccinated?][if (vaccine-immune-count) > (immunity-period * 720) [get-susceptible]] ;;if the immune-count exceeds the immunity-period, become susceptible
end

;;--------------------------------------------------------------------------------------------

to move
  carefully[move-to one-of neighbors4][]
end

;;--------------------------------------------------------------------------------------------

to calculate-sick-population
  set sick-population (count (turtles-here with [sick?])) ;;counts number of sick agents on a patch
end

to calculate-total-population
  set total-population (count (turtles-here)) ;;counts total number of agents on a patch
end

to calculate-days
  if (cumulative-hour-counter mod 24) = 0
  [
    set days days + 1
  ]
end

;;--------------------------------------------------------------------------------------------

to-report report-current-population
  report count turtles
end

to-report report-current-sick
  report count turtles with [sick?]
end

to-report report-current-immune
  report count turtles with [immune?]
end

to-report report-current-susceptible
  report count turtles with [susceptible?]
end

to-report report-current-vaccinated
  report count turtles with [vaccinated?]
end

to-report report-current-days
  report days
end

to-report report-current-months
  report floor (precision (days / 30) 1)
end

;;--------------------------------------------------------------------------------------------

to-report report-cumulative-population
  report cumulative_sick + cumulative_immune + cumulative_susceptible + cumulative_vaccinated
end

to-report report-cumulative-sick
  report cumulative_sick
end

to-report report-cumulative-immune
  report cumulative_immune
end

to-report report-cumulative-susceptible
  report cumulative_susceptible
end

to-report report-cumulative-vaccinated
  report cumulative_vaccinated
end

to-report report-proportion-sick
  report precision (cumulative_sick / report-cumulative-population) 3
end

to-report report-proportion-immune
  report precision (cumulative_immune / report-cumulative-population) 3
end

to-report report-proportion-susceptible
  report precision (cumulative_susceptible / report-cumulative-population) 3
end

to-report report-proportion-vaccinated
  report precision (cumulative_vaccinated / report-cumulative-population) 3
end
@#$#@#$#@
GRAPHICS-WINDOW
368
8
901
542
-1
-1
12.82
1
10
1
1
1
0
0
0
1
-20
20
-20
20
0
0
1
ticks
60.0

SLIDER
154
9
361
42
initial-population
initial-population
1500
1500
1500.0
0
1
agents
HORIZONTAL

SLIDER
154
114
361
147
infectious-period
infectious-period
2
4
2.0
1
1
weeks
HORIZONTAL

SLIDER
154
79
361
112
immunity-period
immunity-period
9
11
9.0
1
1
months
HORIZONTAL

BUTTON
11
8
75
42
NIL
Go\n
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
81
9
145
43
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

PLOT
19
253
220
407
Endemic Cases
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -2674135 true "" "plot count turtles with [sick?]"
"pen-1" 1.0 0 -14439633 true "" "plot count turtles with [immune?]"
"pen-2" 1.0 0 -11221820 true "" "plot count turtles with [vaccinated?]"
"pen-3" 1.0 0 -13345367 true "" "plot count turtles with [susceptible?]"

MONITOR
224
253
362
302
Current Sick
report-current-sick
0
1
12

MONITOR
224
306
362
355
Current Immune
report-current-immune
0
1
12

MONITOR
224
358
362
407
Current Vaccinated
report-current-vaccinated
0
1
12

MONITOR
224
201
362
250
Current Susceptible
report-current-susceptible
0
1
12

MONITOR
224
409
313
458
Days Passed
report-current-days
0
1
12

MONITOR
1140
110
1295
159
Cumulative Sick
report-cumulative-sick
0
1
12

MONITOR
1140
60
1295
109
Cumulative Susceptible
report-cumulative-susceptible
0
1
12

MONITOR
1140
210
1295
259
Cumulative Vaccinated
report-cumulative-vaccinated
0
1
12

MONITOR
1140
160
1295
209
Cumulative Immune
report-cumulative-immune
0
1
12

PLOT
922
45
1122
195
Cumulative Endemic Cases
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -2674135 true "" "plot cumulative_sick"
"pen-1" 1.0 0 -13840069 true "" "plot cumulative_immune"
"pen-2" 1.0 0 -13345367 true "" "plot cumulative_susceptible"
"pen-3" 1.0 0 -11221820 true "" "plot cumulative_vaccinated"

MONITOR
908
274
966
323
tube
count turtles with [transportation = \"tube\"]
0
1
12

MONITOR
967
274
1025
323
bus
count turtles with [transportation = \"bus\"]
0
1
12

MONITOR
1027
274
1085
323
train
count turtles with [transportation = \"train\"]
0
1
12

MONITOR
1085
274
1143
323
walk
count turtles with [transportation = \"walk\"]
0
1
12

MONITOR
1143
274
1201
323
car
count turtles with [transportation = \"car\"]
0
1
12

MONITOR
908
447
966
496
Tesla
count turtles with [company = \"tesla\"]
0
1
12

MONITOR
971
361
1029
410
Apple
count turtles with [company = \"apple\"]
0
1
12

MONITOR
1030
361
1088
410
Google
count turtles with [company = \"google\"]
0
1
12

MONITOR
1092
361
1151
410
Amazon
count turtles with [company = \"amazon\"]
0
1
12

MONITOR
1152
361
1226
410
Facebook
count turtles with [company = \"facebook\"]
0
1
12

MONITOR
1230
361
1300
410
Samsung
count turtles with [company = \"samsung\"]
0
1
12

MONITOR
910
361
969
410
Toyota
count turtles with [company = \"toyota\"]
0
1
12

MONITOR
983
531
1041
580
NHS
count turtles with [company = \"nhs\"]
0
1
12

MONITOR
968
447
1026
496
Yahoo
count turtles with [company = \"yahoo\"]
0
1
12

MONITOR
1028
447
1086
496
Dell
count turtles with [company = \"dell\"]
0
1
12

MONITOR
908
531
981
580
Sainsbury
count turtles with [company = \"sainsbury\"]
0
1
12

MONITOR
1302
361
1376
410
Coca-Cola
count turtles with [company = \"cocacola\"]
0
1
12

MONITOR
1043
531
1101
580
H & M
count turtles with [company = \"h&m\"]
0
1
12

MONITOR
1090
447
1148
496
Zara
count turtles with [company = \"zara\"]
0
1
12

MONITOR
1103
531
1161
580
GAP
count turtles with [company = \"gap\"]
0
1
12

TEXTBOX
908
254
1087
286
Transportation Distribution
12
0.0
1

TEXTBOX
912
340
1076
372
High Popular Companies
12
0.0
1

TEXTBOX
912
426
1113
458
Mid Popular Companies
12
0.0
1

TEXTBOX
910
511
1110
543
Low Popular Companies
12
0.0
1

MONITOR
89
201
221
250
Current Population
count turtles
0
1
12

MONITOR
114
409
221
458
Months Passed
report-current-months
0
1
12

MONITOR
1298
110
1454
159
Proportion Sick
report-proportion-sick
3
1
12

MONITOR
1298
210
1454
259
Proportion Vaccinated
report-proportion-vaccinated
3
1
12

MONITOR
1298
60
1453
109
Proportion Susceptible
report-proportion-susceptible
3
1
12

MONITOR
1298
160
1454
209
Proportion Immune
report-proportion-immune
3
1
12

MONITOR
1140
8
1296
57
Cumulative Population
report-cumulative-population
0
1
12

SLIDER
154
44
361
77
vaccination-rate
vaccination-rate
0
0.005
0.005
0.0025
1
NIL
HORIZONTAL

SLIDER
154
150
362
183
social-distancing-levels
social-distancing-levels
1
3
2.0
1
1
level
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
NetLogo 6.2.2
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="experiment" repetitions="3" sequentialRunOrder="false" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <exitCondition>turtles with [sick?] = 0</exitCondition>
    <metric>count turtles with [sick?]</metric>
    <enumeratedValueSet variable="infection-rate">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="population">
      <value value="600"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="vaccinate-people?">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="immunity-period">
      <value value="60"/>
      <value value="70"/>
      <value value="80"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="infectious-period">
      <value value="14"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
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
