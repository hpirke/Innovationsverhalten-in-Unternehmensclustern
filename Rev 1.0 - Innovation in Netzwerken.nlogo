globals [
  total-R&D
  mean-link-success-rate
  max-skill
  min-skill
  skill-gain
  skill-loss
]

turtles-own [
 behaviour-type      ;; Hier ist das SOKI-Verhalten des Agents gespeichert in Werten von 1-4 für jeden der 4 Typen
 own-R&D             ;; Hier speichern wir Werte zwischen 0 und 1, die dann die Wahrscheinlichkeit einer eigenen Innovation pro Tick ausdrücken -> 0.2 = 20%
                     ;; Formel für unser Innovations-Orakel und dessen Wahrscheinlichkeit ist Wahrscheinlichkeit = Skill-Wert + own-R&D
 open-R&D            ;; Wie oben nur für Open Innovation, also Innovation mit vernetzten Agents
 networking          ;; Wieder ein Wert zwischen 0 und 1 der die Wahrscheinlichkeit ausdrückt sich mit anderen zu vernetzen -> SOKI Verhalten
 network-skill-range ;; Der Abstand den ein anderer Agent besser sein muss wenn man mit ihm einen Link eingehen möchte
 network-money-range ;; Der Mindestwert an Geld unterhalb dessen man nach neuen Partnern sucht
 money               ;; Vorhandene Menge Geld die je nach Art und Intensität der Innovation pro Tick weniger wird,
                     ;; aber von den vorhanden Innovationen und deren Einkünfte wieder zunimmt
 own-innovations     ;; Liste der verhandenen eignene Innovationen und die Phase in der Sie sind
 shared-innovations  ;; Liste der verhandenen Open Innovations und die Phase in der Sie sind
 skills              ;; Liste mit unseren Fähigkeiten, die zusammen mit own-R&D und open-R&D die Wahrscheilichkeit einer neuen Innovation bestimmen
                     ;; auch hier stehen Werte von 0 bis 1 aber in einer Liste mit mehreren Einträgen (aktuell 3)
 max-connections     ;; Maximale Anzahl an Links die ein Agent eingeht
 R&D-Cost            ;; R&D Kosten die ein Agent in einem Tick bezahlt hat, zur Berehcnung der Durchschnitts R&D Kosten pro Typ und gesamt im Cluster
]

links-own [
  link-success-rate    ;; Zählt wie oft ein Link eine Innovation hervor gebracht hat
  link-age             ;; Zählt wie oft ein link schon benutzt wurde, also pro tick 2 Mal (von jeder Seite)
]

to setup
  ca

  ;; Parameter für die Entwicklung der Skills
  set max-skill 0.35      ;; Obergrenze die ein Skill haben kann  -> Sollte nicht 1 sein, weil sonst jedes mal was erfunden wird und er nie mehr kleiner wird
  set min-skill 0.05      ;; Untergrenze die ein Skill haben kann -> Solle nicht 0 sein, weil sonst nie mehr was erfunden wird und er nie mehr gößer wird
  set skill-gain 0.15     ;; Skill-Zuwachs, wenn was erfunden wurde
  set skill-loss 0.01     ;; Skill-Verlust wenn eine Runde mal nichts erfunden wurde

  crt behaviour-type-1 [
    set behaviour-type 1
    set own-R&D 1.2                    ;; hoher Wert                                                                    -> starke Initiative
    set open-R&D 0.3                   ;; hoher Wert                                                                    -> starke Initiative
    set networking 0.25                ;; hoher Netzwerkfaktor                                                          -> starke Vernetzung
    set network-skill-range 0.1        ;; niedriger Wert, Partner muss also nicht sehr viel besser sein um zu vernetzen -> starke Vernetzung
    set network-money-range 1000000    ;; hoher Wert, Agent muss also nicht sehr arm sein um sich zu vernetzen          -> starke Vernetzung
    set max-connections max-links * 3  ;; hoch                                                                          -> starke vernetzung

    ;; Startwerte
    set money 100000
    set own-innovations [10 10 10 15 15 15]     ;; Ziel ca. 50% der Innovationen Open Innovations
    set shared-innovations [10 10 10 15 15 15]  ;; Zum Start gleich viele interne wie externe
    set skills n-values 3 [max-skill / 2]  ;; Alle starten bei 50% des Max Skills


    setxy random-xcor random-ycor
    set color orange
    set shape "house"
    set R&D-Cost 0
 ]


  crt behaviour-type-2 [
    set behaviour-type 2
    set own-R&D 1.2                   ;; wie Typ 1                                           -> starke Initiative
    set open-R&D 0.3                  ;; wie Typ 1                                           -> starke Initiative
    set networking 0.1                ;; niedriger als Typ 1                                 -> geringe Vernetzung
    set network-skill-range 0.2       ;; Hoher Wert, vernetzt sich nur wenn es sich lohnt    -> geringe Vernetzung
    set network-money-range 50000     ;; Geringer Wert, vernetzt sich erst wenn er muss      -> geringe Vernetzung
    set max-connections max-links     ;; weniger als Typ 1                                   -> geringe Vernetzung

    ;; Identische Startwerte
    set money 100000
    set own-innovations [10 10 10 10 10 15 15 15] ;;
    set shared-innovations [10 10 10] ;; Geringe Vernetzung -> zum Start weniger externe, dafür 2 mehr bei interne Innovation (nicht 3 weil die mehr Geld geben)
    set skills n-values 3 [max-skill / 2]


    setxy random-xcor random-ycor
    set color blue
    set shape "house"
    set R&D-Cost 0
 ]


  crt behaviour-type-3 [
    set behaviour-type 3
    set own-R&D 0.8                    ;; niedrig      -> geringe Initiative
    set open-R&D 0.15                  ;; niedrig      -> geringe Initiative
    set networking 0.25                ;; wie Typ 1    -> starke Vernetzung
    set network-skill-range 0.1        ;; wie Typ 1    -> starke Vernetzung
    set network-money-range 1000000    ;; wie Typ 1    -> starke Vernetzung
    set max-connections max-links * 3  ;; wie Typ 1    -> starke Vernetzung

    ;; Startwerte
    set money 100000
    set own-innovations [15 15 15]
    set shared-innovations [10 10 10 15 15 15 15 15] ;; Starke Vernetzung, daher mehr zum Start, in Summe zwei mehr als die anderen weil extern weniger Geld einbringen
    set skills n-values 3 [max-skill / 2]


    setxy random-xcor random-ycor
    set color green
    set shape "house"
    set R&D-Cost 0
 ]

 reset-ticks

