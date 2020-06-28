rm(list = ls())

packages = c("plyr", "here",
             "reshape2", "ggplot2")

## Now load or install&load all
package.check <- lapply(
  packages,
  FUN = function(x) {
    if (!require(x, character.only = TRUE)) {
      install.packages(x, dependencies = TRUE)
      library(x, character.only = TRUE)
    }
  }
)

Patterns<-c('*cand0.log','*cand1.log','*cand3.log','*cand4.log')
Heuristics<-c('prop','a2a','steal','stealLocal')
MPIs<-c('sharedM','2M12','4M6','6M4','12M2','24M1')
Numbers<-c(1,2,4,6,12,24)
Types<-c('number','volume')
matrixnames<-read.table(file = here::here("matrixnames.txt"),header = FALSE,stringsAsFactors = FALSE)
matrixnames<-as.character(matrixnames$V1)

MergeMatrix<-function(index,MPI,number){
  matrixname<-matrixnames[index]
  print(paste0("merge matrix ", matrixname," on MPI ", MPI))
  dirs<-list.dirs(here::here('shared',paste0('pmap-miriel-',MPI),matrixname),TRUE)
  logfiles<-list.files(path = here::here('shared',paste0('pmap-miriel-',MPI),matrixname), '*.log')
  matrix.merged<-data.frame(Preader=character(),Treader=character(),
                           Pwriter=character(),Twriter=character(),
                           number=numeric(),heuristic=character())
  for(i in 1:4){
    logfile<-grep(Patterns[i],logfiles,value = TRUE)
    lines<-readLines(here::here('shared',paste0('pmap-miriel-',MPI),matrixname,logfile))
    outputdirs<-grep("OUTPUTDIR",lines,value = TRUE)
    outputdirs<-gsub('OUTPUTDIR: ','',outputdirs)
    
    dirs.heuristic<-grep(here::here('shared',paste0('pmap-miriel-',MPI),matrixname,outputdirs),dirs,value = TRUE)
    dirs.csv1<-list.files(dirs.heuristic,'cost_matrix_[0-9].csv',full.names = TRUE)
    dirs.csv2<-list.files(dirs.heuristic,'cost_matrix_[0-9][0-9].csv',full.names = TRUE)
    dirs.csv<-c(dirs.csv1,dirs.csv2)
    if(length(dirs.csv)!=number){
      print(paste0("error at ",MPI, " and matrix ",matrixname," and heuristic ",Heuristics[i]))
    }
    csvs<-lapply(dirs.csv,read.csv,header=TRUE,sep=";")
    csv<-do.call(rbind.data.frame, csvs)
    csv$heuristic<-Heuristics[i]
    matrix.merged<-rbind(matrix.merged,csv)
  }
  
  return(matrix.merged)
}

#store data movements
period<-2*length(MPIs)
DataMove<-data.frame(matrix=rep(matrixnames,period),
                     propMap=rep(0,length(matrixnames)*period),
                     a2a=rep(0,length(matrixnames)*period),
                     steal=rep(0,length(matrixnames)*period),
                     stealLocal=rep(0,length(matrixnames)*period),
                     MPI=rep('0M0',length(matrixnames)*period),
                     type=rep('vorn',length(matrixnames)*period),
                     stringsAsFactors = FALSE)
#store communications
CommunicationTable<-DataMove

