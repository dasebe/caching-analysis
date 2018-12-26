library(ggplot2)
library(data.table)
library(scales)
library(foreach)
ggplot <- function(...) { ggplot2::ggplot(...) + theme_bw() }

dt1 <- data.table(read.table("../ntrace/traceUS100m.tr_sizes.tr"))
dt2 <- data.table(read.table("../ntrace/w100m.tr_sizes.tr"))

setnames(dt1,c("V1","V2"),c("id","size"))
setnames(dt2,c("V1","V2"),c("id","size"))

dts <- dt1
dts <- dt2

setkey(dts,size)
dts[,ii:=1/nrow(dts)]
dts2 <- dts[,list(isums=sum(ii),size=last(size)),by=list(r=(1000*log2(size))%/%10)]
dts2[,cdf:=cumsum(isums)]
dts2[,data:='empirical']

write.table(dts2,"traceUS100m_cdf.table")
write.table(dts2,"w100m_cdf.table")

pdf("/tmp/plots/size_cdf_traceUS100m.pdf",5,3)
pdf("/tmp/plots/size_cdf_w100m.pdf",5,3)

ggplot(dts2,aes(size,cdf)) +
    geom_line(size=.7) +
        scale_y_continuous("Distribution (CDF)", expand=c(0,0))+
    scale_x_continuous("Object Size",trans = log2_trans(),breaks=2^seq(0,30,5),labels=c("1B","32B","1KB","32KB","1MB","32MB","1GB"),minor_breaks=NULL, expand=c(0,0))+
    theme(legend.key.width = unit(1.1, "cm"),
          legend.key.height = unit(0.43, "cm"))+
    theme(legend.text = element_text(size = rel(0.9)))+
    theme(axis.title.x = element_text(size = rel(1.05),vjust=-.1),axis.title.y = element_text(size = rel(1.05),vjust=1.2))+
    coord_cartesian(ylim=c(0,1.01),xlim=c(1,2^31))
dev.off()
