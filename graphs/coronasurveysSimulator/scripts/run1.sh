# docker build -t coronasurveys:debugging .

F=0.01
S=300
r=150
E=0



E=0

S=300
GNAME=ringmodel-100k
/coronasurveys/bin/scaleUpDirectSurveyComparator -g /coronasurveys/graphs/$GNAME.txt -s /coronasurveys/seeds.txt -f $F -S $S -r $r >$GNAME-f$f-S$S-r$r-e$E.out &


GNAME=ringmodel-1M
/coronasurveys/bin/scaleUpDirectSurveyComparator -g /coronasurveys/graphs/$GNAME.txt -s /coronasurveys/seeds.txt -f $F -S $S -r $r >$GNAME-f$f-S$S-r$r-e$E.out &

GNAME=PrefA1000000-50
/coronasurveys/bin/scaleUpDirectSurveyComparator -G $GNAME -s /coronasurveys/seeds.txt -f $F -S $S -r $r -e $E >$GNAME-f$f-S$S-r$r-e$E.out &

S=3000
GNAME=com-dblp.ungraph
/coronasurveys/bin/scaleUpDirectSurveyComparator -g /coronasurveys/graphs/$GNAME.txt -s /coronasurveys/seeds.txt -f $F -S $S -r $r >$GNAME-f$f-S$S-r$r-e$E.out &

E=0.01

S=300
GNAME=ringmodel-100k
/coronasurveys/bin/scaleUpDirectSurveyComparator -g /coronasurveys/graphs/$GNAME.txt -s /coronasurveys/seeds.txt -f $F -S $S -r $r >$GNAME-f$f-S$S-r$r-e$E.out &


GNAME=ringmodel-1M
/coronasurveys/bin/scaleUpDirectSurveyComparator -g /coronasurveys/graphs/$GNAME.txt -s /coronasurveys/seeds.txt -f $F -S $S -r $r >$GNAME-f$f-S$S-r$r-e$E.out &

GNAME=PrefA1000000-50
/coronasurveys/bin/scaleUpDirectSurveyComparator -G $GNAME -s /coronasurveys/seeds.txt -f $F -S $S -r $r -e $E >$GNAME-f$f-S$S-r$r-e$E.out &

S=3000
GNAME=com-dblp.ungraph
/coronasurveys/bin/scaleUpDirectSurveyComparator -g /coronasurveys/graphs/$GNAME.txt -s /coronasurveys/seeds.txt -f $F -S $S -r $r >$GNAME-f$f-S$S-r$r-e$E.out &