for(i in seq_along(MPIs)){
  for(j in seq_along(matrixnames)){
    csv<-MergeMatrix(j,MPIs[i],Numbers[i])
    csv$Nbr.of.elements.written<-as.numeric(csv$Nbr.of.elements.written)
    
    #extract the communication between MPI nodes
    if(MPIs[i]!='sharedM'){
      Comm<-csv[which(csv$Thread.Reader==-1&csv$Thread.Writer==-1),]
      if(sum(Comm$X..Proc.Reader==Comm$Proc.Writer)!=0){
        print(paste0("error at ",MPIs[i], " and matrix ",matrixnames[j]))
      }
      Comm<-Comm[,c("X..Proc.Reader", "Proc.Writer", "Nbr.of.elements.written", "heuristic")]
      colnames(Comm)<-c("to","from","value","heuristic")
      Number.Comm<-table(Comm$heuristic)
      Volume.Comm<-aggregate(value~heuristic,Comm,sum)
    }
    
    #extract the data movements in a MPI node
    if(MPIs[i]!='24M1'){
    Move<-csv[csv$X..Proc.Reader == csv$Proc.Writer,]
    Move<-csv[csv$Thread.Reader>=0,]
    Move<-csv[csv$Thread.Writer>=0|csv$Thread.Writer==-2,]
    #Move<-csv[csv$Thread.Writer>=0,]
    
    Move<-Move[,c("Thread.Reader","Thread.Writer","Nbr.of.elements.written","heuristic")]
    colnames(Move)<-c("to","from","value","heuristic")
    
    Number.Move<-table(Move$heuristic)
    Volume.Move<-aggregate(value~heuristic,Move,sum)
    }
    
    #store the data
    for(k in seq_along(Types)){
      if(MPIs[i]!='sharedM'){
        if(k==1){#number
          if(is.na(Number.Comm["prop"])==TRUE){
            CommunicationTable[(i-1)*2*length(matrixnames)+(k-1)*length(matrixnames)+j,"propMap"]<-0
            print(paste0("No Communication, Heuristic propMap, Number? ",k))
          }else{
            CommunicationTable[(i-1)*2*length(matrixnames)+(k-1)*length(matrixnames)+j,"propMap"]<-Number.Comm["prop"]
          }
          
          if(is.na(Number.Comm["a2a"])==TRUE){
            CommunicationTable[(i-1)*2*length(matrixnames)+(k-1)*length(matrixnames)+j,"a2a"]<-0
            print(paste0("No Communication, Heuristic a2a, Number? ",k))
          }else{
            CommunicationTable[(i-1)*2*length(matrixnames)+(k-1)*length(matrixnames)+j,"a2a"]<-Number.Comm["a2a"]
          }
          
          if(is.na(Number.Comm["steal"])==TRUE){
            CommunicationTable[(i-1)*2*length(matrixnames)+(k-1)*length(matrixnames)+j,"steal"]<-0
            print(paste0("No Communication, Heuristic steal, Number? ",k))
          }else{
            CommunicationTable[(i-1)*2*length(matrixnames)+(k-1)*length(matrixnames)+j,"steal"]<-Number.Comm["steal"]
          }
          
          if(is.na(Number.Comm["stealLocal"])==TRUE){
            CommunicationTable[(i-1)*2*length(matrixnames)+(k-1)*length(matrixnames)+j,"stealLocal"]<-0
            print(paste0("No Communication, Heuristic stealLocal, Number? ",k))
          }else{
            CommunicationTable[(i-1)*2*length(matrixnames)+(k-1)*length(matrixnames)+j,"stealLocal"]<-Number.Comm["stealLocal"]
          }
        }
        
        if(k==2){#volume
          CommunicationTable[(i-1)*2*length(matrixnames)+(k-1)*length(matrixnames)+j,"propMap"]<-Volume.Comm$value[Volume.Comm$heuristic=='prop']
          CommunicationTable[(i-1)*2*length(matrixnames)+(k-1)*length(matrixnames)+j,"a2a"]<-Volume.Comm$value[Volume.Comm$heuristic=='a2a']
          CommunicationTable[(i-1)*2*length(matrixnames)+(k-1)*length(matrixnames)+j,"steal"]<-Volume.Comm$value[Volume.Comm$heuristic=='steal']
          CommunicationTable[(i-1)*2*length(matrixnames)+(k-1)*length(matrixnames)+j,"stealLocal"]<-Volume.Comm$value[Volume.Comm$heuristic=='stealLocal']
        }
        
        CommunicationTable[(i-1)*2*length(matrixnames)+(k-1)*length(matrixnames)+j,'MPI']<-MPIs[i]
        CommunicationTable[(i-1)*2*length(matrixnames)+(k-1)*length(matrixnames)+j,'type']<-Types[k]
      }
      
      #------data movements
      if(MPIs[i]!='24M1'){
        if(k==1){#number
          if(is.na(Number.Move["prop"])==TRUE){
            DataMove[(i-1)*2*length(matrixnames)+(k-1)*length(matrixnames)+j,"propMap"]<-0
            print(paste0("No Communication, Heuristic propMap, Number? ",k))
          }else{
            DataMove[(i-1)*2*length(matrixnames)+(k-1)*length(matrixnames)+j,"propMap"]<-Number.Move["prop"]
          }
          
          if(is.na(Number.Move["a2a"])==TRUE){
            DataMove[(i-1)*2*length(matrixnames)+(k-1)*length(matrixnames)+j,"a2a"]<-0
            print(paste0("No Communication, Heuristic a2a, Number? ",k))
          }else{
            DataMove[(i-1)*2*length(matrixnames)+(k-1)*length(matrixnames)+j,"a2a"]<-Number.Move["a2a"]
          }
          
          if(is.na(Number.Move["steal"])==TRUE){
            DataMove[(i-1)*2*length(matrixnames)+(k-1)*length(matrixnames)+j,"steal"]<-0
            print(paste0("No Communication, Heuristic steal, Number? ",k))
          }else{
            DataMove[(i-1)*2*length(matrixnames)+(k-1)*length(matrixnames)+j,"steal"]<-Number.Move["steal"]
          }
          
          if(is.na(Number.Move["stealLocal"])==TRUE){
            DataMove[(i-1)*2*length(matrixnames)+(k-1)*length(matrixnames)+j,"stealLocal"]<-0
            print(paste0("No Communication, Heuristic stealLocal, Number? ",k))
          }else{
            DataMove[(i-1)*2*length(matrixnames)+(k-1)*length(matrixnames)+j,"stealLocal"]<-Number.Move["stealLocal"]
          }
        }
        
        if(k==2){#volume
          DataMove[(i-1)*2*length(matrixnames)+(k-1)*length(matrixnames)+j,"propMap"]<-Volume.Move$value[Volume.Move$heuristic=='prop']
          DataMove[(i-1)*2*length(matrixnames)+(k-1)*length(matrixnames)+j,"a2a"]<-Volume.Move$value[Volume.Move$heuristic=='a2a']
          DataMove[(i-1)*2*length(matrixnames)+(k-1)*length(matrixnames)+j,"steal"]<-Volume.Move$value[Volume.Move$heuristic=='steal']
          DataMove[(i-1)*2*length(matrixnames)+(k-1)*length(matrixnames)+j,"stealLocal"]<-Volume.Move$value[Volume.Move$heuristic=='stealLocal']
        }
        
        DataMove[(i-1)*2*length(matrixnames)+(k-1)*length(matrixnames)+j,'MPI']<-MPIs[i]
        DataMove[(i-1)*2*length(matrixnames)+(k-1)*length(matrixnames)+j,'type']<-Types[k]
      }
    }
  }
}

