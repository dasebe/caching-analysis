library(ggplot2)
library(data.table)
library(foreach)
library(scales)
library(RColorBrewer)

ggplot <- function(...) { ggplot2::ggplot(...) + theme_bw() }

options(width=Sys.getenv("COLUMNS"))


#dvars

# offline lower bound

#2 msr_proj_1.tr 24 36 .83 .67 Storage_Proj1


x <-"
trace lr ur lx ly type tname
1 msr_proj_0.tr 24 34 .7 .23 Storage Proj0
3 msr_proj_2.tr 28 40 .7 .67 Storage Proj2
4 msr_src1_0.tr 28 38 .3 .65 Storage Src1
5 w100m.tr 28 41 .7 .23 CDN smallSF
6 traceUS100m.tr 28 42 .7 .23 CDN largeUS
7 traceHK100m.tr 28 42 .7 .23 CDN largeHK
"            
traceprops <- data.table(read.table(textConnection(x)))

traces <- traceprops$trace
logsizes <- 20:42

lbound1 <- foreach(trace=traces, .combine=rbind, .errorhandling='remove') %:%
    foreach(acc=c("500000","450000","1000000","2000000"), .combine=rbind, .errorhandling='remove') %:%
    foreach(logsize=logsizes, .combine=rbind, .errorhandling='remove') %do% {
        fname <- paste("~/LemonMCFlns/nsolution/sol_lnslbound_",trace,"_",acc,"_",logsize,".log",sep="")
        tmp <- data.table(read.table(fname))
        tmp2 <- last(tmp)
        data.table(type="lbound",trace,logsize,h=tmp2$V14,r=tmp2$V16)
}

#LM
lbound2 <- foreach(trace=traces, .combine=rbind, .errorhandling='remove') %:%
    foreach(acc=c("500000","450000","800000","1000000","2000000"), .combine=rbind, .errorhandling='remove') %:%
    foreach(logsize=logsizes, .combine=rbind, .errorhandling='remove') %do% { 
        fname <- paste("~/LemonMCFlns/nsolution/sol_lnslboundLM_",trace,"_",acc,"_",logsize,".log",sep="")
        tmp <- data.table(read.table(fname))
        tmp2 <- last(tmp)
        data.table(type="lbound",trace,logsize,h=tmp2$V14,r=tmp2$V16)
}

#LM cpy
lboundcpy <- foreach(trace=traces, .combine=rbind, .errorhandling='remove') %:%
    foreach(acc=c("500000","450000","1000000","2000000"), .combine=rbind, .errorhandling='remove') %:%
    foreach(logsize=logsizes, .combine=rbind, .errorhandling='remove') %do% { 
        fname <- paste("~/LemonMCFlns/nsolution/sol_lnslboundLM_",trace,"_",acc,"_",logsize,".log_cpy",sep="")
        tmp <- data.table(read.table(fname))
        tmp2 <- last(tmp)
        data.table(type="lbound",trace,logsize,h=tmp2$V14,r=tmp2$V16)
}

#LM cpy MSR
lboundcpy2 <- foreach(trace=traces, .combine=rbind, .errorhandling='remove') %:%
    foreach(acc=c("500000","450000","800000","1000000","2000000"), .combine=rbind, .errorhandling='remove') %:%
    foreach(logsize=logsizes, .combine=rbind, .errorhandling='remove') %do% { 
        fname <- paste("~/LemonMCFlns/nsolution/sol_lnslboundLM_",trace,"_",acc,"_",logsize,".logf_cpy",sep="")
        print(fname)
        tmp <- data.table(read.table(fname))
        tmp2 <- last(tmp)
        data.table(type="lbound",trace,logsize,h=tmp2$V14,r=tmp2$V16)
}


# gcd

errorhandler <- "remove"

basepath <- "~/gcd/nsolutiong/"
servercount <- 30

lboundgcd <- foreach(server=0:servercount, .combine=rbind, .errorhandling=errorhandler) %:%
    foreach(trace=traces, .combine=rbind, .errorhandling=errorhandler) %:%
    foreach(acc=c("500000","1000000","2000000"), .combine=rbind, .errorhandling=errorhandler) %:%
    foreach(method=c("lnslbound","lnslboundLM","linearlns","linearlns3"), .combine=rbind, .errorhandling=errorhandler) %:%
    foreach(format=c(".log",".log_cpy"), .combine=rbind, .errorhandling=errorhandler) %:%
    foreach(logsize=logsizes, .combine=rbind, .errorhandling=errorhandler) %do% {
        fname <- paste(basepath,server,"/sol_",method,"_",trace,"_",acc,"_",logsize,format,sep="")
        if(file.exists(fname)){
            print(fname)
            tmp <- data.table(read.table(fname))
            tmp2 <- last(tmp)
            data.table(type="lbound",trace,logsize,h=tmp2$V14,r=tmp2$V16)
        }
}