end


to go
  if create-startups? = "Yes" and ticks > 0 and ticks mod 8 = 0 [create-startups]   ;; Erstelle neue Agents/Firmen im Cluster alle 16 Ticks = 4 Jahre
  network                     ;; Vernetze die Agents neu gemäß ihrer Verhaltensregel
  internal-innovation         ;; Forsche an eigener Innovation und bezahle dafür
  collaborative-innovation    ;; Forsche zusammen mit vernetzten Partnern und bezahle dafür
  make-money                  ;; Sammel das Geld all deiner aktiven Innovationen ein, je nach Phase in der sie sind
  plot-all                    ;; Berechne Summen und andere Kennzahlen, die wir als Graphen plotten wollen, machen wir ganz zum Schluss
  if count turtles < 4 or ticks = 120 [stop]
  tick
end

to create-startups

  let skill-length 0

  ask one-of turtles [
    set skill-length length skills]    ;; Ermittle wieviele Skills wir gerade in der Liste haben in speichere den Wert für später

  ask turtles[set skills lput min-skill skills]  ;; schaffe einene neuen Skill, alle bisherigen Agents haben den Minimum-Skill in diesem neuen Skill

  crt 1 [
    set behaviour-type 4             ;; alle Werte wie Typ 1, ausser max-connections, weil Anfangs zu wenig personal für zu viele Links
    set own-R&D 1.2                  ;; Wie Typ 1
    set open-R&D 0.3                 ;; Wie Typ 1
    set networking 0.5               ;; schnelle Verlinkung, aber nur mit wenigen Partnern
    set network-skill-range 0.2      ;; Vernetzt sich nur wenn es sich lohnt
    set network-money-range 1000000  ;;
    set money 100000
    set own-innovations [16]                       ;; Aber ein marktreifes Produkt zum Start
    set shared-innovations [ ]                     ;; Keine Netzwerkinnovationen

    set skills n-values skill-length [min-skill]   ;; Setze alle anderen skills auf Minimum, das Startup kann nur eine Sache gut
    set skills lput max-skill skills               ;; Das dafür gleich richtig
    set max-connections max-links

    setxy random-xcor random-ycor
    set color red
    set shape "house"
    set R&D-Cost 0
    ]

  if disruptive-startups? = "Yes" [
    ask turtles [set skills remove-item 0 skills]] ;; Wenn die Startups disruptiv sind, wird sogar noch ein Skill gänzlich entfernt

end


