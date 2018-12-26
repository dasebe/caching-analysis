library(ggplot2)
library(data.table)
library(foreach)
ggplot <- function(...) { ggplot2::ggplot(...) + theme_bw() }


computeci <- function(x) {
    if(length(x)<2) return(0)
    t=try(t.test(x,conf.level=0.99), silent=TRUE)
    if (is(t, "try-error")) return(0) else return(t$estimate-t$conf.int[1])
}


# Exact MCF solution

ppath <- "~/LemonMCF/ntime"
ll <- list.files(path=ppath,pattern=".*rep.*")

tsizes <- c("w10k", "w50k","w100k","w200k","w500k","w750k","w1m","1.25m","w1.5m","w2m","w2.5m","w3m","w5m","w10m","w20m","w40m","w80m","w100m")

exact <- foreach(tsize=tsizes, .combine=rbind, .errorhandling='remove') %:%
    foreach(rep=1:10, .combine=rbind, .errorhandling='remove') %:%
    foreach(csize=c(26), .combine=rbind, .errorhandling='remove') %do% {
        fname <- paste(tsize,".tr__",csize,"_rep",rep,".log",sep="")
        print(paste(ppath,fname,sep="/"))
        tmp <- read.table(paste(ppath,fname,sep="/"))#,fill=TRUE)
        data.table(alg="MCF",tsize,csize,type=tmp$V4,n="",time=tmp$V1)
}

#exact[,time:=as.numeric(as.character(time))]
#exact <- exact[!is.na(time)]

exact[grepl("w.*m",tsize),tsize2:=as.numeric(gsub("w(.*)m","\\1",tsize))*1e6]
exact[grepl("w.*k",tsize),tsize2:=as.numeric(gsub("w(.*)k","\\1",tsize))*1e3]

exact[,list(m=round(mean(time)/60/60,1)),by=tsize2]


# offline lower bound

ppath <- "~/LemonMCFlns/ntime"
ll <- list.files(path=ppath,pattern="^lns[_|l].*")

ll[grepl("w10m",ll)]
fname="MAY_lnsubound_w10m.tr_100000_30.log"
fname="MAY_lnslbound_w10m.tr_100000_32.log"

ssizes <- c(5,40,100,2,20,500)

lbound <- foreach(size=ssizes, .combine=rbind, .errorhandling='remove') %do% {
    fnames <- ll[grepl(paste(size,".*_32.log",sep=""),ll)]
    foreach(fname=fnames, .combine=rbind, .errorhandling='remove') %do% {
#        print(paste(ppath,fname,sep="/"))
        tmp <- read.table(paste(ppath,fname,sep="/"))#,fill=TRUE)
        data.table(size,type=tmp$V4,n=tmp$V9,time=tmp$V1)
    }
}

lbound[,list(m=mean(time)),by=size]
lbound[,list(m=median(time)),by=size]




# localratio

ppath <- "~/LemonMCFlocalratio/ntime"
list.files(path=ppath,pattern="*.rep*.")

tsizes <- c("w10k", "w50k","w100k","w200k","w500k","w750k","w1m","1.25m","w1.5m","w2m","w2.5m","w3m","w5m","w10m")


lcr <- foreach(tsize=tsizes, .combine=rbind, .errorhandling='remove') %:%
    foreach(rep=1:10, .combine=rbind, .errorhandling='remove') %:%
    foreach(csize=c(26,30), .combine=rbind, .errorhandling='remove') %do% {
                                        #        fnames <- ll[grepl(paste(tsize,".*_",csize,".log",sep=""),ll)]
        fname <- paste("lrf10000_",tsize,".tr__",csize,"_rep",rep,".log",sep="")
        print(paste(ppath,fname,sep="/"))
        tmp <- read.table(paste(ppath,fname,sep="/"))#,fill=TRUE)
        data.table(alg="lcr",tsize,csize,type=tmp$V4,n="",time=tmp$V1)
}