#lbound <- rbind(lbound1,lbound2,fast)
lboundall <- rbind(lbound1,lbound2,lboundcpy,lboundcpy2,lboundgcd)

lboundall <- lboundall[!is.na(h)]

lboundall[grep("100m",trace),r:=1e8]
lboundall[grep("500m",trace),r:=5e8]

lboundall2 <- lboundall[,list(h=max(h),r=max(r)),by=list(type,trace,logsize)]

# if ever goes downwards, skip this datapoint
setkey(lboundall2,trace,logsize)

lboundall2[,dd:=c(1,diff(h)),by=trace]
lboundall2 <- lboundall2[dd>0]
lboundall2[,dd:=NULL]


lboundall2[grepl("src1",trace)]



# fluid model
fluid <- foreach(trace=traces, .combine=rbind, .errorhandling='remove') %do% {
    fname <- paste("~/LemonMCFlns/nsolution/sol_fluidupper2_",trace,".log",sep="")
    print(fname)
    tmp <- data.table(read.table(fname))
    tmp[,list(type=V1,trace,logsize=log2(V2),h=V3,r=V4)]
}

#fluid2 <- foreach(trace=traces, .combine=rbind, .errorhandling='remove') %do% {
#    fname <- paste("~/LemonMCFlns/nsolution/sol_fluid_",trace,".log",sep="")
#    print(fname)
#    tmp <- data.table(read.table(fname))
#    tmp[,list(type=V1,trace,logsize=log2(V2),h=V3,r=V4)]
#}


allfluid <- fluid #rbind(fluid,fluid2)


# backward/forward
trace <- traces[1]
logsize <- logsizes[9]

belady <- foreach(trace=traces, .combine=rbind, .errorhandling='remove') %:%
    foreach(logsize=logsizes, .combine=rbind, .errorhandling='remove') %do% {
        tmp <- data.table(read.table(paste("~/LemonMCFofma/nsolution/sol_belady2_",trace,"_100_",logsize,".log",sep="")))
        dt1 <- tmp[,list(type=V1,trace=trace,logsize,h=V5,r=V7)]
        tmp <- data.table(read.table(paste("~/LemonMCFofma/nsolution/sol_belady2size_",trace,"_100_",logsize,".log",sep="")))
        dt2 <- tmp[,list(type=V1,trace=trace,logsize,h=V5,r=V7)]
        tmp <- data.table(read.table(paste("~/LemonMCFofma/nsolution/sol_belady2sizefrequency_",trace,"_100_",logsize,".log",sep="")))
        dt3 <- tmp[,list(type=V1,trace=trace,logsize,h=V5,r=V7)]
        rbind(dt1,dt2,dt3)
    }

belady2 <- belady[!grepl("Backward",type)]



# utility

util <- foreach(trace=traces, .combine=rbind, .errorhandling='remove') %do% {
    fname <- paste("~/LemonMCFofma/nsolution/sol_utilityknapsack_",trace,".log",sep="")
    print(fname)
    tmp <- data.table(read.table(fname))
    rbind(
        tmp[V1!=-1,list(type="util",trace,logsize=log2(V1),h=V2,r=V3)],
        tmp[V1==-1,list(type="inf",trace,logsize=1:50,h=V2,r=V3)]
        )
}


# webcachesim results

pname <- "~/webcachesim/nsolution/"

t <- list.files(path=pname,pattern=paste("^sol_.*",trace,sep=""))
fname=t[grepl("GD",t)][1]

sims <- foreach(trace=traces, .combine=rbind, .errorhandling='remove') %:%
    foreach(fname=
                list.files(path=pname,pattern=paste("^sol_.*",trace,sep=""))
          , .combine=rbind) %do% {
              tmp <- data.table(read.table(paste(pname,fname,sep="")))
              if(length(colnames(tmp))==5) {
                  tmp[,list(type=V1,trace,logsize=log2(V2),h=V4,r=V3)]
              } else {
                  tmp[,list(type=V1,trace,logsize=log2(V2),h=V5,r=V4)]
              }
}