to network
  ;; Es gibt zwei Arten von Verbindungen:
  ;; Die Blauen werden zufällig bestimmt bis zur Max Anzahl Links der Agents
  ;; Die Roten sind Links, die aufgebaut werden, wenn ein Skill die untergrenze erreicht hat und ein Partner mit einem höheren Skill dafür gesucht wird

  ;; Töte alle blauen Links die das maximale Alter wie im Slider festgelegt erreicht haben und die nicht über der durchschnittlichen Erfolgsrate liegen
  ask links with [(color = blue) and (link-age > max-link-age) and (link-success-rate / link-age < mean-link-success-rate)] [ die ]

  ;; Dasselbe nochmal mit den roten, nur ergänzt um deren Alterfaktor mit dem Slider
  ask links with [(color = red) and (link-age > (max-link-age * red-links-age-factor)) and (link-success-rate / link-age < mean-link-success-rate)] [ die ]

  let low-skill 1       ;; Variable um den kleinsten Skill zu speichern
  let low-skill-pos 0   ;; Variable um die Position des kleinsten Skills zu speichern

  ask turtles with [(min skills = min-skill) and (money < network-money-range)] [     ;; Alle Agents deren kleinster Skill an der per Slider definierten Skill-Untergrenze angekommen ist

    set low-skill min skills                      ;; Speichere den kleinsten Skill-Wert
    set low-skill-pos position low-skill skills   ;; Specihere dessen Position in der Skill-Liste

    ;; Wenn es Agents gibt, die mindesten network-skill-range Skillpunkte mehr haben als ich in meinem kleinsten Skill
    ;; dann schaffe einen neuen roten Link

    ;; Erst mal nachsehen, ob es überhaupt jemanden gibt der so viel besser ist als ich (weil wenn nicht, Fehlermeldung und Abbruch!)
    if any? turtles with [((item low-skill-pos skills) - network-skill-range) > low-skill and count my-links < max-connections] [
      if count my-links with [color = blue] > 0 [ask one-of my-links with [color = blue] [die]]  ;; Ersetze einen meiner blauen Links durch den neuen roten
      create-link-with one-of other turtles with [((item low-skill-pos skills) - network-skill-range) > low-skill and count my-links < max-connections] [
        set link-success-rate 0
        set link-age 0
        set color red
      ]
    ]
  ]

  ;; Alle Agents die nicht schon an ihrer per Slider definierten Link-Obergrenze angekommen sind bekommen einen neuen blauen Zufalls-Link dazu
  ask turtles with [count my-links < max-connections] [
    if (random-float 1 < networking) and (any? other turtles) [
     create-link-with one-of other turtles [
        set link-success-rate 0
        set link-age 0
        set color blue
      ]
    ]
  ]

  ;; Das ist der Befehl, der uns Ingo auch schon in der Übung gezeigt hat
  ;; Hier werden die Agents näher an ihre vernetzten Partner "herangezogen"
  ;; layout-spring funktioniert wie ein Gummiband oder eine Feder (spring) das vernetzte Agents zueinander zieht
  ;; So liegen vernetzte Agents näher beieinander und man sieht die Gruppen

  repeat 30 [ layout-spring turtles links 0.2 8 1 ]

end


to internal-innovation

  ask turtles [

    let single-skill 0 ;; Variable in der wir die einzelnen Einträge in unserer Skill-Liste zwischenspeichern

    ;; Range erstellt eine Liste von Zahlen die mit 0 Anfängt und bis zu einerm angegebenen Wert immer um eins erhöt
    ;; Im Fall unten ist es die Länge unserer Skill-Liste, wenn dort also 3 Werte drin stehn, ist die Liste
    ;; die range an foreach zurückgibt also [0 1 2]
    ;; Merke: Netlogo beginnt immer mit 0 zu zählen, die erste Position in der Liste ist also Position 0

    foreach range (length skills) [
      i ->                              ;; Das i ist eine temporäre Variable in der bei jedem Durchlauf die Zahl der Liste drinsteht, an deren Position wir gerade sind
                                        ;; im ersten durchlauf ist i also 0, im zweiten 1 usw. Wir nutzen das um uns mit dem Befehl item durch unsere Skill-Liste zu hangeln
      set single-skill (item i skills)  ;; Hier speichern wir den Skill-Wert zwischen, an dessen Position wir gerade sind

      ;; Das ist unser Orakel, das auf Basis der Wahrscheinlichkeit unseres Skill-Wertes und des Innovationsfaktors own-R&D bestimmt ob eine Innovation gefunden wurde

      ifelse random-float 1 < (single-skill * own-R&D) [

        set own-innovations lput 20 own-innovations               ;; Falls ja, setze eine neue Innovation ans Ende unserer Innovations-Liste (lput = last put) mit Wert 5...

        ifelse (single-skill + skill-gain) > max-skill                      ;; Falls wir an der Obergenze der Skills angekommen sind,
          [set skills (replace-item i skills max-skill)]                    ;; setze Wert auf Maximalwert,
          [set skills (replace-item i skills (single-skill + skill-gain))]  ;; falls nicht erhöhe ihn wir im Slider vorgegeben
        ]

       [ifelse (single-skill - skill-loss) < min-skill                      ;; Falls wir an der Untergrenze des Skills angekommen sind,
          [set skills (replace-item i skills min-skill)]                    ;; setze Wert auf Minimalwert,
          [set skills (replace-item i skills (single-skill - skill-loss))]  ;; falls nicht reduziere ihn wir im Slider vorgegeben
      ]
    ]
    set money (money - (own-R&D * cost-internal-r&d))  ;; Und hier die Kosten der Forschung, das werden wir später noch an die Einkünfte anpassen müssen,
                                                       ;; bzw. mit dem Startwert des Geldes jedes Agents in Bezug setzen

    set R&D-Cost cost-internal-r&d         ;; R&D Kosten sind mindestens einmal die Kosten der internen R&D pro Tick plus die external R&D, siehe unten
  ]
end



