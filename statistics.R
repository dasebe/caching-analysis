library(ggplot2)
library(data.table)
library(foreach)
library(scales)
library(RColorBrewer)

ggplot <- function(...) { ggplot2::ggplot(...) + theme_bw() }

options(width=Sys.getenv("COLUMNS"))

trace <- traces[1]
trace <- "CDN 1"
traces <- trace
fname <- "../sw10m.tr"
tmp <- data.table(read.table(fname))
stats <- tmp[,list(trace,type=V1,val=V3,res=V4)]
llbreaks=traces
llabels <- traces




traces <- c("sm100m","sw100m")
traces <- c("s2h100m","s2m100m","s2w100m")

stats <- foreach(trace=traces, .combine=rbind, .errorhandling='remove') %do% {
        fname <- paste("../",trace,".tr",sep="")
        print(fname)
        tmp <- data.table(read.table(fname))
        tmp[,list(trace,type=V1,val=V3,res=V4)]
}

stats[,unique(trace)]

llbreaks=traces
llabels <- traces

stats <- stats[trace %in% llbreaks]
stats[,trace2:=factor(trace,levels=llbreaks,labels=llabels,ordered=TRUE)]

stats.rd <- stats[type=="rd"]
maxrd <- stats.rd[,max(val)]
stats.rd[val< 0,val:=maxrd+1]
stats.rd[,prob:=res/sum(res),by=list(trace)]
maxprob <- stats.rd[val<=maxrd,max(prob)]

stats.rd[,linrd:=10^val]

stats.rd[,w:=res/sum(res),by=trace2]
setkey(stats.rd,trace2,val)
stats.rd[,ecdf:=cumsum(w),by=trace2]

stats.rd[grepl("proj",trace)]

stats.rd

pl <- ggplot(stats.rd,aes(val,ecdf,color=trace2,linetype=trace2))+
        geom_line(size=0.5)+
#        geom_point(size=1.8)+
    scale_color_manual("",values=c(rep("#1b9e77",3),rep("#d95f02",2),rep("#7570b3",3)))+
    scale_linetype_manual("",values=1:10)+
#    scale_size_manual("",values=c(0.5,0.5,0.5,0.9,0.9,0.5))+
    scale_y_continuous("Cumulative Request Probability",expand=c(0,0))+
    scale_x_continuous("Reuse Distance",expand=c(0,0),breaks=seq(0,10,by=2),labels=10^(seq(0,10,by=2)))+
    theme(legend.key.width = unit(0.5, "cm"),
          legend.key.height = unit(0.26, "cm"),
          plot.margin = unit(c(0.2, 0.9, 0.4, 0.4), "lines"))+  # changed
    theme(legend.position = "top")+ #c(0.3,0.86)
    theme(legend.text = element_text(size = rel(.91)))+ ## changed
    theme(axis.title.x = element_text(size = rel(1.1),vjust=-.1),axis.title.y = element_text(size = rel(1.1),vjust=1.2))+
        theme(legend.background = element_rect(fill="transparent"))+
    coord_cartesian(xlim=c(0,maxrd),ylim=c(0,1))


    oname <- paste("/tmp/plots/statistics_rd.pdf",sep="")
#pdf(oname,2.9,3.5) ## changed
    pdf(oname,6,5) ## changed
    print(pl)
    dev.off()



## non cumulative rd plot (density)

stats.rd2 <- stats.rd[val!=maxrd+1]

pl <- ggplot(stats.rd2,aes(val,prob,color=trace2))+  #,linetype=trace2
        geom_line(size=0.5)+
#        geom_point(size=1.8)+
    scale_color_brewer("",palette="Set1")+
#    scale_linetype_manual("",values=1:10)+
#    scale_size_manual("",values=c(0.5,0.5,0.5,0.9,0.9,0.5))+
    scale_y_continuous("Request Probability",expand=c(0,0))+
    scale_x_continuous("Reuse Distance",expand=c(0,0),breaks=seq(0,10,by=2),labels=10^(seq(0,10,by=2)))+
    theme(legend.key.width = unit(0.5, "cm"),
          legend.key.height = unit(0.26, "cm"),
          plot.margin = unit(c(0.2, 0.9, 0.4, 0.4), "lines"))+  # changed
    theme(legend.position = "top")+ #c(0.3,0.86)
    theme(legend.text = element_text(size = rel(.91)))+ ## changed
    theme(axis.title.x = element_text(size = rel(1.1),vjust=-.1),axis.title.y = element_text(size = rel(1.1),vjust=1.2))+
        theme(legend.background = element_rect(fill="transparent"))+
    coord_cartesian(xlim=c(0,maxrd))

    oname <- paste("/tmp/plots/statistics_rd_density.pdf",sep="")