#sims[grepl("LRUS([5-9]|1[0-9])$",type) & trace=="traceUS100m.tr" & logsize==30]
#sims <- sims[!grepl("LRUS([0-9]|1[0-9])$",type)]
#sims <- sims[!grepl("LRUS$",type)]
sims[,unique(type)]

sims[,type2:=gsub("[0-9.]","",type)]
sims2 <- sims[,list(h=max(h)),by=list(type=type2,trace,logsize,r)]



#plots

getPalette = colorRampPalette(brewer.pal(8, "Set1"))

bbreaks <- c(22,24,26,28,30,32,34,36,38,40,42)
blabels <- c("       4MB","16MB","64MB","       256MB","1GB","4GB","16GB","64GB","256GB","1TB","4TB   ")

bbreaks <- c(24,28,32,36,40)
blabels <- c("16MB","256MB","4GB","64GB","1TB")

bbreaks <- c(24,27,30,33,36,39)
blabels <- c("16MB","128MB","1GB","8GB","128GB","512GB")



# opt vs belady

dt <- rbind(lboundall2,allfluid)
dt <- rbind(lboundall2,fluid,belady2,util)
dt <- dt[!is.na(r)]
dt[,r:=max(r),by=trace]

dt[,unique(trace)]
dt[,unique(type)]

llbreaks=c("inf","fluid2","lbound","FW-Volume","Belady2SizeFrequencyForward","Belady2SizeForward","Belady2SizeFrequencyBackward","Belady2SizeBackward","GDSF","GDS","Filter","ExpLRU","Belady2Forward","SLRU","Belady2Backward","LRUS","LRUK","LFUDA","LRU")
llabels=c("Infinite Capacity","OPT fluid bound","OPT lower bound","Fw-Volume","Fw-FreqSize","Fw-RecSize","Bw-FreqSize","Bw-RecSize","GDSF","GDS","Bloom","AdaptSize","Fw-Recency","SLRU","Bw-Recency","LRU-S","LRU-K","LFU-DA","LRU")

llbreaks=c("inf","fluid2","lbound","FW-Volume","Belady2SizeForward","util","Belady2Forward")
llabels=c("Inf Capacity (u)","P-FOO (u)","P-FOO (l)","Fw-Volume (l)","Belady-Size (l)","Freq-Size (l)","Belady (l)")


dt2 <- dt[type %in% llbreaks]
dt2[,type2:=factor(type,levels=llbreaks,labels=llabels,ordered=TRUE)]

ttypes <- dt2[,unique(type2)]

for(i in 1:nrow(traceprops)) {
    rw <- traceprops[i]
    tr <- rw$trace
    print(tr)
    lrange <- rw$lr
    rrange <- rw$ur
    dt3 <- dt2[trace==tr & logsize>=lrange & logsize<=rrange]
    lx <- rw$lx
    ly <- rw$ly
    pl <- ggplot(dt3,aes(logsize,h/r,color=type2,shape=type2))+
        geom_line(size=0.5)+
        geom_point(size=1.2)+
    scale_color_manual("",values = c("#6852C1","#888888","#444444",getPalette(length(ttypes)-3)))+
    scale_shape_manual("",values=1:20)+
    scale_y_continuous("Object Hit Ratio",expand=c(0,0))+
    scale_x_continuous("Cache Size",expand=c(0,0),breaks=bbreaks,labels=blabels)+
    theme(legend.key.width = unit(0.5, "cm"),
          legend.key.height = unit(0.28, "cm"))+
    theme(legend.position = c(lx,ly))+
    theme(legend.text = element_text(size = rel(0.8)))+
    theme(axis.title.x = element_text(size = rel(1.1),vjust=-.1),axis.title.y = element_text(size = rel(1.1),vjust=1.2))+
        theme(legend.background = element_rect(fill="transparent"))+
    coord_cartesian(xlim=c(lrange,rrange),ylim=c(0,1.0))
#
    oname <- paste("/tmp/plots/opt_belady_",tr,".pdf",sep="")
    pdf(oname,3,2.6)
    print(pl)
    dev.off()
}


# opt vs sims

dt <- rbind(lboundall2,fluid,sims2)
dt[,r:=max(r),by=trace]

dt[,unique(type)]