lcr[grepl("w.*m",tsize),tsize2:=as.numeric(gsub("w(.*)m","\\1",tsize))*1e6]
lcr[grepl("w.*k",tsize),tsize2:=as.numeric(gsub("w(.*)k","\\1",tsize))*1e3]


lcr
lcr2 <- lcr[,list(mt=mean(time),ci=computeci(time)),by=list(alg,csize,tsize2)]
lcr2
lcr2[csize==26]








# ofma

ppath <- "~/LemonMCFofma/ntime"
list.files(path=ppath,pattern="^ofma.*rep.*")

tsizes <- c("w10k", "w50k","w100k","w200k","w500k","w1m","w1.5m","w2m","w2.5m","w3m","w5m","w10m","w20m","w32m")

ofma <- foreach(tsize=tsizes, .combine=rbind, .errorhandling='remove') %:%
    foreach(rep=1:10, .combine=rbind, .errorhandling='remove') %:%
    foreach(csize=c(26,30), .combine=rbind, .errorhandling='remove') %do% {
                                        #        fnames <- ll[grepl(paste(tsize,".*_",csize,".log",sep=""),ll)]
        fname <- paste("ofma_",tsize,".tr__",csize,"_rep",rep,".log",sep="")
        print(paste(ppath,fname,sep="/"))
        tmp <- read.table(paste(ppath,fname,sep="/"))#,fill=TRUE)
        data.table(alg="ofma",tsize,csize,type=tmp$V4,n="",time=tmp$V1)
}

ofma[grepl("w.*m",tsize),tsize2:=as.numeric(gsub("w(.*)m","\\1",tsize))*1e6]
ofma[grepl("w.*k",tsize),tsize2:=as.numeric(gsub("w(.*)k","\\1",tsize))*1e3]

ofma
ofma2 <- ofma[,list(mt=mean(time),ci=computeci(time)),by=list(alg,csize,tsize2)]
ofma2
ofma2[csize==26]






# belady

ppath <- "~/LemonMCFofma/ntime"
list.files(path=ppath,pattern="^belady.*rep.*")

tsizes <- c("w10k", "w50k","w100k","w200k","w500k","w1m","w1.5m","w2m","w2.5m","w3m","w5m","w10m","w20m")

belady <- foreach(tsize=tsizes, .combine=rbind, .errorhandling='remove') %:%
    foreach(rep=1:10, .combine=rbind, .errorhandling='remove') %:%
    foreach(csize=c(26,30), .combine=rbind, .errorhandling='remove') %do% {
                                        #        fnames <- ll[grepl(paste(tsize,".*_",csize,".log",sep=""),ll)]
        fname <- paste("belady_",tsize,".tr__",csize,"_rep",rep,".log",sep="")
        print(paste(ppath,fname,sep="/"))
        tmp <- read.table(paste(ppath,fname,sep="/"))#,fill=TRUE)
        data.table(alg="belady",tsize,csize,type=tmp$V4,n="",time=tmp$V1)
}

belady[grepl("w.*m",tsize),tsize2:=as.numeric(gsub("w(.*)m","\\1",tsize))*1e6]
belady[grepl("w.*k",tsize),tsize2:=as.numeric(gsub("w(.*)k","\\1",tsize))*1e3]


# SLP

slp <- data.table(read.table("timeSLP.table"))




# log log

dt3[,logt:=log10(tsize2/1e6)]
dt3[,logmt:=log10(mt)]

pdf("/tmp/plots/time_all.pdf",6,3)
ggplot(dt3,aes(logt,logmt,color=alg2,linetype=alg2))+
    geom_point(size=0.3,color="grey40")+
#    geom_errorbar(aes(ymin=logmt-log10(ci),ymax=logmt+log10(ci)),width=.2,size=0.7, color="grey40",linetype=1)+
    geom_line()+
    scale_colour_discrete("  Offline\n algorithm")+
    scale_linetype("  Offline\n algorithm")+
    scale_y_continuous("Time [hours]",expand=c(0.01,0))+
    scale_x_continuous("Trace length (millions of reqs)",expand=c(0,0))+
    theme(legend.key.width = unit(1.1, "cm"),
          legend.key.height = unit(0.43, "cm"))+
    theme(legend.text = element_text(size = rel(0.9)))+
    theme(axis.title.x = element_text(size = rel(1.05),vjust=-.1),axis.title.y = element_text(size = rel(1.05),vjust=1.2))#+