#pdf(oname,2.9,3.5) ## changed
    pdf(oname,6,5) ## changed
    print(pl)
    dev.off()





## popularity

stats[,unique(type)]
stats.zipf <- stats[type=="zipf"]

stats.zipf[,sum(res),by=trace2]

pl <- ggplot(stats.zipf,aes(log10(val),log10(res),color=trace2,linetype=trace2))+
        geom_line(size=0.5)+
#        geom_point(size=1.8)+
    scale_color_manual("",values=c(rep("#1b9e77",3),rep("#d95f02",2),rep("#7570b3",3)))+
    scale_linetype_manual("",values=1:10)+
#    scale_size_manual("",values=c(0.5,0.5,0.5,0.9,0.9,0.5))+
    scale_y_continuous("Request Count",expand=c(0,0),breaks=seq(0,10,by=2),labels=10^(seq(0,10,by=2)))+
    scale_x_continuous("i-th Most Popular Object    ",expand=c(0,0),breaks=seq(0,10,by=2),labels=10^(seq(0,10,by=2)))+
    theme(legend.key.width = unit(0.5, "cm"),
          legend.key.height = unit(0.26, "cm"),
          plot.margin = unit(c(0.2, 0.9, 0.4, 0.4), "lines"))+  # changed
    theme(legend.position = "top")+ #c(0.60,0.91)
    theme(legend.text = element_text(size = rel(.91)))+ ## changed
    theme(axis.title.x = element_text(size = rel(1.1),vjust=-.1),axis.title.y = element_text(size = rel(1.1),vjust=1.2))+
        theme(legend.background = element_rect(fill="transparent"))

    oname <- paste("/tmp/plots/statistics_zipf.pdf",sep="")
    pdf(oname,6,5) ## changed
    print(pl)
    dev.off()





## REQUEST SIZE DISTRIBUTION


stats.size <- stats[type=="size"]

stats.size[,w:=res/sum(res),by=trace2]
setkey(stats.size,trace2,val)
stats.size[,ecdf:=cumsum(w),by=trace2]

msbreaks <- c(0,1,10,11,20,21,30,31,40)
slabels <- c("1B","2B","1KB","2KB","1MB","2MB","1GB","2GB","1TB")

msbreaks <- c(0,10,20,30,40)
slabels <- c("1B","1KB","1MB","1GB","1TB")

stats.size[,rsize:=10^val]

pl <- ggplot(stats.size,aes(rsize,ecdf,color=trace2,linetype=trace2))+
        geom_line(size=0.5)+
#        geom_point(size=1.8)+
    scale_color_manual("",values=c(rep("#1b9e77",3),rep("#d95f02",2),rep("#7570b3",3)))+
    scale_linetype_manual("",values=1:10)+
#    scale_size_manual("",values=c(0.5,0.5,0.5,0.9,0.9,0.5))+
    scale_y_continuous("Cumulative Distribution  ",expand=c(0,0))+
    scale_x_log10("Object Size",expand=c(0,0),breaks=2^msbreaks,labels=slabels)+
    theme(legend.key.width = unit(0.3, "cm"),
          legend.key.height = unit(0.3, "cm"),
          plot.margin = unit(c(0.2, 0.9, 0.4, 0.4), "lines"))+  # changed
    theme(legend.position = "top")+ #c(0.71,0.22)
    theme(legend.text = element_text(size = rel(.91)))+ ## changed
    theme(axis.title.x = element_text(size = rel(1.1),vjust=-.1),axis.title.y = element_text(size = rel(1.1),vjust=1.2))+
        theme(legend.background = element_rect(fill="transparent"))

    oname <- paste("/tmp/plots/statistics_size.pdf",sep="")
    pdf(oname,6,5) ## changed
    print(pl)
    dev.off()

    oname <- paste("/tmp/plots/statistics_size.pdf",sep="")
    pdf(oname,8,4) ## changed
    print(pl)
    dev.off()




## OBJECT SIZE DISTRIBUTION


### size uniq

stats.uniqsize <- stats[type=="uniqsize"]

stats.uniqsize[val>8,sum(res)]
stats.size[val>8,sum(res)]

stats.uniqsize[,w:=res/sum(res),by=trace2]
setkey(stats.uniqsize,trace2,val)
stats.uniqsize[,ecdf:=cumsum(w),by=trace2]

msbreaks <- c(0,10,20,30,40)
slabels <- c("1B","1KB","1MB","1GB","1TB")

stats.uniqsize[,rsize:=10^val]