llbreaks=c("fluid","lbound","FW-Volume","Belady2SizeFrequencyForward","Belady2SizeForward","Belady2SizeFrequencyBackward","Belady2SizeBackward","GDSF","GDS","Filter","ExpLRU","Belady2Forward","SLRU","Belady2Backward","LRUS","LRUK","LFUDA","LRU")
llabels=c("OPT fluid bound","OPT lower bound","Fw-Volume","Fw-FreqSize","Fw-RecSize","Bw-FreqSize","Bw-RecSize","GDSF","GDS","Bloom","AdaptSize","Fw-Recency","SLRU","Bw-Recency","LRU-S","LRU-K","LFU-DA","LRU")

llbreaks=c("fluid2","lbound","GDSF","GDS","ExpLRU","SLRU","LRUK","LRU")
llabels=c("P-FOO (upper)","P-FOO (lower)","GDSF","GDS","AdaptSize","SLRU","LRU-K","LRU")

dt2 <- dt[type %in% llbreaks]
dt2[,type2:=factor(type,levels=llbreaks,labels=llabels,ordered=TRUE)]

ttypes <- dt2[,unique(type2)]

dt2[,unique(type2)]

for(i in 1:nrow(traceprops)) {
    rw <- traceprops[i]
    tr <- rw$trace
    lrange <- rw$lr
    rrange <- rw$ur
    dt3 <- dt2[trace==tr & logsize>=lrange & logsize<=rrange]
    lx <- rw$lx
    ly <- rw$ly
    pl <- ggplot(dt3,aes(logsize,h/r,color=type2,shape=type2))+
        geom_line(size=0.5)+
        geom_point(size=1.2)+
    scale_color_manual("",values = c("#888888","#444444",getPalette(length(ttypes)-2)))+
    scale_shape_manual("",values=1:20)+
    scale_y_continuous("Object Hit Ratio",expand=c(0,0))+
    scale_x_continuous("Cache Size",expand=c(0,0),breaks=bbreaks,labels=blabels)+
    theme(legend.key.width = unit(0.5, "cm"),
          legend.key.height = unit(0.28, "cm"))+
    theme(legend.position = c(lx,ly))+
    theme(legend.text = element_text(size = rel(0.8)))+
    theme(axis.title.x = element_text(size = rel(1.1),vjust=-.1),axis.title.y = element_text(size = rel(1.1),vjust=1.2))+
        theme(legend.background = element_rect(fill="transparent"))+
    coord_cartesian(xlim=c(lrange,rrange),ylim=c(0,1.0))
#
    oname <- paste("/tmp/plots/opt_sims_",tr,".pdf",sep="")
    pdf(oname,3,2.6)
    print(pl)
    dev.off()
}


######### outdated
# opt vs online vs stuff

dt <- rbind(lboundall2,fluid,sims2,belady2)
dt[,r:=max(r),by=trace]

dt[,unique(type)]

llbreaks=c("fluid","lbound","Belady2SizeFrequencyForward","Belady2SizeFrequencyBackward","GDSF","ExpLRU","Belady2Forward","LRU")
llabels=c("OPT fluid bound","OPT lower bound","Fw-FreqSize","Bw-FreqSize","GDSF","AdaptSize","Fw-Recency","LRU")

dt2 <- dt[type %in% llbreaks]
dt2[,type2:=factor(type,levels=llbreaks,labels=llabels,ordered=TRUE)]

ttypes <- dt2[,unique(type2)]

for(i in 1:nrow(traceprops)) {
    rw <- traceprops[i]
    tr <- rw$trace
    lrange <- rw$lr
    rrange <- rw$ur
    dt3 <- dt2[trace==tr & logsize>=lrange & logsize<=rrange]
    lx <- rw$lx
    ly <- rw$ly
    pl <- ggplot(dt3,aes(logsize,h/r,color=type2,shape=type2))+
        geom_line(size=0.5)+
        geom_point(size=1.2)+
    scale_color_manual("",values = getPalette(length(ttypes)))+
    scale_shape_manual("",values=1:20)+
    scale_y_continuous("Object Hit Ratio",expand=c(0,0))+
    scale_x_continuous("Cache Size",expand=c(0,0),breaks=bbreaks,labels=blabels)+
    theme(legend.key.width = unit(1.1, "cm"),
          legend.key.height = unit(0.43, "cm"))+
    coord_cartesian(xlim=c(lrange,rrange),ylim=c(0,1.0))
    theme(legend.text = element_text(size = rel(0.9)))+
    theme(axis.title.x = element_text(size = rel(1.05),vjust=-.1),axis.title.y = element_text(size = rel(1.05),vjust=1.2))+
    coord_cartesian(xlim=c(lrange,rrange),ylim=c(0,1.0))
#
    oname <- paste("/tmp/plots/opt_belsims_",tr,".pdf",sep="")
    pdf(oname,8,5)
    print(pl)
    dev.off()
}



