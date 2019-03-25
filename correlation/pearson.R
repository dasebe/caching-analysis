library(data.table)
library(ggplot2)

dt <- data.table(read.table("pearson.log"))

dt[,V1:=gsub("/scratch2/traces/","",V1)]

dt
setnames(dt,c("V1","V2","V3","V4","V5","V6","V7"),
         c("trace","initcount","interval","reps","objcount","p","freq"))

dt[,unique(initcount)]
dt[,unique(interval)]
dt[,unique(reps)]
dt[,unique(objcount)]

dt[,sfreq:=sum(freq),by=list(trace,initcount,interval,reps,objcount)]
dt[,trace2:=factor(trace,levels=dt[,unique(trace)],labels=c("MSR","Wiki","Anonymous","Caida"))]

dt2 <- dt[objcount==100000 & interval==20000]
dt2 <- dt[objcount==100000 & interval==10000]

dt2[,unique(sfreq)]

p<-ggplot(data=dt2, aes(x=p, y=freq/sfreq)) +
    geom_bar(stat="identity") +
        facet_wrap(~trace2,nrow=1)+
            scale_x_continuous("Pearson Correlation Coefficient")+
                scale_y_continuous("Ratio of Object Pairs")+
                    theme(panel.spacing = unit(2, "lines"))
pdf("/tmp/correlation.pdf",8,5)
print(p)
dev.off()
