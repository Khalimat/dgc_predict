library(ggplot2)
library(dplyr)
library(plotrix)
library(R.matlab)
library(tidyr)

#### COMPUTE ROC AND AUC CURVES FOR OVERALL TENSOR #########
colors = GetMethodColors()
methods = names(colors)
percDEG = c(1,10)
out = list()

for(i in 1:length(percDEG)){
  print(i)
  D = TensorDEG(tensors$meas, normGene=FALSE, method='sig', percDEG=percDEG[i], symmetric=FALSE)$D
  labels = as.vector(abs(D))
  idx = which(!is.na(labels))
  labels = labels[idx]
  for(method in methods){
    print(method)
    tensor = tensors$cv[[method]]
    ranked_tensor = RankSigs(abs(tensor))
    out[[method]][[i]] = ComputeAUC(as.vector(ranked_tensor[idx]), labels, computeROC=TRUE, abs=TRUE)
  }
}

#### PLOT ####################################################
  pdf(PlotDir('ROC_DEGs.pdf'), width=8, height=7)
  lwd=5
  lty = c(1, 3)
  legend_str = c()
  par(mar=c(5,6,4,2))
  n_roc = 200
  roc = list()
  
  for(i in 1:length(percDEG)){
    for(method in methods){
      roc[[method]] = SubsetROC(out[[method]][[i]]$roc, n_roc)
    }
    lt = lty[i]
    
    if(i == 1){
      plot(roc[['mean']]$fpr, roc[['mean']]$tpr, xlab='FPR', ylab='TPR', type='l', col=colors$mean,
           lwd=lwd, ylim=c(0,1), cex.lab=2.0, cex.axis=1.5, lty=lt)
    }else if(i > 1){
      lines(roc[['mean']]$fpr, roc[['mean']]$tpr, col=colors$mean, lwd=lwd, type='l', lty=lt)
    }
    lines(roc[['mean2']]$fpr, roc[['mean2']]$tpr, col=colors$mean2, lwd=lwd, type='l', lty=lt)
    lines(roc[['dnpp']]$fpr, roc[['dnpp']]$tpr, col=colors$dnpp, lwd=lwd, type='l', lty=lt)
    lines(roc[['tensor']]$fpr, roc[['tensor']]$tpr, col=colors$tensor, lwd=lwd, type='l',lty=lt)
    
    legend_str = c(legend_str, sprintf('Tensor, %0.0f%% DEG, AUC=%0.2f', percDEG[i], out[['tensor']][[i]]$auc))
    legend_str = c(legend_str, sprintf('DNPP, %0.0f%% DEG, AUC=%0.2f', percDEG[i], out[['dnpp']][[i]]$auc))
    legend_str = c(legend_str, sprintf('2D-Mean, %0.0f%% DEG, AUC=%0.2f', percDEG[i], out[['mean2']][[i]]$auc))
    legend_str = c(legend_str, sprintf('1D-Mean, %0.0f%% DEG, AUC=%0.2f', percDEG[i], out[['mean']][[i]]$auc))
  }
  lines(c(0,1), c(0,1), lwd=2, col='black', lty=3)
  all_colors = unlist(c(rep(c(colors$tensor, colors$dnpp, colors$mean2, colors$mean), 2), 'black'))
  legend('bottomright', lwd=4, legend=c(legend_str, 'random'), 
         col=all_colors, lty=c(1, 1, 1, 1, 3, 3, 3, 3, 3), cex=1.28) 
  dev.off()