# approximation error

dt <- rbind(lboundall2,fluid)

dt[,ohr:=h/r]

dt2 <- dt[,list(maxo=max(ohr),mino=min(ohr)), by=list(trace,logsize)]

dt2[,err:=(maxo-mino)/mino]
dt2[,mean(err),by=trace]

getPalette <- colorRampPalette(brewer.pal(9, "Set1"))

for(tr in traces) {
    dt3 <- dt2[trace==tr]
#
    pl <- ggplot(dt3,aes(logsize,err*100))+
        geom_line(size=0.5)+
        geom_point(size=1.2)+
    scale_y_continuous("Approximation Error [%]",expand=c(0,0))+
    scale_x_continuous("Cache Size",expand=c(0,0),breaks=bbreaks,labels=blabels)+
    theme(legend.key.width = unit(1.1, "cm"),
          legend.key.height = unit(0.43, "cm"))+
    theme(legend.position = c(.73,0.25))+
    theme(legend.text = element_text(size = rel(0.9)))+
    theme(axis.title.x = element_text(size = rel(1.05),vjust=-.1),axis.title.y = element_text(size = rel(1.05),vjust=1.2))+
#    coord_cartesian(xlim=c(20,42))
    coord_cartesian(xlim=c(28,42),ylim=c(0,3.0))
#
    oname <- paste("/tmp/plots/opt_error_",tr,".pdf",sep="")
    pdf(oname,8,5)
    print(pl)
    dev.off()
}

a








# backward/forward
trace <- traces[1]
logsize <- logsizes[9]

belady <- foreach(trace=traces, .combine=rbind, .errorhandling='remove') %:%
    foreach(sample=c(100,500,1000,2000,2001,4001,8001,16001), .combine=rbind, .errorhandling='remove') %:%
    foreach(logsize=logsizes, .combine=rbind, .errorhandling='remove') %do% {
#        print(paste("~/LemonMCFofma/nsolution/sol_belady2size_",trace,"_",sample,"_",logsize,".log",sep=""))
        tmp <- data.table(read.table(paste("~/LemonMCFofma/nsolution/sol_belady2size_",trace,"_",sample,"_",logsize,".log",sep="")))
        dt2 <- tmp[,list(type=V1,trace=trace,sample,logsize,h=V5,r=V7)]
        tmp <- data.table(read.table(paste("~/LemonMCFofma/nsolution/sol_belady2_",trace,"_",sample,"_",logsize,".log",sep="")))
        dt1 <- tmp[,list(type=V1,trace=trace,sample,logsize,h=V5,r=V7)]
        tmp <- data.table(read.table(paste("~/LemonMCFofma/nsolution/sol_belady2sizefrequency_",trace,"_",sample,"_",logsize,".log",sep="")))
        dt3 <- tmp[,list(type=V1,trace=trace,sample,logsize,h=V5,r=V7)]
        rbind(dt1,dt2,dt3)
    }

belady[trace=="traceUS100m.tr" & logsize==30 & type=="Belady2SizeForward"]
belady[trace=="traceUS100m.tr" & logsize==31 & type=="Belady2SizeForward"]
belady[trace=="traceHK100m.tr" & logsize==31 & type=="Belady2SizeForward"]
belady[trace=="memcachier100m.tr"]

belady2 <- belady[!grepl("Backward",type)]


tracesfast <- c("w100m", "traceUS100m","traceHK100m")
trace="w100m"
logsize=30

fast <- foreach(trace=tracesfast, .combine=rbind, .errorhandling='remove') %:%
    foreach(logsize=c(30,31), .combine=rbind, .errorhandling='remove') %do% { 
        fname <- paste("~/LemonMCFlns/nsolution/sol_lboundfast_",trace,"_",logsize,".log",sep="")
        print(fname)
        tmp <- data.table(read.table(fname,skip=0))
        tmp2 <- last(tmp)
        tmp2[,list(type="FW-Volume",trace=paste(trace,"tr",sep="."),sample=0,logsize,h=V3,r=V4)]
}

fast[trace=="w100m.tr"]
fast[trace=="traceHK100m.tr"]