CommunicationTable<-CommunicationTable[CommunicationTable$type!='vorn',] 
DataMove<-DataMove[DataMove$type!='vorn',]

write.table(CommunicationTable,here::here('shared','Communication_summary.txt'),quote = FALSE,col.names = TRUE, row.names = FALSE)
write.table(DataMove,here::here('shared','DataMove_summary_countLocalC.txt'),quote = FALSE,col.names = TRUE, row.names = FALSE)


#--------------------------------------

###factorization time difference between all2all, propMap, closer
factor.time<-data.frame(matrix=matrixnames,
                        propMap1=rep(0,length(matrixnames)),
                        propMap2=rep(0,length(matrixnames)),
                        propMap3=rep(0,length(matrixnames)),
                        a2a1=rep(0,length(matrixnames)),
                        a2a2=rep(0,length(matrixnames)),
                        a2a3=rep(0,length(matrixnames)),
                        steal1=rep(0,length(matrixnames)),
                        steal2=rep(0,length(matrixnames)),
                        steal3=rep(0,length(matrixnames)),
                        stringsAsFactors = FALSE)

for(j in seq_along(matrixnames)){
  #prop
  log<-readLines(here::here('shared','pmap-miriel-factor',matrixnames[j],paste0('miriel_',matrixnames[j],'_sched1_1d_bs288_864_cand0.log')))
  #log<-readLines(paste0(matrixnames[j],'/miriel_',matrixnames[j],'_sched1_1d_bs288_864_cand0.log'))
  fac.time<-grep("Time to factorize",log, value = TRUE)
  fac.time<-fac.time[2:4]
  fac.time<-strsplit(fac.time,' ')
  fac.time<-unlist(lapply(fac.time,function(x){as.numeric(x[28])}))
  factor.time[j,2:4]<-fac.time
  
  #a2a
  log<-readLines(here::here('shared','pmap-miriel-factor',matrixnames[j],paste0('miriel_',matrixnames[j],'_sched1_1d_bs288_864_cand1.log')))
  fac.time<-grep("Time to factorize",log, value = TRUE)
  fac.time<-fac.time[2:4]
  fac.time<-strsplit(fac.time,' ')
  fac.time<-unlist(lapply(fac.time,function(x){as.numeric(x[28])}))
  factor.time[j,5:7]<-fac.time
  
  #steal
  log<-readLines(here::here('shared','pmap-miriel-factor',matrixnames[j],paste0('miriel_',matrixnames[j],'_sched1_1d_bs288_864_cand3.log')))
  fac.time<-grep("Time to factorize",log, value = TRUE)
  fac.time<-fac.time[2:4]
  fac.time<-strsplit(fac.time,' ')
  fac.time<-unlist(lapply(fac.time,function(x){as.numeric(x[28])}))
  factor.time[j,8:10]<-fac.time
}