to collaborative-innovation

  ask turtles with [count my-links > 0] [         ;; Für alle Agents mit mindestens einem Link

    let me who                                    ;; Speichere die aktuelle Nummer des Agents der gerade bearbeitet wird
    let my-skills skills                          ;; Speichere dessen Skill-Tabelle zwischen
    let my-innovations shared-innovations         ;; Speichere dessen Innovations-Tabelle zwischen
    let my-open-R&D open-R&D

    ask link-neighbors [                          ;; Jetzt geh alle Nachbarn durch, mit denen er verlinkt ist

      let neighbor who                            ;; Speichere die aktuelle Nummer des Nachbar-Agents der gerade bearbeitet wird
      let neighbor-skills skills                  ;; Speichere dessen Skill-Tabelle
      let neighbor-innovations shared-innovations ;; Speichere dessen Innovations-Tabelle zwischen


      ask link me neighbor [                      ;; Jetzt geh die Links durch da wir jetzt auch noch die Link Variablen link-age und link-success-rate anpassen

       set link-age (link-age + 1)               ;; Erhöhe das Link-Alter um 1

       foreach range (length my-skills) [                                 ;; Jetzt geh alle meine Skills durch
         i ->                                                             ;; Mit i als Zähler
         let my-skill (item i my-skills)                                  ;; Speichere den Wert an Stelle i des Agents am einen Ende zwischen
         let neighbor-skill (item i neighbor-skills)                      ;; Speichere den Wert an Stelle i des Agents am anderen Ende zwischen
         let link-skill (my-open-R&D * (my-skill + neighbor-skill) / 4)

         ifelse random-float 1 < link-skill  [     ;; Unser Orakel arbeitet mit dem halben Durchschnittswert beider Enden
                                                                           ;; halb deswegen, weil der Link ja von jeder Seite einmal angegangen wird
                                                                           ;; daher halbe Wahrscheinlichkeit (also geteilt duch 4 statt 2)

            set my-innovations lput 20 my-innovations                      ;; Falls es geklappt aht, setze eine neue Innnovation ans Ende der Liste

            ifelse (my-skill + skill-gain) > max-skill                     ;; Falls wir an der Obergenze der Skills angekommen sind
              [set my-skills (replace-item i my-skills max-skill)]         ;; Setze Wert auf Maximalwert
              [set my-skills (replace-item i my-skills (my-skill + skill-gain))]  ;; Falls nicht erhöhe ihn wie im Slider vorgegeben

            set neighbor-innovations lput 20 neighbor-innovations           ;; Dasselbe nochmal für den Agent am anderen Ende des Links
            ifelse (neighbor-skill + skill-gain) > max-skill
              [set neighbor-skills (replace-item i neighbor-skills max-skill)]
              [set neighbor-skills (replace-item i neighbor-skills (neighbor-skill + skill-gain))]

          set link-success-rate (link-success-rate + 1)]                 ;; Falls es geklappt hat, setze die Success-Rate eins hoch

           [ifelse (my-skill - skill-loss) < min-skill                     ;; Falls es nicht geklappt hat und wir bereits an der Untergrenze des Skill-wertes angekommen sind
             [set my-skills (replace-item i my-skills min-skill)]          ;; Setze Wert auf Minimalwert
             [set my-skills (replace-item i my-skills (my-skill - skill-loss))]  ;; Falls nicht reduziere den Skill wir im Slider vorgegeben

           ifelse (neighbor-skill - skill-loss) < min-skill                ;; Dasselbe nochmal für den Agent am anderen Ende des Links
             [set neighbor-skills (replace-item i neighbor-skills min-skill)]
             [set neighbor-skills (replace-item i neighbor-skills (neighbor-skill - skill-loss))]
           ]
         ]
      ]
      set shared-innovations neighbor-innovations     ;; Kopiere die temporäre Innovations-Liste zurück in die Liste des Agents am einen Ende des Links
      set skills neighbor-skills                      ;; Genauso wie die Skill-Liste
    ]
    set shared-innovations my-innovations             ;; Kopiere die temporäre Innovations-Liste zurück in die Liste des Agents am anderen Ende des Links
    set skills my-skills                              ;; Genauso wie die Skill-Liste

    set money (money - (open-R&D * cost-external-r&d * (count my-links)))  ;; Bezahle für jeden Link des Agents die im Slider vorgegebenen Kosten

    set R&D-Cost (R&D-Cost + (open-R&D * cost-external-r&d * (count my-links)))  ;; Zu den internen R&D Kosten von oben kommen etzt noch die Kosten pro Link
  ]
end