#stats.uniqsize2 <- stats.uniqsize[!grepl("msr",trace) & !grepl("memcach",trace) & !grepl("trace.json",trace)]
stats.uniqsize2 <- stats.uniqsize

pl <- ggplot(stats.uniqsize2,aes(rsize,ecdf,color=trace2,linetype=trace2))+
        geom_line(size=0.5)+
#        geom_point(size=1.8)+
    scale_color_manual("",values=c(rep("#1b9e77",3),rep("#d95f02",2),rep("#7570b3",3)))+
    scale_linetype_manual("",values=1:10)+
#    scale_size_manual("",values=c(0.5,0.5,0.5,0.9,0.9,0.5))+
    scale_y_continuous("Cumulative Distribution  ",expand=c(0,0))+
    scale_x_log10("Object Size",expand=c(0,0),breaks=2^msbreaks,labels=slabels)+
    theme(legend.key.width = unit(0.3, "cm"),
          legend.key.height = unit(0.3, "cm"),
          plot.margin = unit(c(0.2, 0.9, 0.4, 0.4), "lines"))+  # changed
    theme(legend.position = "top")+ #c(0.71,0.22)
    theme(legend.text = element_text(size = rel(.91)))+ ## changed
    theme(axis.title.x = element_text(size = rel(1.1),vjust=-.1),axis.title.y = element_text(size = rel(1.1),vjust=1.2))+
        theme(legend.background = element_rect(fill="transparent"))

    oname <- paste("/tmp/plots/statistics_size.pdf",sep="")
    pdf(oname,2.9,3.5) ## changed
    print(pl)
    dev.off()

    oname <- paste("/tmp/plots/statistics_uniqsize.pdf",sep="")
    pdf(oname,8,4) ## changed
    print(pl)
    dev.off()



### correlation

stats.p = data.table(read.table("~/webcachesim-optlearn/pearson.log"))
stats.p = data.table(read.table("~/webcachesim-optlearn/pearson3.log"))

stats.p[,trace:=gsub(".*/","",V1)]
stats.p[,V1:=NULL]

stats.p[,pval:=V11]
stats.p[,V11:=NULL]


setnames(stats.p,"V2","init")
setnames(stats.p,"V3","interval")
setnames(stats.p,"V4","reps")
setnames(stats.p,"V5","objCount")

setkey(stats.p,trace,init,interval,reps,objCount,pval)
stats.p[,w:=1/length(pval),by=list(trace,init,interval,reps,objCount)]

stats.p2 <- stats.p[,list(ws=sum(w)),by=list(trace,init,interval,reps,objCount,pval=round(pval,4))]

stats.p2[,ecdf:=cumsum(ws),by=list(trace,init,interval,reps,objCount)]
stats.p2[grepl("memcachier",trace),trace:=llbreaks[5]]

stats.p2[,trace2:=factor(trace,levels=llbreaks,labels=llabels,ordered=TRUE)]

stats.p2 <- stats.p2[!is.na(trace2)]

for(int in stats.p[,unique(interval)]) {
    for(re in stats.p[,unique(reps)]) {
        for(ob in stats.p[,unique(objCount)]) {
            tmp <- stats.p2[interval==int & reps == re & objCount == ob]
#
            pl <- ggplot(tmp,aes(pval,ecdf,color=trace2,linetype=trace2))+
                geom_line(size=0.5)+
                scale_color_manual("",values=c(rep("#1b9e77",3),rep("#d95f02",2),rep("#7570b3",3)))+
                scale_linetype_manual("",values=1:10)+
                scale_y_continuous("Cumulative Distribution  ",expand=c(0,0))+
                scale_x_continuous("Correlation Coefficient",expand=c(0,0))+
                theme(legend.key.width = unit(0.6, "cm"),
                      legend.key.height = unit(0.3, "cm"),
                      plot.margin = unit(c(0.2, 0.9, 0.4, 0.4), "lines"))+  # changed
                theme(legend.position = "top")+ #c(0.21,0.72)
                theme(legend.text = element_text(size = rel(.91)))+ ## changed
                theme(axis.title.x = element_text(size = rel(1.1),vjust=-.1),axis.title.y = element_text(size = rel(1.1),vjust=1.2))+
                theme(legend.background = element_rect(fill="transparent"))+
                coord_cartesian(xlim=c(-1,1),ylim=c(0,1))
#
            oname <- paste("/tmp/plots/pearson/pearson",int,"_",re,"_",ob,".pdf",sep="")
            print(oname)
            pdf(oname,2.9,3.5) ## changed
            print(pl)
            dev.off()
        }
    }
}




#### bla

stats[,unique(type)]
stats[type=="zipf"]
stats[type=="pop"]