#    coord_cartesian(ylim=c(0,26))
dev.off()








### nu measurements

ppath <- "~/LemonMCFofma/ntime/"
ll <- list.files(path=ppath,pattern=".*time_.*")

i <- 200
fname <- ll[i]

mixed <- foreach(fname=ll, .combine=rbind, .errorhandling='remove') %do% {
    parts <- strsplit(fname,"_")
    type <- parts[[1]][1]
    size <- parts[[1]][5]
    csize <- parts[[1]][7]
    ffname <- paste(ppath,fname,sep="")
    print(ffname)
    tmp <- read.table(ffname)
    data.table(alg=type,tsize=size,csize,type=tmp$V4,n="",time=tmp$V1)
}

mixed[,tsize2:=gsub("k.tr","000",tsize)]
mixed[,tsize2:=gsub("m.tr","000000",tsize2)]
mixed[,tsize2:=as.numeric(tsize2)]

mixed[,list(m=mean(time)),by=list(tsize2,alg)]
mixedagg <- mixed[,list(m=max(time)),by=list(tsize2,alg)]
mixedagg <- mixed[,list(m=mean(time)),by=list(tsize2,alg)]
mixedagg <- mixed[,list(m=quantile(time,0.95)),by=list(tsize2,alg)]
mixedagg[m==0,m:=0.001]

m2 <- mixedagg[,list(alg,tsize2=(tsize2),m=(m))]


pdf("/tmp/plots/time_all_new.pdf",6,3)
ggplot(m2,aes(tsize2,m,color=alg,linetype=alg))+
    geom_point(size=0.3,color="grey40")+
#    geom_errorbar(aes(ymin=logmt-log10(ci),ymax=logmt+log10(ci)),width=.2,size=0.7, color="grey40",linetype=1)+
    geom_line()+
    scale_colour_discrete("  Offline\n algorithm")+
    scale_linetype("  Offline\n algorithm")+
    scale_y_continuous("Time [s]",expand=c(0.01,0))+
    scale_x_continuous("Trace length",expand=c(0,0))+
    theme(legend.key.width = unit(1.1, "cm"),
          legend.key.height = unit(0.43, "cm"))+
    theme(legend.text = element_text(size = rel(0.9)))+
    theme(axis.title.x = element_text(size = rel(1.05),vjust=-.1),axis.title.y = element_text(size = rel(1.05),vjust=1.2))#+
#    coord_cartesian(ylim=c(0,26))
dev.off()


m2 <- mixedagg[,list(alg,tsize2=log10(tsize2),m=log10(m))]

m2

logtbreaks <- c(-3:3)
logtlabels <- c("1ms","10ms","100ms","1s","10s","100s","1000s")

logsbreaks <- c(3:7)
logslabels <- c("1k","10k","100k","1m","10m")


pdf("/tmp/plots/time_all_new.pdf",6,3)
ggplot(m2,aes(tsize2,m,color=alg,linetype=alg))+
    geom_point(size=0.3,color="grey40")+
#    geom_errorbar(aes(ymin=logmt-log10(ci),ymax=logmt+log10(ci)),width=.2,size=0.7, color="grey40",linetype=1)+
    geom_line()+
    scale_colour_discrete("  Offline\n algorithm")+
    scale_linetype("  Offline\n algorithm")+
    scale_y_continuous("Time [s]",expand=c(0.01,0),breaks=logtbreaks,labels=logtlabels)+
    scale_x_continuous("Trace length",expand=c(0,0),breaks=logsbreaks,labels=logslabels)+
    theme(legend.key.width = unit(1.1, "cm"),
          legend.key.height = unit(0.43, "cm"))+
    theme(legend.text = element_text(size = rel(0.9)))+
    theme(axis.title.x = element_text(size = rel(1.05),vjust=-.1),axis.title.y = element_text(size = rel(1.05),vjust=1.2))#+