tmp1 <- lboundall2
tmp1[,sample:=0]
tmp2 <- sims2
tmp2[,sample:=0]
fluid[,sample:=0]
dt <- rbind(belady,fast,lboundall2,sims2,fluid)

tr="w100m.tr"
tr="traceUS100m.tr"
tr="traceHK100m.tr"
tr="w100m.tr"

for(tr in traces) {

    dt2 <- dt[trace==tr]
    dt2[,tt:=paste(type,sample)]
    dt2[,unique(tt)]

#    llbreaks=c("fluid 0","lbound 0","FW-Volume 0",paste("Belady2SizeFrequencyForward",rev(c(100,500,1000,2001,4001,8001)),sep=" "),paste("Belady2SizeForward",rev(c(100,500,1000,2001,4001,8001)),sep=" "),"GDSF 0","LRU 0")
#    llabels=c("OPT\nupper","OPT\nlower","Greedy\nVolume",paste("Belady\nSizeFreq\n",rev(c(100,500,1000,2001,4001,8001)),"sampl",sep=" "),paste("Belady\nSize\n",rev(c(100,500,1000,2001,4001,8001)),"sampl",sep=" "),"GDSF","LRU")

    llbreaks=c("fluid 0","lbound 0","FW-Volume 0","Belady2SizeForward 500","GDSF 0","LRU 0")
    llabels=c("OPT\nupper","OPT\nlower","Greedy\nVolume","Belady\nSize\n500","GDSF","LRU")

    
    dt3 <- dt2[tt %in% llbreaks]
    dt3[,type2:=factor(tt,levels=rev(llbreaks),labels=rev(llabels),ordered=TRUE)]

    dt4 <- dt3[logsize==31]
    dt4 <- dt3[logsize==30]

#
    pl <- ggplot(dt4,aes(type2,h/r))+
        geom_bar(stat="identity")+
    scale_y_continuous("Object Hit Ratio",expand=c(0,0))+
    scale_x_discrete("")+
    theme(legend.key.width = unit(1.1, "cm"),
          legend.key.height = unit(0.43, "cm"))+
    theme(legend.position = c(.73,0.25))+
    theme(legend.text = element_text(size = rel(0.9)))+
    theme(axis.title.x = element_text(size = rel(1.05),vjust=-.1),axis.title.y = element_text(size = rel(1.05),vjust=1.2))+
#    coord_cartesian(xlim=c(20,42))
                                        #    coord_cartesian(ylim=c(0.22,0.8))
    coord_cartesian(ylim=c(0,1))
#

    oname <- paste("/tmp/plots/opt_samplesize_",tr,".pdf",sep="")
    pdf(oname,8,5)
    print(pl)
    dev.off()

}





### abs error

dt <- rbind(lboundall2,fluid)
dt <- dt[!is.na(r)]
dt[,r:=max(r),by=trace]

errorhandler="stop"

i <- 1

dterr <- foreach(i=1:nrow(traceprops), .combine=rbind, .errorhandling=errorhandler) %do% {
    rw <- traceprops[i]
    tr <- rw$trace
    lrange <- rw$lr
    rrange <- rw$ur
    dt3 <- dt[trace==tr & logsize>=lrange & logsize<=rrange]
    if(nrow(dt3)==0) {
        next
    }
    dt3[type=="lbound" | type=="fluid2",list(err=max(h/r)-min(h/r)),by=list(logsize,trace)]
}    

dterr[,summary(err)]

setkey(dterr,trace,err)
dterr[,w:=1/length(err),by=trace]
dterr[,ecdf:=cumsum(w),by=trace]

dterr[,unique(trace)]

llbreaks=traceprops$trace
llabels=traceprops$tname

dterr[,trace2:=factor(trace,levels=llbreaks,labels=llabels,ordered=TRUE)]

cdntr <- traceprops[type=="CDN"]$trace

dterr2 <- dterr[trace %in% cdntr]

dterr2 <- dterr[!trace %in% cdntr]


pl <- ggplot(dterr2, aes(trace2, err, fill=trace)) + 
  geom_boxplot(outlier.shape=NA)+
    scale_x_discrete("")+
    scale_y_continuous("Error in Hit Ratio",expand=c(0,0))+
    theme(legend.position = "none")+
    theme(legend.key.width = unit(0.5, "cm"),
          legend.key.height = unit(0.28, "cm"))+
    theme(legend.text = element_text(size = rel(0.8)))+
    theme(axis.title.x = element_text(size = rel(1.1),vjust=-.1),axis.title.y = element_text(size = rel(1.1),vjust=1.2))+
    coord_cartesian(ylim=c(0,0.1))