write.table(factor.time,here::here('shared','factorization_time_miriel.txt'),quote = FALSE, row.names = FALSE)

#--------------------------------------
#get the simulation cost in second, and the predicted factorization time

Simu.cost<-data.frame(matrix=rep(matrixnames,length(MPIs)),
                     PropMap=rep(0,length(matrixnames)*length(MPIs)),
                     a2a=rep(0,length(matrixnames)*length(MPIs)),
                     Steal=rep(0,length(matrixnames)*length(MPIs)),
                     StealLocal=rep(0,length(matrixnames)*length(MPIs)),
                     MPI=rep('0M0',length(matrixnames)*length(MPIs)),
                     stringsAsFactors = FALSE)
Predicted.factor<-Simu.cost

for(i in seq_along(MPIs)){
  for(j in seq_along(matrixnames)){
    logfiles<-list.files(path = here::here('shared',paste0('pmap-miriel-',MPIs[i]),matrixnames[j]), '*.log')
    for(k in 1:4){
      logfile<-grep(Patterns[k],logfiles,value = TRUE)
      lines<-readLines(here::here('shared',paste0('pmap-miriel-',MPIs[i]),matrixnames[j],logfile))
      sim.time<-grep("Simulation done in",lines, value = TRUE)
      sim.time<-strsplit(sim.time,' ')
      sim.time<-as.numeric(sim.time[[1]][length(sim.time[[1]])-1])
      Simu.cost[(i-1)*length(matrixnames)+j,1+k]<-sim.time
      
      predict<-grep("Time to factorize", lines, value=TRUE)
      predict.time<-strsplit(predict,' ')
      predict.time<-as.numeric(predict.time[[1]][length(predict.time[[1]])-1])
      Predicted.factor[(i-1)*length(matrixnames)+j,1+k]<-predict.time
    }
    Simu.cost[(i-1)*length(matrixnames)+j,'MPI']<-MPIs[i]
    Predicted.factor[(i-1)*length(matrixnames)+j,'MPI']<-MPIs[i]
  }
}

write.table(Simu.cost,here::here('shared','simulation_cost.txt'), quote = FALSE, row.names = FALSE)
write.table(Predicted.factor,here::here('shared','Predicted_factor_time.txt'), quote = FALSE, row.names = FALSE)

#--------------------------------------
matrix<-matrixnames
factor.time<-data.frame(matrix=matrix,
                        propMap1=rep(0,length(matrix)),
                        propMap2=rep(0,length(matrix)),
                        propMap3=rep(0,length(matrix)),
                        a2a1=rep(0,length(matrix)),
                        a2a2=rep(0,length(matrix)),
                        a2a3=rep(0,length(matrix)),
                        steal1=rep(0,length(matrix)),
                        steal2=rep(0,length(matrix)),
                        steal3=rep(0,length(matrix)),
                        stringsAsFactors = FALSE)

for(j in seq_along(matrix)){
  #prop
  log<-readLines(here::here('pmap-crunch-sharedM-support',paste0('crunch_',matrix[j],'_sched1_1d_bs288_864_cand0.log')))
  fac.time<-grep("Time to factorize",log, value = TRUE)
  fac.time<-fac.time[2:4]
  fac.time<-strsplit(fac.time,' ')
  fac.time<-unlist(lapply(fac.time,function(x){as.numeric(x[28])}))
  factor.time[j,2:4]<-fac.time
  
  #a2a
  log<-readLines(here::here('pmap-crunch-sharedM-support',paste0('crunch_',matrix[j],'_sched1_1d_bs288_864_cand1.log')))
  fac.time<-grep("Time to factorize",log, value = TRUE)
  fac.time<-fac.time[2:4]
  fac.time<-strsplit(fac.time,' ')
  fac.time<-unlist(lapply(fac.time,function(x){as.numeric(x[28])}))
  factor.time[j,5:7]<-fac.time
  
  #steal
  log<-readLines(here::here('pmap-crunch-sharedM-support',paste0('crunch_',matrix[j],'_sched1_1d_bs288_864_cand3.log')))
  fac.time<-grep("Time to factorize",log, value = TRUE)
  fac.time<-fac.time[2:4]
  fac.time<-strsplit(fac.time,' ')
  fac.time<-unlist(lapply(fac.time,function(x){as.numeric(x[28])}))
  factor.time[j,8:10]<-fac.time
}

