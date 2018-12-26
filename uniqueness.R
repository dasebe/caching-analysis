library(ggplot2)
library(data.table)
library(foreach)
#library(doparallel)
ggplot <- function(...) { ggplot2::ggplot(...) + theme_bw() }

confs <- c("10.0","19.99","19","19.9")
sizes <- c(30,32,34)
reps <- 1:30

### cpp

dt <- foreach(conf=confs, .combine=rbind, .errorhandling="remove") %:%
    foreach(size=sizes, .combine=rbind, .errorhandling="remove") %:%
    foreach(rep=combn(reps,2), .combine=rbind, .errorhandling="remove") %do% {
        fname <- paste("uniqueTrace/res_cpp_w20m_",conf,"m_rD_",size,"_",rep[1],"_",rep[2],".log",sep="")
#        print(fname)
        tmp <- data.table(read.table(fname))
        tmp[,list(conf,size,rep[1],rep[2],type=V1,val=V2)]
}

dt[type=="iter",list(mean(as.numeric(val)),min(as.numeric(val)),max(as.numeric(val))),by=conf]

#dt[,maxInCommon:=as.numeric(conf)*1e6]
#dt[,maxInCommon:=NULL]

dtt <- dt[type %in% c(0,1),list(maxInCommon=sum(val)),by=list(conf,size,V3,V4)]
setkey(dt,conf,size,V3,V4)
setkey(dtt,conf,size,V3,V4)
dt2 <- dt[dtt]

dt2[,conf2:=(20-as.numeric(conf))/20]

dt2[,ratio:=val/maxInCommon]
dt2[type==0,list(mean(ratio)),by=list(conf,size)]


computeci <- function(x) {
  t=try(t.test(x,conf.level=0.99), silent=TRUE)
  if (is(t, "try-error")) return(0) else return(t$estimate-t$conf.int[1])
  }

dt3 <- dt2[type==1,list(r=mean(ratio),ci=computeci(ratio)),by=list(conf2,size)]
dt3

pdf("/tmp/plots/knockon.pdf",6,5)
ggplot(dt3,aes(paste(round(conf2,4)*100,"%"),r,fill=factor(size)))+
    geom_bar(stat="identity", width=.5, position = position_dodge(0.6))+
    geom_errorbar(aes(ymin=r-ci,ymax=r+ci),width=.2,size=0.7, color="grey40", position = position_dodge(0.6))+
    scale_y_continuous("Difference in decision for requests that remain in both traces",expand=c(0,0))+
    scale_x_discrete("Percentage of requests deleted from trace",expand=c(0,0))+
    theme(legend.key.width = unit(1.1, "cm"),
          legend.key.height = unit(0.43, "cm"))+
    theme(legend.text = element_text(size = rel(0.9)))+
    theme(axis.title.x = element_text(size = rel(1.05),vjust=-.1),axis.title.y = element_text(size = rel(1.05),vjust=1.2))+
    coord_cartesian(ylim=c(0,.3))
dev.off()



### unix comm stuff

dt <- foreach(conf=confs, .combine=rbind, .errorhandling="remove") %:%
    foreach(size=sizes, .combine=rbind, .errorhandling="remove") %:%
    foreach(rep=combn(reps,2), .combine=rbind, .errorhandling="remove") %do% {
        fname <- paste("uniqueTrace/res_w20m_",conf,"m_rD_",size,"_",rep[1],"_",rep[2],".log",sep="")
#        print(fname)
        tmp <- scan(fname)
        data.table(conf,size,rep[1],rep[2],val=tmp)
}

dt

dt[,maxInCommon:=as.numeric(conf)*1e6]
dt[,ratio:=val/maxInCommon]


dt[,list(mean(ratio)),by=list(conf,size)]