oname <- "/tmp/plots/opt_pfoo_err_cdn.pdf"
oname <- "/tmp/plots/opt_pfoo_err_storage.pdf"
    
pdf(oname,2.5,2.6)
    print(pl)
    dev.off()


a








## exact

traces <- traceprops$trace
traces2 <- gsub("100m","",traces)

exact <- foreach(trace=traces2, .combine=rbind, .errorhandling='remove') %:%
    foreach(logsize=logsizes, .combine=rbind, .errorhandling='remove') %do% {
        fname <- paste("~/LemonMCF/nsolution/sol_exact_",trace,"5m_",logsize,".log",sep="")
        print(fname)
        tmp <- data.table(read.table(fname))
        tmp[,list(type="foo",trace,logsize,hu=V9,hl=V10,r=V6)]
}

errorhandler <- "remove"
#errorhandler <- "stop"

basepath <- "~/gcd/nsolutiong/"
servercount <- 25

exactgcd <- foreach(server=0:servercount, .combine=rbind, .errorhandling=errorhandler) %:%
    foreach(trace=traces, .combine=rbind, .errorhandling=errorhandler) %:%
    foreach(method=c("exact"), .combine=rbind, .errorhandling=errorhandler) %:%
    foreach(format=c(".log",".log_cpy"), .combine=rbind, .errorhandling=errorhandler) %:%
    foreach(logsize=logsizes, .combine=rbind, .errorhandling=errorhandler) %do% {
        fname <- paste(basepath,server,"/sol_",method,"_",trace,"5m__",logsize,format,sep="")
        if(file.exists(fname)){
            print(fname)
            tmp <- data.table(read.table(fname))
            tmp[,list(type="foo",trace,logsize,hu=V9,hl=V10,r=V6)]
        }
}

exactall <- rbind(exact,exactgcd)




exactall2 <- rbind(
    exactall[,list(type="ufoo",trace,logsize,h=hu,r)],
    exactall[,list(type="lfoo",trace,logsize,h=hl,r)]
    )


### OFMA


traces <- traceprops$trace
traces2 <- gsub("100m","",traces)


ofma <- foreach(trace=traces2, .combine=rbind, .errorhandling='remove') %:%
    foreach(format=c(".log",".log_cpy"), .combine=rbind, .errorhandling='remove') %:%
    foreach(logsize=logsizes, .combine=rbind, .errorhandling='remove') %do% {
        fname <- paste("~/LemonMCFofma/nsolution/sol_ofma_",trace,"5m_",logsize,format,sep="")
        if(file.exists(fname) & file.info(fname)$size > 0){
            print(fname)
            tmp <- data.table()
            tmp <- data.table(read.table(fname))
            print(paste("good",fname))
            tmp[,list(type=V1,trace,logsize,h=V4,r=V6)]
        }
}



# localratio

traces <- traceprops$trace
traces2 <- gsub("100m","",traces)

localratio <- foreach(trace=traces2, .combine=rbind, .errorhandling=errorhandler) %:%
    foreach(method=c("localratio"), .combine=rbind, .errorhandling=errorhandler) %:%
    foreach(logsize=logsizes, .combine=rbind, .errorhandling=errorhandler) %do% {
#        ttrace <- gsub("100m","",rw$trace) ## check this for other traces
        fname <- paste("~/LemonMCFlocalratio/nsolution/sol_",method,"_",trace,"5m_",logsize,".log",sep="")
        if(file.exists(fname)){
            print(fname)
            tmp <- data.table(read.table(fname))
            tmp2 <- last(tmp)
            tmp2[,list(type=method,trace=trace,logsize,h=V2,r=V4)]
        }
}


localratio
ofma
exactall2

dt <- rbind(exactall2,ofma,localratio)
dt <- dt[,list(h=max(h,na.rm=TRUE),r=max(r,na.rm=TRUE)),by=list(type,trace,logsize)]
dt[type=="ufoo",maxh:=h]
dt[,maxh:=max(maxh,na.rm=TRUE),by=list(logsize,trace)]
dt[ifelse(maxh<1,FALSE,h>maxh),h:=maxh]
dt[,maxh:=NULL]

dt[,r:=max(r),by=trace]

dt[,unique(type)]