write.table(factor.time,here::here('pmap-crunch-sharedM-support','factorTime.txt'),col.names = TRUE,row.names = FALSE,quote = FALSE)
#--------------------------------------

#----------plots start from here-------------------

#colours in all figures are consistent
cb_palette <- c(PropMap="#F8766D", a2a="#B79F00",
                Steal="#619CFF", StealLocal="#00BA38")

###figure_3(a) and figure_3(b), number and volume of communications between MPI nodes
commCost<-read.table(here::here('shared','Communication_summary.txt'),header = TRUE)
commCost.copy<-commCost

commCost$propMap<-commCost$propMap/commCost$a2a
commCost$steal<-commCost$steal/commCost$a2a
commCost$stealLocal<-commCost$stealLocal/commCost$a2a

commCost.long<-melt(commCost,id.vars = c("matrix","MPI","type"),variable.name = "heuristic", value.name = "value")
commCost.long<-commCost.long[commCost.long$heuristic!='a2a',]
commCost.long$MPI<-factor(commCost.long$MPI, levels=c("sharedM","2M12","4M6","6M4","12M2","24M1"))
levels(commCost.long$heuristic)[1]<-"PropMap"
levels(commCost.long$heuristic)[3]<-"Steal"
levels(commCost.long$heuristic)[4]<-"StealLocal"
commCost.long$heuristic<-factor(commCost.long$heuristic,levels = c("PropMap","Steal","StealLocal"))

select="number"
#figure_3(a) in the paper
ggplot(commCost.long[commCost.long$type==select,],aes(x=MPI,y=value,fill=heuristic))+geom_boxplot(outlier.size = 0.3)+
  labs(y="Number of communications\n normalized to A2A", x="MPI settings")+
  coord_cartesian(ylim=c(0,0.15))+
  labs(fill="")+
  scale_fill_manual(values = cb_palette)+
  guides(fill=guide_legend(nrow = 1))+
  theme(legend.position = "top",legend.background = element_blank(),legend.key = element_blank(),
        axis.text.x = element_text(angle = 30, hjust = 1, vjust = 1, size = 8),
        axis.text.y = element_text(angle = 30, hjust = 1, vjust = 1, size = 8))
#ggsave(here::here("figure_3a.pdf"), width=12, height=9, units="cm")

#figure_3(b) in the paper
select="volume"
ggplot(commCost.long[commCost.long$type==select,],aes(x=MPI,y=value,fill=heuristic))+geom_boxplot(outlier.size = 0.3)+
  labs(y="Volume of communications\n normalized to A2A", x="MPI settings")+
  coord_cartesian(ylim=c(0,1))+
  labs(fill="")+
  scale_fill_manual(values = cb_palette)+
  guides(fill=guide_legend(nrow = 1))+
  theme(legend.position = "top",legend.background = element_blank(),legend.key = element_blank(),
        axis.text.x = element_text(angle = 30, hjust = 1, vjust = 1, size = 8),
        axis.text.y = element_text(angle = 30, hjust = 1, vjust = 1, size = 8))
#ggsave(here::here("figure_3b.pdf"), width=12, height=9, units="cm")

#data movement in MPI nodes -----------------------------------------------------
### figure_4(a), figure_4(b), data movement in MPI nodes
rm("commCost","commCost.copy","commCost.long")

#datamove<-read.table("DataMove_summary.txt",header = TRUE)
datamove<-read.table(here::here('shared',"DataMove_summary_countLocalC.txt"),header = TRUE)
datamove.copy<-datamove

datamove$propMap<-datamove$propMap/datamove$a2a
datamove$steal<-datamove$steal/datamove$a2a
datamove$stealLocal<-datamove$stealLocal/datamove$a2a

datamove.long<-melt(datamove,id.vars=c("matrix","MPI","type"),variable.name = "heuristic", value.name = "value")
datamove.long$MPI<-factor(datamove.long$MPI, levels=c("sharedM","2M12","4M6","6M4","12M2","24M1"))
levels(datamove.long$heuristic)[1]<-"PropMap"
levels(datamove.long$heuristic)[3]<-"Steal"
levels(datamove.long$heuristic)[4]<-"StealLocal"
datamove.long$heuristic<-factor(datamove.long$heuristic,levels = c("PropMap","a2a","Steal","StealLocal"))
datamove.long<-datamove.long[datamove.long$heuristic!="a2a",]