to make-money
 ask turtles [
  foreach own-innovations [
    i ->                                      ;; Wieder die temporäre Variable, die bei jedem Durshcgang den Wert von own-innovations speichert,
                                              ;; an dessen Positon wir gerade sind
    if i <= 20 and i > 16 [ set money (money - 600) ]    ;; Im Moment lebt eine Innovation immer über 20 Ticks, die ersten 4 Ticks kosten Geld -> Einführung
    if i <= 16 and i > 12  [ set money (money + 800) ]   ;; die nächsten 4 Ticks verdient man etwas Geld -> Wachstum
    if i <= 12  and i > 4  [ set money (money + 1600) ]  ;; die nächsten 8 Ticks verdienen wir das eigentliche Geld -> Reife
    if i <= 4 [ set money (money + 800) ]                ;; und dann noch 4 Ticks lang Sättigung mit wieder weniger Geld -> Sättigung
    ]

    ;; Mit foreach kann man die Einträge einer Liste nicht verändern,
    ;; Wenn man da das i verändert verändert man nur diese temporäre Variable aber nicht die Einträge der Liste
    ;; Wenn wir also pro Tick alle Zähler unser Innovationen um 1 reduzieren wollen brauchen wir map
    ;; Wie foreach geht auch map alle Einträge einer Liste nacheinander durch, hier kann man die jeweiligen i Werte aber verändern
    ;; Alle veränderten i Werte werden als Ergebnisliste zurückgegeben
    ;; Mit der Liste die map zurückgibt überschreiben wir unsere alte Innovations-Liste, also mit den Werten die alle um 1 reduziert wurden

    set own-innovations map [i -> i - 1] own-innovations
    set own-innovations remove 0 own-innovations ;; Lösche alle abgelaufenen innovation mit Wert 0 aus der Liste

  foreach shared-innovations [
    i ->                                      ;; Wieder die temporäre Variable, die bei jedem Durchgang den Wert von own-innovations speichert,

    if i <= 20 and i > 16 [ set money (money - 300) ]    ;; Im Moment lebt eine Innovation immer über 20 Ticks, die ersten 4 Ticks kosten Geld -> Einführung
    if i <= 16 and i > 12  [ set money (money + 400) ]   ;; die nächsten 4 Ticks verdient man etwas Geld -> Wachstum
    if i <= 12  and i > 4  [ set money (money + 800) ]   ;; die nächsten 8 Ticks verdienen wir das eigentliche Geld -> Reife
    if i <= 4 [ set money (money + 400 ) ]               ;; und dann noch 4 Ticks lang Sättigung mit wieder weniger Geld -> Sättigung

      ;; Regel, shared-innivations geben nur 50% des Geldes wie own
    ]

    set shared-innovations map [i -> i - 1] shared-innovations
    set shared-innovations remove 0 shared-innovations ;; Lösche alle abgelaufenen innovation mit Wert 0 aus der Liste

    if money < 0 [die]
    if money > 200000 [set size 2]
    if money > 400000 [set size 3]

  ]
end

to plot-all
  If count links > 0 [ set mean-link-success-rate (mean [link-success-rate] of links) / (mean [link-age] of links) ]

end
@#$#@#$#@
GRAPHICS-WINDOW
210
10
647
448
-1
-1
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
0
0
1
ticks
30.0

BUTTON
18
124
191
157
Setup
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
18
163
102
196
Go
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
1136
80
1552
125
NIL
[skills] of turtle first-turtle
2
1
11

MONITOR
1136
131
1553
176
NIL
[shared-innovations] of turtle first-turtle
17
1
11

INPUTBOX
1247
10
1344
70
first-turtle
22.0
1
0
Number

INPUTBOX
1376
10
1473
70
second-turtle
25.0
1
0
Number

MONITOR
1139
246
1552
291
NIL
[skills] of turtle second-turtle
17
1
11

MONITOR
1139
296
1551
341
NIL
[shared-innovations] of turtle second-turtle
17
1
11

PLOT
1141
403
1341
553
Skills first Turtle
NIL
NIL
0.0
10.0
0.0
1.0
true
false
"" ""
PENS
"Skill 1" 1.0 0 -14439633 true "" "plot [item 0 skills] of turtle first-turtle"
"Skill 2" 1.0 0 -12345184 true "" "plot [item 1 skills] of turtle first-turtle"
"Skill 3" 1.0 0 -2674135 true "" "plot [item 2 skills] of turtle first-turtle"

PLOT
1349
402
1549
552
Skills second Turtle
NIL
NIL
0.0
10.0
0.0
1.0
true
false
"" ""
PENS
"default" 1.0 0 -14439633 true "" "plot [item 0 skills] of turtle second-turtle"
"pen-1" 1.0 0 -12345184 true "" "plot [item 1 skills] of turtle second-turtle"
"pen-2" 1.0 0 -2674135 true "" "plot [item 2 skills] of turtle second-turtle"

SLIDER
20
315
192
348
max-link-age
max-link-age
1
20
15.0
1
1
NIL
HORIZONTAL

SLIDER
20
387
192
420
max-links
max-links
1
10
8.0
1
1
NIL
HORIZONTAL

SLIDER
20
351
192
384
red-links-age-factor
red-links-age-factor
0
2
1.0
0.1
1
NIL
HORIZONTAL

PLOT
1142
557
1342
707
Money Turtle 1
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
"default" 1.0 0 -16777216 true "" "plot [money] of turtle first-turtle"

PLOT
1349
556
1549
706
Money Turtle 2
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
"default" 1.0 0 -16777216 true "" "plot [money] of turtle second-turtle"

SLIDER
20
432
192
465
cost-internal-r&d
cost-internal-r&d
500
15000
6000.0
100
1
NIL
HORIZONTAL

SLIDER
20
469
193
502
cost-external-r&d
cost-external-r&d
500
10000
1500.0
100
1
NIL
HORIZONTAL

PLOT
654
10
854
160
Number of Agents
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
"default" 1.0 0 -16777216 true "" "plot count turtles"
"pen-1" 1.0 0 -955883 true "" "plot count turtles with [behaviour-type = 1]"
"pen-2" 1.0 0 -13345367 true "" "plot count turtles with [behaviour-type = 2]"
"pen-3" 1.0 0 -10899396 true "" "plot count turtles with [behaviour-type = 3]"
"pen-4" 1.0 0 -2674135 true "" "plot count turtles with [behaviour-type = 4]"

