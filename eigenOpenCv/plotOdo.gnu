set multiplot layout 2,1

plot  "< tail -2000 logs/logMain.csv" using 1:6  title 'pos x'  with lines , \
      "< tail -2000 logs/logMain.csv" using 1:7  title 'pos y'  with lines , \
      "< tail -2000 logs/logMain.csv" using 1:8  title 'pos z'  with lines , \
      "< tail -2000 logs/log.csv"     using 1:6  title 'pos est x'  with lines , \
      "< tail -2000 logs/log.csv"     using 1:7 title 'pos est y'  with lines , \
      "< tail -2000 logs/log.csv"     using 1:8 title 'pos est z'  with lines

plot  "< tail -2000 logs/logMain.csv" using 1:9  title 'vel x'  with lines , \
      "< tail -2000 logs/logMain.csv" using 1:10 title 'vel y'  with lines , \
      "< tail -2000 logs/logMain.csv" using 1:11 title 'vel z'  with lines , \
      "< tail -2000 logs/log.csv"     using 1:9  title 'vel est x'  with lines , \
      "< tail -2000 logs/log.csv"     using 1:10 title 'vel est y'  with lines , \
      "< tail -2000 logs/log.csv"     using 1:11 title 'vel est z'  with lines

unset multiplot

pause -1