select<-'number'
#figure 4(a) in the paper
ggplot(datamove.long[datamove.long$type==select,],aes(x=MPI,y=value,fill=heuristic))+geom_boxplot(outlier.size = 0.3)+
  labs(y="Number of data movements\n normalized to A2A", x="MPI settings")+
  #coord_cartesian(ylim=c(0,8))+
  guides(fill=guide_legend(nrow = 1))+
  labs(fill="")+
  scale_fill_manual(values = cb_palette)+
  theme(legend.position = "top",legend.background = element_blank(),legend.key = element_blank(),
        axis.text.x = element_text(angle = 30, hjust = 1, vjust = 1, size = 8),
        axis.text.y = element_text(angle = 30, hjust = 1, vjust = 1, size = 8))

#ggsave(here::here('figure_4a.pdf'), width=12, height=9, units="cm")

#figure 4(b) in the paper
select<-'volume'
ggplot(datamove.long[datamove.long$type==select,],aes(x=MPI,y=value,fill=heuristic))+geom_boxplot(outlier.size = 0.3)+
  labs(y="Volume of data movements\n normalized to A2A",x="MPI settings")+
  #coord_cartesian(ylim=c(0,8))+
  guides(fill=guide_legend(nrow = 1))+
  labs(fill="")+
  scale_fill_manual(values = cb_palette)+
  theme(legend.position = "top",legend.background = element_blank(),legend.key = element_blank(),
        axis.text.x = element_text(angle = 30, hjust = 1, vjust = 1, size = 8),
        axis.text.y = element_text(angle = 30, hjust = 1, vjust = 1, size = 8))
#ggsave(here::here('figure_4b.pdf'), width=12, height=9, units="cm")

#---------------------------------------
#figure_5a simulation cost
simu.cost<-read.table(here::here('shared','simulation_cost.txt'),header = TRUE)
str(simu.cost)

simu.cost.long<-melt(simu.cost,id.vars = c("matrix","MPI"),variable.name = "heuristic", value.name = "cost")
str(simu.cost.long)
simu.cost.long$MPI<-factor(simu.cost.long$MPI,levels = c("sharedM","2M12","4M6","6M4","12M2","24M1"))
levels(simu.cost.long$heuristic)[2]<-"A2A"
simu.cost.long$heuristic<-factor(simu.cost.long$heuristic,levels=c("A2A","PropMap","Steal","StealLocal"))

cb_palette <- c(PropMap="#F8766D", A2A="#B79F00",
                Steal="#619CFF", StealLocal="#00BA38")

#figure_5a
ggplot(simu.cost.long,aes(x=MPI,y=cost,fill=heuristic))+geom_boxplot(outlier.size = 0.3)+
  labs(y="Simulation cost in second",fill="")+
  scale_fill_manual(values = cb_palette)+
  guides(fill=guide_legend(nrow = 1))+
  theme(legend.position = "top",legend.background = element_blank(),legend.key = element_blank(),
        axis.text.x = element_text(angle = 30, hjust = 1, vjust = 1, size = 8),
        axis.text.y = element_text(angle = 30, hjust = 1, vjust = 1, size = 8))
#ggsave(here::here('figure_5a'), width=12, height=9, units="cm")

#figure_6a predicted factorization time
pre.factor<-read.table(here::here('shared','Predicted_factor_time.txt') ,header = TRUE)

pre.factor.long<-melt(pre.factor,id.vars = c("matrix","MPI"),variable.name = "heuristic", value.name = "cost")
pre.factor.long$MPI<-factor(pre.factor.long$MPI,levels = c("sharedM","2M12","4M6","6M4","12M2","24M1"))
levels(pre.factor.long$heuristic)[2]<-"A2A"
pre.factor.long$heuristic<-factor(pre.factor.long$heuristic,levels=c("A2A","PropMap","Steal","StealLocal"))

cb_palette <- c(PropMap="#F8766D", A2A="#B79F00",
                Steal="#619CFF", StealLocal="#00BA38")

#figure_6a
ggplot(pre.factor.long,aes(x=MPI,y=cost,fill=heuristic))+geom_boxplot(outlier.size = 0.3)+
  labs(y="Estimated factorization time in second",fill="")+
  coord_cartesian(ylim=c(0.85,500))+
  scale_fill_manual(values = cb_palette)+
  guides(fill=guide_legend(nrow = 1))+
  theme(legend.position = "top", legend.background = element_blank(),legend.key = element_blank(),
        axis.text.x = element_text(angle = 30, hjust = 1, vjust = 1))
#ggsave(here::here('figure6_a.pdf'), width=12, height=9, units="cm")