MONITOR
1137
182
1552
227
NIL
[own-innovations] of turtle first-turtle
17
1
11

MONITOR
1139
346
1550
391
NIL
[own-innovations] of turtle second-turtle
17
1
11

PLOT
860
165
1060
315
Average Money per Agent
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
"default" 1.0 0 -16777216 true "" "plot mean [money] of turtles"
"pen-1" 1.0 0 -955883 true "" "plot mean [money] of turtles with [behaviour-type = 1]"
"pen-2" 1.0 0 -13345367 true "" "plot mean [money] of turtles with [behaviour-type = 2]"
"pen-3" 1.0 0 -10899396 true "" "plot mean [money] of turtles with [behaviour-type = 3]"
"pen-4" 1.0 0 -2674135 true "" "plot mean [money] of turtles with [behaviour-type = 4]"

BUTTON
110
163
192
196
Go once
go
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
656
473
856
623
Average Amount of Links
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
"default" 1.0 0 -16777216 true "" "plot mean [count my-links] of turtles"
"pen-1" 1.0 0 -955883 true "" "plot mean [count my-links] of turtles with [behaviour-type = 1]"
"pen-2" 1.0 0 -13345367 true "" "plot mean [count my-links] of turtles with [behaviour-type = 2]"
"pen-3" 1.0 0 -10899396 true "" "plot mean [count my-links] of turtles with [behaviour-type = 3]"
"pen-4" 1.0 0 -2674135 true "" "plot mean [count my-links] of turtles with [behaviour-type = 4]"

PLOT
655
319
855
469
Average R&D Cost
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
"default" 1.0 0 -16777216 true "" "plot mean [R&D-Cost] of turtles"
"pen-1" 1.0 0 -955883 true "" "plot mean [R&D-Cost] of turtles with [behaviour-type = 1]"
"pen-2" 1.0 0 -13345367 true "" "plot mean [R&D-Cost] of turtles with [behaviour-type = 2]"
"pen-3" 1.0 0 -10899396 true "" "plot mean [R&D-Cost] of turtles with [behaviour-type = 3]"
"pen-4" 1.0 0 -2674135 true "" "plot mean [R&D-Cost] of turtles with [behaviour-type = 4]"

PLOT
860
319
1060
469
Percentage of R&D to Money
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
"default" 1.0 0 -16777216 true "" "plot 100 * ((mean [R&D-Cost] of turtles) / (mean [money] of turtles))"
"pen-1" 1.0 0 -955883 true "" "plot 100 * ((mean [R&D-Cost] of turtles with [behaviour-type = 1]) / (mean [money] of turtles with [behaviour-type = 1]))"
"pen-2" 1.0 0 -13345367 true "" "plot 100 * ((mean [R&D-Cost] of turtles with [behaviour-type = 2]) / (mean [money] of turtles with [behaviour-type = 2]))"
"pen-3" 1.0 0 -10899396 true "" "plot 100 * ((mean [R&D-Cost] of turtles with [behaviour-type = 3]) / (mean [money] of turtles with [behaviour-type = 3]))"
"pen-4" 1.0 0 -2674135 true "" "plot 100 * ((mean [R&D-Cost] of turtles with [behaviour-type = 4]) / (mean [money] of turtles with [behaviour-type = 4]))"

PLOT
861
472
1061
622
Mean Success Rate of Links
NIL
NIL
0.0
10.0
0.0
0.3
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot mean-link-success-rate"

CHOOSER
19
212
191
257
create-startups?
create-startups?
"No" "Yes"
0

CHOOSER
19
259
191
304
disruptive-startups?
disruptive-startups?
"No" "Yes"
0

PLOT
655
165
855
315
Amount of Money in Cluster
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
"default" 1.0 0 -16777216 true "" "plot sum [money] of turtles"
"pen-1" 1.0 0 -955883 true "" "plot sum [money] of turtles with [behaviour-type = 1]"
"pen-2" 1.0 0 -13345367 true "" "plot sum [money] of turtles with [behaviour-type = 2]"
"pen-3" 1.0 0 -10899396 true "" "plot sum [money] of turtles with [behaviour-type = 3]"
"pen-4" 1.0 0 -2674135 true "" "plot sum [money] of turtles with [behaviour-type = 4]"

PLOT
859
10
1059
160
Number of Links
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
"default" 1.0 0 -16777216 true "" "plot count links"
"pen-2" 1.0 0 -13345367 true "" "plot count links with [color = blue]"
"pen-4" 1.0 0 -2674135 true "" "plot count links with [color = red]"

SLIDER
18
13
190
46
behaviour-type-1
behaviour-type-1
0
30
10.0
1
1
NIL
HORIZONTAL

SLIDER
18
48
190
81
behaviour-type-2
behaviour-type-2
0
30
10.0
1
1
NIL
HORIZONTAL

SLIDER
18
83
190
116
behaviour-type-3
behaviour-type-3
0
30
10.0
1
1
NIL
HORIZONTAL

PLOT
211
463
411
613
Innovations by Innovation Type
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
"default" 1.0 0 -16777216 true "" "plot sum [length own-innovations] of turtles + sum [length shared-innovations] of turtles"
"pen-1" 1.0 0 -13345367 true "" "plot sum [length own-innovations] of turtles"
"pen-2" 1.0 0 -10899396 true "" "plot sum [length shared-innovations] of turtles"

