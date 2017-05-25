#!/usr/bin/env Rscript
args = commandArgs(trailingOnly=TRUE)
                   
p<-read.table(args[1])
p<-1-p
a<-p.adjust(p$V1,method = "fdr")
#sort(a)
a<-1-a
write.table(a,args[2],row.names = F, quote = F,col.names = F)