#---------------------------------------
#figure_5(b) simulation cost normalized to A2A
simu.cost<-read.table(here::here('shared','simulation_cost.txt'),header = TRUE)

simu.cost$PropMap<-simu.cost$PropMap/simu.cost$a2a
simu.cost$Steal<-simu.cost$Steal/simu.cost$a2a
simu.cost$StealLocal<-simu.cost$StealLocal/simu.cost$a2a

simu.cost.long<-melt(simu.cost,id.vars = c("matrix","MPI"),variable.name = "heuristic", value.name = "cost")
simu.cost.long$MPI<-factor(simu.cost.long$MPI,levels = c("sharedM","2M12","4M6","6M4","12M2","24M1"))
simu.cost.long<-simu.cost.long[simu.cost.long$heuristic!="a2a",]
#levels(simu.cost.long$heuristic)[2]<-"A2A"
#simu.cost.long$heuristic<-factor(simu.cost.long$heuristic,levels=c("A2A","PropMap","Steal","StealLocal"))
simu.cost.long$heuristic<-factor(simu.cost.long$heuristic,levels=c("PropMap","Steal","StealLocal"))

cb_palette <- c(PropMap="#F8766D", A2A="#B79F00",
                Steal="#619CFF", StealLocal="#00BA38")

#figure_5b 
ggplot(simu.cost.long,aes(x=MPI,y=cost,fill=heuristic))+geom_boxplot(outlier.size = 0.3)+
  labs(y="Simulation cost normalized to A2A",fill="")+
  scale_fill_manual(values = cb_palette)+
  guides(fill=guide_legend(nrow = 1))+
  theme(legend.position = "top",legend.background = element_blank(),legend.key = element_blank(),
        axis.text.x = element_text(angle = 30, hjust = 1, vjust = 1, size = 8),
        axis.text.y = element_text(angle = 30, hjust = 1, vjust = 1, size = 8))
#ggsave(here::here('figure_5b.pdf'), width=12, height=9, units="cm")

#figure_6b predicted factorization time normalized to A2A
pre.factor<-read.table(here::here('shared','Predicted_factor_time.txt') ,header = TRUE)

pre.factor$PropMap<-pre.factor$PropMap/pre.factor$a2a
pre.factor$Steal<-pre.factor$Steal/pre.factor$a2a
pre.factor$StealLocal<-pre.factor$StealLocal/pre.factor$a2a

pre.factor.long<-melt(pre.factor,id.vars = c("matrix","MPI"),variable.name = "heuristic", value.name = "cost")
pre.factor.long$MPI<-factor(pre.factor.long$MPI,levels = c("sharedM","2M12","4M6","6M4","12M2","24M1"))
pre.factor.long<-pre.factor.long[pre.factor.long$heuristic!="a2a",]
#levels(pre.factor.long$heuristic)[2]<-"A2A"
#pre.factor.long$heuristic<-factor(pre.factor.long$heuristic,levels=c("A2A","PropMap","Steal","StealLocal"))
pre.factor.long$heuristic<-factor(pre.factor.long$heuristic,levels=c("PropMap","Steal","StealLocal"))

cb_palette <- c(PropMap="#F8766D", A2A="#B79F00",
                Steal="#619CFF", StealLocal="#00BA38")

#figure_6(b) 
ggplot(pre.factor.long,aes(x=MPI,y=cost,fill=heuristic))+geom_boxplot(outlier.size = 0.3)+
  labs(y="Estimated factorization time\n normalized to A2A",fill="")+
  coord_cartesian(ylim=c(0.85,1.2))+
  scale_fill_manual(values = cb_palette)+
  guides(fill=guide_legend(nrow = 1))+
  theme(legend.position = "top", legend.background = element_blank(),legend.key = element_blank(),
        axis.text.x = element_text(angle = 30, hjust = 1, vjust = 1))
#ggsave(here::here('figure_6b.pdf'), width=12, height=9, units="cm")

#---------------------------------------
#figure_7a Factorization time
factor.time<-read.table(here::here('shared','factorization_time_miriel.txt'),header = TRUE)
factor.time$PropMap<-(factor.time$propMap2+factor.time$propMap3)/3
factor.time$A2A<-(factor.time$a2a2+factor.time$a2a3)/3
factor.time$Steal<-(factor.time$steal2+factor.time$steal3)/3
factor.time$machine<-"miriel"

