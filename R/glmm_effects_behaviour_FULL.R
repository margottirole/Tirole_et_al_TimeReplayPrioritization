library(lmerTest) 
library(afex)
library(emmeans)
library(optimx)


args <- commandArgs(trailingOnly = TRUE)

kv <- list(); i <- 1L
while (i <= length(args)) {
  key <- args[[i]]
  if (!startsWith(key, "--")) { i <- i + 1L; next }
  if (i == length(args)) { kv[[substr(key, 3L, nchar(key))]] <- TRUE; break }
  val <- args[[i+1L]]
  if (startsWith(val, "--")) { kv[[substr(key, 3L, nchar(key))]] <- TRUE; i <- i + 1L; next }
  kv[[substr(key, 3L, nchar(key))]] <- val
  i <- i + 2L
}
getk <- function(k, default=NULL) if (!is.null(kv[[k]])) kv[[k]] else default


load_path <- getk("load_path")
save_path <- getk("save_path")
wd_path <- getk("wd_path")
setwd(wd_path)


# LOAD -----------------------------------------------------------------

dt_TRACKS <- read.csv(load_path, header=T, sep=",")

dt_TRACKS$rat= factor(dt_TRACKS$rat)
dt_TRACKS$track = factor(dt_TRACKS$track)
dt_TRACKS$reward = factor(dt_TRACKS$reward, levels=c('HIGH','LOW'))
dt_TRACKS$session = factor(dt_TRACKS$session)
# set contrasts
contrasts(dt_TRACKS$reward) <- contr.sum(2, contrasts= TRUE)
contrasts(dt_TRACKS$track) <- contr.sum(3, contrasts= TRUE)
contrasts(dt_TRACKS$session) <- contr.sum(6, contrasts= TRUE)

f_numLaps <- as.formula('number_of_laps ~ reward * track + (1 | rat/session)')
f_total_imm <- as.formula('total_imm ~ reward * track + (1 | rat/session)')
f_total_imm_END <- as.formula('total_imm_END ~ reward * track + (1 | rat/session)')
f_time_run_zones_immobile_per_min <- as.formula('time_run_zones_immobile_per_min ~ reward * track + (1 | rat/session)')
f_run_speed <- as.formula('run_speed ~ reward * track + (1 | rat/session)')
f_stop_speed <- as.formula('stop_speed ~ reward * track + (  1| rat/session)')

allF= list(f_numLaps,f_total_imm,f_total_imm_END,
           f_time_run_zones_immobile_per_min,f_run_speed,f_stop_speed)

for (f in allF) {
  
  if (as.character(as.formula(f))[2] %in% names(dt_TRACKS)) {

  # run GLMM
  m1_rate <- mixed(f,
            data = dt_TRACKS,
            expand_re = TRUE,
            check_contrasts= TRUE,
            all_fit = TRUE)
  summary(m1_rate)
  anova(m1_rate)
  
  # SUMMARIES --------------------------------------------------------------
  emm_reward <- emmeans(m1_rate$full_model, ~ reward, type = "response")
  c_reward <- contrast(emm_reward, "pairwise")
  emm_rec <- emmeans(m1_rate$full_model, ~ track, type = "response")
  c_rec <- contrast(emm_rec, "pairwise")
  emm_simple <- emmeans(m1_rate$full_model, ~ reward | track, type = "response")
  c_simple <- contrast(emm_simple, "pairwise")
  emm_interact <- contrast(emmeans(m1_rate$full_model, ~ track * reward  , type = "response"), interaction =c("pairwise","pairwise"))
  c_interact <- contrast(emmeans(m1_rate$full_model, ~ track * reward  , type = "response"), interaction =c("pairwise","pairwise"))
  
  out_emm <- rbind(emm_reward,emm_rec,emm_simple,emm_interact)
  out_c <- rbind(c_reward,c_rec,c_simple,c_interact)
  
  # report these values
  out_c <- update(out_c, adjust= 'none') # figure out pvalue for sidak 1 - (1- alpha)^(1/num contrasts). alpha=0.05*3 because 3 families, num contrasts= 10
  alpha <- 1 - (1- 0.05*3)^(1/ 10)
  # need to adjust pval and set alpha level for confint
  out2 <- update(out_c, adjust= 'sidak')
  CI <- confint(out2, level= 1 - 0.05*3)
  
  df_simple <- as.data.frame(c_simple)
  df_rec <- as.data.frame(c_rec)
  df_eff_interact <- as.data.frame(c_interact)
  out_c <- as.data.frame(out_c)
  out2 <- as.data.frame(out2)
  out_emm <- as.data.frame(out_emm)
  out_c$label <- c("(HIGH-LOW)",
                    df_rec$contrast,
                    paste0("T", df_simple$track, " (HIGH-LOW)"),
                    paste0("T: ",df_eff_interact$track_pairwise,": (HIGH-LOW)"))

  out_c$alpha <- alpha
  out_c$p_sidak <- out2$p.value
  out_c$estimate <- CI$estimate
  out_c$SE <- CI$SE
  out_c$CI_low <- CI$lower.CL
  out_c$CI_high <- CI$upper.CL
  out_c$RateRatio  <- exp(out_c$estimate)
  out_c$CI_low_RR  <- exp(out_c$CI_low)
  out_c$CI_high_RR <- exp(out_c$CI_high)
  
  
  ### SAVE
  dep_var = as.character(as.formula(f))[2]
  if (save_path == ''){
    for (subdir in c("contrasts", "emmeans", "anova")) {
      dir.create(file.path(subdir),recursive = TRUE,showWarnings = FALSE)
    }
  write.csv(out_c, file.path("contrasts",paste0("behaviour_contrasts_",dep_var,".csv")), row.names = FALSE)
  write.csv(out_emm, file.path("emmeans",paste0("behaviour_emmeans_",dep_var,".csv")), row.names = FALSE)
  write.csv(as.data.frame(anova(m1_rate)),file.path("anova",paste0("anova_behaviour_",dep_var,".csv")), row.names = TRUE)
  }
  else {
    for (subdir in c("contrasts", "emmeans", "anova")) {
      dir.create(file.path(save_path, subdir),recursive = TRUE,showWarnings = FALSE)
    }
    dir.create(file.path(save_path), showWarnings = FALSE)
    write.csv(out_c, file.path(save_path,"contrasts",paste0("behaviour_contrasts_",dep_var,".csv")), row.names = FALSE)
    write.csv(out_emm, file.path(save_path,"emmeans",paste0("behaviour_emmeans_",dep_var,".csv")), row.names = FALSE)
    write.csv(as.data.frame(anova(m1_rate)),file.path(save_path,"anova",paste0("anova_behaviour_",dep_var,".csv")), row.names = TRUE)
    }
  
  }

}