llbreaks=c("ufoo","lfoo","OFMA","localratio")
llabels=c("FOO (upper)","FOO (lower)","OFMA","LocalRatio")

dt2 <- dt[type %in% llbreaks]
dt2[,type2:=factor(type,levels=llbreaks,labels=llabels,ordered=TRUE)]

ttypes <- dt2[,unique(type2)]

bbreaks <- c(22,24,26,28,30,32,34,36,38,40,42)
blabels <- c("       4MB","16MB","64MB","       256MB","1GB","4GB","16GB","64GB","256GB","1TB","4TB   ")

bbreaks <- c(24,27,30,33,36,39,42)
blabels <- c("16MB","128MB","1GB","8GB","128GB","512GB","4TB  ")


for(i in 1:nrow(traceprops)) {
    rw <- traceprops[i]
    tr <- traces2 <- gsub("100m","",rw$trace) ## check this for other traces
    lrange <- rw$lr
    rrange <- rw$ur
    dt3 <- dt2[trace==tr & logsize>=lrange & logsize<=rrange]
    if(nrow(dt3)==0) {
        next
    }
    lx <- rw$lx
    ly <- rw$ly
    pl <- ggplot(dt3,aes(logsize,h/r,color=type2,shape=type2))+
        geom_line(size=0.5)+
        geom_point(size=1.2)+
    scale_color_manual("",values = c("#888888","#444444",getPalette(length(ttypes)-2)))+
    scale_shape_manual("",values=1:20)+
    scale_y_continuous("Object Hit Ratio",expand=c(0,0))+
    scale_x_continuous("Cache Size",expand=c(0,0),breaks=bbreaks,labels=blabels)+
    theme(legend.key.width = unit(0.5, "cm"),
          legend.key.height = unit(0.28, "cm"))+
    theme(legend.position = c(lx,ly))+
    theme(legend.text = element_text(size = rel(0.8)))+
    theme(axis.title.x = element_text(size = rel(1.1),vjust=-.1),axis.title.y = element_text(size = rel(1.1),vjust=1.2))+
        theme(legend.background = element_rect(fill="transparent"))+
    coord_cartesian(xlim=c(lrange,rrange),ylim=c(0,1.0))
#
    oname <- paste("/tmp/plots/opt_foo_",tr,".pdf",sep="")
    pdf(oname,3,2.6)
    print(pl)
    dev.off()
}


errorhandler="stop"

dterr <- foreach(i=1:nrow(traceprops), .combine=rbind, .errorhandling=errorhandler) %do% {
    rw <- traceprops[i]
    tr <- traces2 <- gsub("100m","",rw$trace) ## check this for other traces
    lrange <- rw$lr
    rrange <- rw$ur
    dt3 <- dt2[trace==tr & logsize>=lrange & logsize<=rrange]
    if(nrow(dt3)==0) {
        next
    }
    dt3[grepl("foo",type),list(err=max(h/r)-min(h/r)),by=list(logsize,trace)]
}    

dterr[,summary(err)]

setkey(dterr,trace,err)
dterr[,w:=1/length(err),by=trace]
dterr[,ecdf:=cumsum(w),by=trace]

dterr[,unique(trace)]

llbreaks=gsub("100m","",traceprops$trace)
llabels=traceprops$tname

dterr[,trace2:=factor(trace,levels=llbreaks,labels=llabels,ordered=TRUE)]

dterr

cdntr <- gsub("100m","",traceprops[type=="CDN"]$trace)

dterr2 <- dterr[trace %in% cdntr]

dterr2 <- dterr[!trace %in% cdntr]


pl <- ggplot(dterr2, aes(trace2, err, fill=trace)) + 
  geom_boxplot(outlier.shape=NA)+
    scale_x_discrete("")+
    scale_y_continuous("Error in Hit Ratio",expand=c(0,0))+
    theme(legend.position = "none")+
    theme(legend.key.width = unit(0.5, "cm"),
          legend.key.height = unit(0.28, "cm"))+
    theme(legend.text = element_text(size = rel(0.8)))+
    theme(axis.title.x = element_text(size = rel(1.1),vjust=-.1),axis.title.y = element_text(size = rel(1.1),vjust=1.2))+
    coord_cartesian(ylim=c(0,0.0005))

oname <- "/tmp/plots/opt_foo_err_cdn.pdf"
oname <- "/tmp/plots/opt_foo_err_storage.pdf"
    
pdf(oname,2.5,2.6)
    print(pl)
    dev.off()