####factor time on machine crunch
factor.time.crunch<-read.table(here::here('pmap-crunch-sharedM-support','factorTime.txt'),header = TRUE)
factor.time.crunch$machine<-"crunch"
factor.time.crunch$PropMap<-(factor.time.crunch$propMap2+factor.time.crunch$propMap3)/3
factor.time.crunch$A2A<-(factor.time.crunch$a2a2+factor.time.crunch$a2a3)/3
factor.time.crunch$Steal<-(factor.time.crunch$steal2+factor.time.crunch$steal3)/3

factor.time.crunch<-factor.time.crunch[,c("matrix","PropMap","A2A","Steal","machine")]
factor.time.miriel<-factor.time[,c("matrix","PropMap","A2A","Steal","machine")]
factor.time<-rbind(factor.time.crunch,factor.time.miriel)

factor.time.long<-melt(factor.time,id.vars = c("matrix","machine"),variable.name = "heuristic", value.name = "time")
factor.time.long$heuristic<-factor(factor.time.long$heuristic,levels = c('A2A', 'PropMap', 'Steal'))
factor.time.long$machine<-factor(factor.time.long$machine,levels = c('miriel','crunch'))

#figure 7a
ggplot(factor.time.long,aes(x=machine,y=time,fill=heuristic))+geom_boxplot()+
  stat_summary(fun.y = "mean", mapping = aes(group =heuristic), geom = "point", 
               shape=23, size=3, fill="white",position=position_dodge(0.7))+  
  scale_fill_manual(values = cb_palette)+
  coord_cartesian(ylim = c(0,500))+
  guides(fill=guide_legend(nrow = 1))+
  theme(legend.position = c(0.5,0.95),legend.background = element_blank(),legend.key = element_blank(),
        axis.text.x = element_text(angle = 30, hjust = 1, vjust = 1, size = 8),
        axis.text.y = element_text(angle = 30, hjust = 1, vjust = 1, size = 8))+
  labs(y="Factorization time in second",fill="")
#ggsave(here::here('figure7_a.pdf'), width=12, height=9, units="cm")

#---------------------------------------
#figure_7b Factorization time normalized 
factor.time<-read.table(here::here('shared','factorization_time_miriel.txt'),header = TRUE)
factor.time$PropMap<-(factor.time$propMap2+factor.time$propMap3)/3
factor.time$A2A<-(factor.time$a2a2+factor.time$a2a3)/3
factor.time$Steal<-(factor.time$steal2+factor.time$steal3)/3
factor.time$machine<-"miriel"

####factor time on machine crunch
factor.time.crunch<-read.table(here::here('pmap-crunch-sharedM-support','factorTime.txt'),header = TRUE)
factor.time.crunch$machine<-"crunch"
factor.time.crunch$PropMap<-(factor.time.crunch$propMap2+factor.time.crunch$propMap3)/3
factor.time.crunch$A2A<-(factor.time.crunch$a2a2+factor.time.crunch$a2a3)/3
factor.time.crunch$Steal<-(factor.time.crunch$steal2+factor.time.crunch$steal3)/3

factor.time.crunch<-factor.time.crunch[,c("matrix","PropMap","A2A","Steal","machine")]
factor.time.miriel<-factor.time[,c("matrix","PropMap","A2A","Steal","machine")]
factor.time<-rbind(factor.time.crunch,factor.time.miriel)

factor.time$PropMap<-factor.time$PropMap/factor.time$A2A
factor.time$Steal<-factor.time$Steal/factor.time$A2A

factor.time.long<-melt(factor.time,id.vars = c("matrix","machine"),variable.name = "heuristic", value.name = "time")
factor.time.long<-factor.time.long[factor.time.long$heuristic%in%c('PropMap','Steal'),]
factor.time.long$heuristic<-factor(factor.time.long$heuristic,levels = c('PropMap','Steal'))
factor.time.long$machine<-factor(factor.time.long$machine,levels = c('miriel','crunch'))

#figure 7b
ggplot(factor.time.long,aes(x=machine,y=time,fill=heuristic))+geom_boxplot()+
  stat_summary(fun.y = "mean", mapping = aes(group =heuristic), geom = "point", shape=23, size=3, fill="white",position=position_dodge(0.7))+  
  scale_fill_manual(values = cb_palette)+
  theme(legend.position = c(0.3,0.95),legend.background = element_blank(),legend.key = element_blank(),
        axis.text.x = element_text(angle = 30, hjust = 1, vjust = 1, size = 8),
        axis.text.y = element_text(angle = 30, hjust = 1, vjust = 1, size = 8))+
  labs(y="Factorization time\n normalized to A2A",fill="")
#ggsave(here::here('figure_7b.pdf'), width=12, height=9, units="cm")