PLOT
445
462
645
612
Innovation by Behaviour Type
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
"default" 1.0 0 -16777216 true "" "plot sum [length own-innovations] of turtles + sum [length shared-innovations] of turtles"
"pen-1" 1.0 0 -955883 true "" "plot sum [length own-innovations] of turtles with [behaviour-type = 1] + sum [length shared-innovations] of turtles with [behaviour-type = 1]"
"pen-2" 1.0 0 -13345367 true "" "plot sum [length own-innovations] of turtles with [behaviour-type = 2] + sum [length shared-innovations] of turtles with [behaviour-type = 2]"
"pen-3" 1.0 0 -10899396 true "" "plot sum [length own-innovations] of turtles with [behaviour-type = 3] + sum [length shared-innovations] of turtles with [behaviour-type = 3]"
"pen-4" 1.0 0 -2674135 true "" "plot sum [length own-innovations] of turtles with [behaviour-type = 4] + sum [length shared-innovations] of turtles with [behaviour-type = 4]"

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
NetLogo 6.1.1
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="Standardwerte ohne Startups" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles</metric>
    <metric>count turtles with [behaviour-type = 1]</metric>
    <metric>count turtles with [behaviour-type = 2]</metric>
    <metric>count turtles with [behaviour-type = 3]</metric>
    <metric>count turtles with [behaviour-type = 4]</metric>
    <metric>sum [length own-innovations] of turtles + sum [length shared-innovations] of turtles</metric>
    <metric>sum [length own-innovations] of turtles with [behaviour-type = 1] + sum [length shared-innovations] of turtles with [behaviour-type = 1]</metric>
    <metric>sum [length own-innovations] of turtles with [behaviour-type = 2] + sum [length shared-innovations] of turtles with [behaviour-type = 2]</metric>
    <metric>sum [length own-innovations] of turtles with [behaviour-type = 3] + sum [length shared-innovations] of turtles with [behaviour-type = 3]</metric>
    <metric>sum [length own-innovations] of turtles with [behaviour-type = 4] + sum [length shared-innovations] of turtles with [behaviour-type = 4]</metric>
    <metric>sum [money] of turtles</metric>
    <metric>sum [money] of turtles with [behaviour-type = 1]</metric>
    <metric>sum [money] of turtles with [behaviour-type = 2]</metric>
    <metric>sum [money] of turtles with [behaviour-type = 3]</metric>
    <metric>sum [money] of turtles with [behaviour-type = 4]</metric>
    <metric>mean [money] of turtles</metric>
    <metric>mean [money] of turtles with [behaviour-type = 1]</metric>
    <metric>mean [money] of turtles with [behaviour-type = 2]</metric>
    <metric>mean [money] of turtles with [behaviour-type = 3]</metric>
    <metric>mean [money] of turtles with [behaviour-type = 4]</metric>
    <enumeratedValueSet variable="cost-external-r&amp;d">
      <value value="1500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="behaviour-type-1">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="create-startups?">
      <value value="&quot;No&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-links">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="second-turtle">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-link-age">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="red-links-age-factor">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="disruptive-startups?">
      <value value="&quot;No&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cost-internal-r&amp;d">
      <value value="6000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="behaviour-type-2">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="first-turtle">
      <value value="22"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="behaviour-type-3">
      <value value="10"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Standardwerte mit Startups" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles</metric>
    <metric>count turtles with [behaviour-type = 1]</metric>
    <metric>count turtles with [behaviour-type = 2]</metric>
    <metric>count turtles with [behaviour-type = 3]</metric>
    <metric>count turtles with [behaviour-type = 4]</metric>
    <metric>sum [length own-innovations] of turtles + sum [length shared-innovations] of turtles</metric>
    <metric>sum [length own-innovations] of turtles with [behaviour-type = 1] + sum [length shared-innovations] of turtles with [behaviour-type = 1]</metric>
    <metric>sum [length own-innovations] of turtles with [behaviour-type = 2] + sum [length shared-innovations] of turtles with [behaviour-type = 2]</metric>
    <metric>sum [length own-innovations] of turtles with [behaviour-type = 3] + sum [length shared-innovations] of turtles with [behaviour-type = 3]</metric>
    <metric>sum [length own-innovations] of turtles with [behaviour-type = 4] + sum [length shared-innovations] of turtles with [behaviour-type = 4]</metric>
    <metric>sum [money] of turtles</metric>
    <metric>sum [money] of turtles with [behaviour-type = 1]</metric>
    <metric>sum [money] of turtles with [behaviour-type = 2]</metric>
    <metric>sum [money] of turtles with [behaviour-type = 3]</metric>
    <metric>sum [money] of turtles with [behaviour-type = 4]</metric>
    <metric>mean [money] of turtles</metric>
    <metric>mean [money] of turtles with [behaviour-type = 1]</metric>
    <metric>mean [money] of turtles with [behaviour-type = 2]</metric>
    <metric>mean [money] of turtles with [behaviour-type = 3]</metric>
    <metric>mean [money] of turtles with [behaviour-type = 4]</metric>
    <enumeratedValueSet variable="cost-external-r&amp;d">
      <value value="1500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="behaviour-type-1">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="create-startups?">
      <value value="&quot;Yes&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-links">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="second-turtle">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-link-age">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="red-links-age-factor">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="disruptive-startups?">
      <value value="&quot;Yes&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cost-internal-r&amp;d">
      <value value="6000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="behaviour-type-2">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="first-turtle">
      <value value="22"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="behaviour-type-3">
      <value value="10"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Kosten Open vs Own Innovation - ohne Startups" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles</metric>
    <metric>count turtles with [behaviour-type = 1]</metric>
    <metric>count turtles with [behaviour-type = 2]</metric>
    <metric>count turtles with [behaviour-type = 3]</metric>
    <metric>count turtles with [behaviour-type = 4]</metric>
    <metric>sum [length own-innovations] of turtles + sum [length shared-innovations] of turtles</metric>
    <metric>sum [length own-innovations] of turtles with [behaviour-type = 1] + sum [length shared-innovations] of turtles with [behaviour-type = 1]</metric>
    <metric>sum [length own-innovations] of turtles with [behaviour-type = 2] + sum [length shared-innovations] of turtles with [behaviour-type = 2]</metric>
    <metric>sum [length own-innovations] of turtles with [behaviour-type = 3] + sum [length shared-innovations] of turtles with [behaviour-type = 3]</metric>
    <metric>sum [length own-innovations] of turtles with [behaviour-type = 4] + sum [length shared-innovations] of turtles with [behaviour-type = 4]</metric>
    <metric>sum [money] of turtles</metric>
    <metric>sum [money] of turtles with [behaviour-type = 1]</metric>
    <metric>sum [money] of turtles with [behaviour-type = 2]</metric>
    <metric>sum [money] of turtles with [behaviour-type = 3]</metric>
    <metric>sum [money] of turtles with [behaviour-type = 4]</metric>
    <metric>mean [money] of turtles</metric>
    <metric>mean [money] of turtles with [behaviour-type = 1]</metric>
    <metric>mean [money] of turtles with [behaviour-type = 2]</metric>
    <metric>mean [money] of turtles with [behaviour-type = 3]</metric>
    <metric>mean [money] of turtles with [behaviour-type = 4]</metric>
    <steppedValueSet variable="cost-external-r&amp;d" first="1500" step="500" last="6000"/>
    <enumeratedValueSet variable="behaviour-type-1">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="create-startups?">
      <value value="&quot;No&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-links">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="second-turtle">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-link-age">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="red-links-age-factor">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="disruptive-startups?">
      <value value="&quot;No&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cost-internal-r&amp;d">
      <value value="6000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="behaviour-type-2">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="first-turtle">
      <value value="22"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="behaviour-type-3">
      <value value="10"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Anzahl Links - ohne Startups" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles</metric>
    <metric>count turtles with [behaviour-type = 1]</metric>
    <metric>count turtles with [behaviour-type = 2]</metric>
    <metric>count turtles with [behaviour-type = 3]</metric>
    <metric>count turtles with [behaviour-type = 4]</metric>
    <metric>sum [length own-innovations] of turtles + sum [length shared-innovations] of turtles</metric>
    <metric>sum [length own-innovations] of turtles with [behaviour-type = 1] + sum [length shared-innovations] of turtles with [behaviour-type = 1]</metric>
    <metric>sum [length own-innovations] of turtles with [behaviour-type = 2] + sum [length shared-innovations] of turtles with [behaviour-type = 2]</metric>
    <metric>sum [length own-innovations] of turtles with [behaviour-type = 3] + sum [length shared-innovations] of turtles with [behaviour-type = 3]</metric>
    <metric>sum [length own-innovations] of turtles with [behaviour-type = 4] + sum [length shared-innovations] of turtles with [behaviour-type = 4]</metric>
    <metric>sum [money] of turtles</metric>
    <metric>sum [money] of turtles with [behaviour-type = 1]</metric>
    <metric>sum [money] of turtles with [behaviour-type = 2]</metric>
    <metric>sum [money] of turtles with [behaviour-type = 3]</metric>
    <metric>sum [money] of turtles with [behaviour-type = 4]</metric>
    <metric>mean [money] of turtles</metric>
    <metric>mean [money] of turtles with [behaviour-type = 1]</metric>
    <metric>mean [money] of turtles with [behaviour-type = 2]</metric>
    <metric>mean [money] of turtles with [behaviour-type = 3]</metric>
    <metric>mean [money] of turtles with [behaviour-type = 4]</metric>
    <enumeratedValueSet variable="cost-external-r&amp;d">
      <value value="1500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="behaviour-type-1">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="create-startups?">
      <value value="&quot;No&quot;"/>
    </enumeratedValueSet>
    <steppedValueSet variable="max-links" first="2" step="1" last="8"/>
    <enumeratedValueSet variable="second-turtle">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-link-age">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="red-links-age-factor">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="disruptive-startups?">
      <value value="&quot;No&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cost-internal-r&amp;d">
      <value value="6000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="behaviour-type-2">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="first-turtle">
      <value value="22"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="behaviour-type-3">
      <value value="10"/>
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
