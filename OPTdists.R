library(ggplot2)
library(data.table)
library(foreach)
ggplot <- function(...) { ggplot2::ggplot(...) + theme_bw() }

list.files()

## keep time

keep30 <- data.table(read.table("OPTdists_w100m_30_1.log"))
keep34 <- data.table(read.table("OPTdists_w100m_34_1.log"))
keep32 <- data.table(read.table("OPTdists_w100m_32_1.log"))
keep38 <- data.table(read.table("OPTdists_w100m_38_1.log"))
keep36 <- data.table(read.table("OPTdists_w100m_36_1.log"))

keep30[,logsize:=30]
keep34[,logsize:=34]
keep32[,logsize:=32]
keep38[,logsize:=38]
keep36[,logsize:=36]

keep <- rbind(keep30,keep34,keep32,keep38,keep36)

setnames(keep,"V1","time")
setnames(keep,"V2","count")

keep[,max(time),by=logsize]

# fraction of time kept only one interval
keep[,sumCount:=sum(count),by=logsize]
keep[time==1,count/sumCount,by=logsize]
keep[time>10,sum(count)/max(sumCount),by=logsize]

pdf("/tmp/plots/keepTime.pdf",8,5)
ggplot(keep,aes(time,count,color=factor(logsize)))+
   geom_line(size=0.7)+
    scale_y_log10("Decision count",expand=c(0,0))+
    scale_x_log10("Number of consecutive periods object is kept in cache",expand=c(0,0))+
    theme(legend.key.width = unit(1.1, "cm"),
          legend.key.height = unit(0.43, "cm"))+
#    theme(legend.position = c(.73,0.25))+
    theme(legend.text = element_text(size = rel(0.9)))+
    theme(axis.title.x = element_text(size = rel(1.05),vjust=-.1),axis.title.y = element_text(size = rel(1.05),vjust=1.2))+
    coord_cartesian(xlim=c(1,10000))
dev.off()


## per obj stats

objs30 <- data.table(read.table("OPTdists_w100m_30_2.log"))
objs34 <- data.table(read.table("OPTdists_w100m_34_2.log"))
objs32 <- data.table(read.table("OPTdists_w100m_32_2.log"))
objs38 <- data.table(read.table("OPTdists_w100m_38_2.log"))
objs36 <- data.table(read.table("OPTdists_w100m_36_2.log"))

objs30[,logsize:=30]
objs34[,logsize:=34]
objs32[,logsize:=32]
objs38[,logsize:=38]
objs36[,logsize:=36]

objs <- rbind(objs30,objs34,objs32,objs38,objs36)

setnames(objs,"V1","admissions")
setnames(objs,"V2","evictions")
setnames(objs,"V3","hits")
setnames(objs,"V4","size")
setnames(objs,"V5","freq")

objs[,max(admissions)]

objs[,notAdmitted:=freq-hits-admissions]

objs[,admProb:=admissions/(notAdmitted+admissions)]
objs[admProb<1]


computeci <- function(x) {
  t=try(t.test(x,conf.level=0.99), silent=TRUE)
  if (is(t, "try-error")) return(0) else return(t$estimate-t$conf.int[1])
}


objs2 <- objs[,list(m=mean(admProb),ci=computeci(admProb)),by=list(osize=round(3*log2(size))/3,csize=logsize)]
objs2 <- objs[,list(m=mean(admProb),ci=computeci(admProb)),by=list(osize=round(2*log2(size))/2,csize=logsize)]
#objs2 <- objs[,list(m=mean(admProb)),by=list(osize=size,csize=logsize)]
head(objs2,30)

objs2[csize==30][osize<10]
objs2[csize==38][osize<10]

pdf("/tmp/plots/sizeAdmission.pdf",8,5)
ggplot(objs2,aes(osize,m,color=factor(csize)))+
#    geom_errorbar(aes(ymin=m-ci,ymax=m+ci),width=.5,size=0.7, position = position_dodge(0.1))+
    geom_errorbar(aes(ymin=m-ci,ymax=m+ci),width=.3,size=0.4, position = position_dodge(0.1),color="grey50")+
    geom_line(size=0.5)+
    geom_point(color="grey50",size=0.3)+
    scale_y_continuous("OPT's admission ratio",expand=c(0,0))+
    scale_x_continuous("Object Size",breaks=seq(0,30,10),labels=c("1B","1KB","1MB","1GB"),minor_breaks=NULL,expand=c(0.01,0))  +
    theme(legend.key.width = unit(1.1, "cm"),
          legend.key.height = unit(0.43, "cm"))+
#    theme(legend.position = c(.73,0.25))+
    theme(legend.text = element_text(size = rel(0.9)))+
    theme(axis.title.x = element_text(size = rel(1.05),vjust=-.1),axis.title.y = element_text(size = rel(1.05),vjust=1.2))+
    coord_cartesian(ylim=c(0,1.01),xlim=c(objs2[,min(osize)],objs2[,max(osize)]))
dev.off()

dt <- data.table(osize=(1:320)/8)

dt2 <- rbind(
    dt[,list(osize,m=exp(-2^osize/2^12),csize=30)],
    dt[,list(osize,m=exp(-2^osize/2^12.5),csize=32)],
    dt[,list(osize,m=exp(-2^osize/2^14),csize=34)],
    dt[,list(osize,m=exp(-2^osize/2^16),csize=36)],
    dt[,list(osize,m=exp(-2^osize/2^19.5),csize=38)]
)

pdf("/tmp/plots/sizeAdmission_AdaptSize.pdf",8,5)
ggplot(dt2,aes(osize,m,color=factor(csize)))+
   geom_line(size=0.7)+
    scale_y_continuous("AdaptSize's admission ratio",expand=c(0,0))+
    scale_x_continuous("Object Size",breaks=seq(0,30,10),labels=c("1B","1KB","1MB","1GB"),minor_breaks=NULL,expand=c(0.01,0))  +
    theme(legend.key.width = unit(1.1, "cm"),
          legend.key.height = unit(0.43, "cm"))+
#    theme(legend.position = c(.73,0.25))+
    theme(legend.text = element_text(size = rel(0.9)))+
    theme(axis.title.x = element_text(size = rel(1.05),vjust=-.1),axis.title.y = element_text(size = rel(1.05),vjust=1.2))+
    coord_cartesian(ylim=c(0,1.01),xlim=c(objs2[,min(osize)],objs2[,max(osize)]))
dev.off()


objs[,max(evictions)]

# correlation between size and hits
# correlation between 
