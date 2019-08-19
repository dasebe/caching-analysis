library(data.table)
library(ggplot2)
library(foreach)


files <- dir(,pattern=".*table")

files

dt <- foreach(fn=files,.combine=rbind, .errorhandling="remove") %do%
    {
        data.table(read.table(fn))
    }
    

dt[,tr:=gsub(".*/data/","",V1)]
dt[,V1:=NULL]

dt[,unique(V3)]

dt[V3=="RequestedBytes",sum(V4),by=tr]
dt[V3=="UniqueObjects"]
dt[V3=="RequestCount",sum(V4),by=tr]







dt[V3=="OneHitWonders",min(V4),by=tr]
dt[V3=="OneHitWonders",sum(V4),by=tr]
dt[V3=="OneHitWonders",max(V4),by=tr]

dt[V3=="ObjectSize_Min",min(V4)]
dt[V3=="UniqueBytes",sum(V4)]/dt[V3=="UniqueObjects",sum(V4)]
dt[V3=="ObjectSize_Max",max(V4)]



dt[V3=="RequestCount",min(V4)/10^6,by=tr]
dt[V3=="RequestCount",sum(V4)/10^6,by=tr]
dt[V3=="RequestCount",max(V4)/10^6,by=tr]

dt[V3=="RequestedBytes",min(V4)/2^20/60/60*8,by=tr]
dt[V3=="RequestedBytes",sum(V4)/2^20/60/60*8,by=tr]
dt[V3=="RequestedBytes",max(V4)/2^20/60/60*8,by=tr]

dt[,max(V2)]
dt[,min(V2),by=tr]

dt[,max(V2)/60/60/24,by=tr]

dt[tr=="traceHK.tr",max(V2)/60/60/24]-dt[tr=="traceHK.tr",min(V2)/60/60/24]
dt[tr=="traceUS.tr",max(V2)/60/60/24]-dt[tr=="traceUS.tr",min(V2)/60/60/24]

# plot of sampled request rate over time

dt.sampled <- dt[grepl("SampledObject.*",V3)][tr!="wc400m.tr"]
dt.sampled[,time:=V2-min(V2),by=tr]

objs <- dt.sampled[,unique(V3)]

p <- ggplot(dt.sampled,aes(time/60/60,V4,color=V3))+
    facet_wrap(. ~ tr, scales="free",ncol=1) +
    geom_line()+
    scale_y_log10("Log request rate")+
    scale_x_continuous("Time [hours]")+
    scale_color_discrete("Object\n sample",breaks=objs,labels=1:(length(objs)))
pdf("/tmp/sampled.pdf",8,8)
print(p)
dev.off()


dt.ohw <- dt[grepl("OneHitWonders.*",V3)][tr!="wc400m.tr"]
dt.ohw[,time:=V2-min(V2),by=tr]
objs <- dt.ohw[,unique(V3)]

p <- ggplot(dt.ohw,aes(time/60/60,V4))+
    facet_wrap(. ~ tr, scales="free",ncol=1) +
    geom_line()+
    scale_y_continuous("One Hit Wonder Count")+
    scale_x_continuous("Time [hours]")
pdf("/tmp/ohw.pdf",8,8)
print(p)
dev.off()


dt.reqs <- dt[grepl("RequestCount.*",V3)][tr!="wc400m.tr"]
dt.reqs[,time:=V2-min(V2),by=tr]

p <- ggplot(dt.reqs,aes(time/60/60,V4/60/60))+
    facet_wrap(. ~ tr, scales="free",ncol=1) +
    geom_line()+
    scale_y_continuous("Request rate [reqs/sec]")+
    scale_x_continuous("Time [hours]")
pdf("/tmp/reqs.pdf",8,8)
print(p)
dev.off()


dt.uniqueb <- dt[grepl("UniqueBytes",V3)][tr!="wc400m.tr"]
dt.uniqueb[,time:=V2-min(V2),by=tr]

p <- ggplot(dt.uniqueb,aes(time/60/60,V4/2^30))+
    facet_wrap(. ~ tr, scales="free",ncol=1) +
    geom_line()+
    scale_y_continuous("Unique GB")+
    scale_x_continuous("Time [hours]")
pdf("/tmp/uniqueb.pdf",8,8)
print(p)
dev.off()

dt.totalb <- dt[grepl("RequestedBytes",V3)][tr!="wc400m.tr"]
dt.totalb[,time:=V2-min(V2),by=tr]

setkey(dt.totalb,"tr","time")
setkey(dt.uniqueb,"tr","time")

m1 <- dt.totalb[,list(tr,time,b=V4)]
m2 <- dt.uniqueb[,list(tr,time,u=V4)]

dt.totalbu <- m1[m2]

p <- ggplot(dt.totalbu,aes(time/60/60,u/b))+
    facet_wrap(. ~ tr, scales="free",ncol=1) +
    geom_line()+
    scale_y_continuous("Unique Bytes [%]")+
    scale_x_continuous("Time [hours]")
pdf("/tmp/uniquebu.pdf",8,8)
print(p)
dev.off()



dt.uniqueo <- dt[grepl("UniqueObjects",V3)][tr!="wc400m.tr"]
dt.uniqueo[,time:=V2-min(V2),by=tr]
objs <- dt.uniqueo[,unique(V3)]

p <- ggplot(dt.uniqueo,aes(time/60/60,V4,color=V3))+
    facet_wrap(. ~ tr, scales="free",ncol=1) +
    geom_line()+
    scale_y_continuous("Unique Object Count")+
    scale_x_continuous("Time [hours]")+
    scale_color_discrete("Object\n sample",breaks=objs,labels=1:(length(objs)))
pdf("/tmp/uniqueo.pdf",6,8)
print(p)
dev.off()



#csvs

all <- rbind(
              dt[,list(v=sum(V4),w="sum"),by=list(V3,tr)],
              dt[,list(v=max(V4),w="max"),by=list(V3,tr)],
              dt[,list(v=min(V4),w="min"),by=list(V3,tr)]
          )

write.csv(all,"/tmp/stats.csv")

all[,unique(tr)]
all
write.csv(all[grepl("ntg.*",tr)],"/tmp/stats.csv")