#    coord_cartesian(ylim=c(0,26))
dev.off()


mixed[,csize:=gsub(".log","",csize)]

setkey(mixed,alg,tsize2,csize)
mixed[grepl("local",alg),list(tsize2,csize,time)]

mixed[grepl("ofma",alg),list(tsize2,csize,time)]

mixed[grepl("util",alg),list(tsize2,csize,time)]

mixed[grepl("belad",alg),list(tsize2,csize,time)]









ppath <- "~/LemonMCFofma/ntime/"
ll <- list.files(path=ppath,pattern=".*time_.*")
mixed <- foreach(fname=ll, .combine=rbind, .errorhandling='remove') %do% {
    parts <- strsplit(fname,"_")
    type <- parts[[1]][1]
    size <- parts[[1]][5]
    csize <- parts[[1]][7]
    ffname <- paste(ppath,fname,sep="")
    print(ffname)
    tmp <- read.table(ffname)
    data.table(alg=type,tsize=size,csize,type=tmp$V4,n="",time=tmp$V1)
}
mixed[,tsize2:=gsub("k.tr","000",tsize)]
mixed[,tsize2:=gsub("m.tr","000000",tsize2)]
mixed[,tsize2:=as.numeric(tsize2)]
mcf <- mixed[alg=="mcftime",list(alg,tsize,csize=26,type,n,time,tsize2)]
lns <- mixed[alg=="lnstime",list(alg,tsize,csize=26,type,n,time,tsize2)]
fluid <- mixed[alg=="fluidtime",list(alg,tsize,csize=26,type,n,time,tsize2)]

# together
#
dt <- rbind(lcr,ofma,belady,slp,mcf,lns,fluid)
dt[,time2:=as.numeric(as.character(time))]
dt2 <- dt[!is.na(time2),list(mt=mean(time2/60/60),ci=computeci(time2/60/60)),by=list(alg,csize,tsize2)]
llbreaks=c("slp","lcr","ofma","mcftime","lnstime","fluidtime","belady")
llabels=c("LP","Localratio","OFMA","FOO","P-FOO (U)","P-FOO (L)","Belady")
dt2[,alg2:=factor(alg,levels=llbreaks,labels=llabels,ordered=TRUE)]
#
dtx <- dt2[,mean(mt),by=list(alg2,csize,tsize2)]
setkey(dtx,alg2,csize,tsize2)
dt3 <- dt2[csize==26]
#

pdf("/tmp/plots/time_all.pdf",4,2.5)
ggplot(dt3,aes(tsize2/1e6,mt,color=alg2,linetype=alg2,shape=alg2))+
    geom_point(size=1.5)+#,color="grey40")+
#    geom_errorbar(aes(ymin=mt-ci,ymax=mt+ci),width=.2,size=0.7, color="grey40",linetype=1)+
    geom_line()+
    scale_colour_discrete("")+
    scale_linetype("")+
    scale_shape("")+
    scale_y_continuous("Time [hours]",expand=c(0.01,0))+
    scale_x_continuous("Trace length (millions of reqs)",expand=c(0,0))+
    theme(legend.key.width = unit(0.5, "cm"),
          legend.key.height = unit(0.28, "cm"),
          plot.margin = unit(c(1.7, 0.8, 0.4, 0.4), "lines"))+  # changed
    theme(legend.position = c(.3,.9))+
    theme(legend.text = element_text(size = rel(1.1)))+ ## changed
    theme(axis.title.x = element_text(size = rel(1.1),vjust=-.1),axis.title.y = element_text(size = rel(1.1),vjust=1.2))+
        theme(legend.background = element_rect(fill="transparent"))+
    coord_cartesian(ylim=c(0,25),xlim=c(0,32.5))
dev.off()


    
