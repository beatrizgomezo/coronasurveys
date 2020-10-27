library(lubridate)
library(useful)
library(dplyr)
# smoothed p_cases and CI:
source("smooth_column-v2.R")

estimates_path <- "../data/estimates-provinces/"
plots_path <- "../data/estimates-provinces/plots/"

# estimates_path <- "./estimates-provinces/"
# plots_path <- "./estimates-provinces/plots/"


smooth_param <- 15
age_recent <- 3


## Load data ----
df <- read.csv(paste0(estimates_path, "ES/ESM-estimate.csv"))
df <- df %>% select(date, p_recentcases, p_recentcases_error, 
                    p_cases, p_cases_error, p_stillsick, p_stillsick_error)
df$date <- as.Date(df$date)

# df <- tail(df, n=(nrow(df)-211))
df <- df[df$date >= ymd("2020-10-01"),]

df$date <- df$date - (age_recent-1)/2

#shift recent cases
df$recent_shifted <- df$p_recentcases
df <- smooth_column(df_in = df, 
                        col_s = "recent_shifted", 
                        basis_dim = smooth_param,
                        link_in = "log")
df$recent_error_shifted <- df$p_recentcases_error

len <- nrow(df)
df$recent_shifted[1:(len-3)] <- df$recent_shifted[4:len]
df$recent_shifted_smooth[1:(len-3)] <- df$recent_shifted_smooth[4:len]
df$recent_error_shifted[1:(len-3)] <- df$recent_error_shifted[4:len]
df$recent_shifted[(len-2):len] <- df$recent_shifted_smooth[(len-2):len] <-
  df$recent_error_shifted[(len-2):len] <- NA

## Non-monotonic ----
df <- smooth_column(df_in = df, 
                        col_s = "p_recentcases", 
                        basis_dim = smooth_param,
                        link_in = "log")

df <- smooth_column(df_in = df, 
                        col_s = "p_stillsick", 
                        basis_dim = smooth_param,
                        link_in = "log")

# colors <- c("Nuevos casos" = "red", "recent_c" = "red", "sick_c" = "blue", "Sintomáticos" = "blue")
p1 <- ggplot(data = df, aes(x = date, color = ""))  +
  geom_rect(xmin = ymd("2020-10-03"), xmax = ymd("2020-10-04"),
                ymin = 0, ymax = Inf, 
              alpha = 0.01, color = "orange", size = 0.1, fill = "yellow") +
  geom_rect(xmin = ymd("2020-10-10"), xmax = ymd("2020-10-11"),
            ymin = 0, ymax = Inf, 
            alpha = 0.01, color = "orange", size = 0.1, fill = "yellow") +
  geom_rect(xmin = ymd("2020-10-17"), xmax = ymd("2020-10-18"),
            ymin = 0, ymax = Inf, 
            alpha = 0.01, color = "orange", size = 0.1, fill = "yellow") +
  geom_rect(xmin = ymd("2020-10-24"), xmax = ymd("2020-10-25"),
            ymin = 0, ymax = Inf, 
            alpha = 0.01, color = "orange", size = 0.1, fill = "yellow") +
  #
  # geom_vline(aes(xintercept = ymd("2020-10-03"), color = "Fin_de_semana"),
  #            linetype="solid")+
  # geom_vline(aes(xintercept = ymd("2020-10-04"), color = "Fin_de_semana"),
  #            linetype="solid")+
  # geom_vline(aes(xintercept = ymd("2020-10-11"), color = "Fin_de_semana"),
  #            linetype="solid")+
  # geom_vline(aes(xintercept = ymd("2020-10-18"), color = "Fin_de_semana"),
  #            linetype="solid")+
  # geom_vline(aes(xintercept = ymd("2020-10-25"), color = "Fin_de_semana"),
  #            linetype="solid")+
  #
  geom_rect(xmin = ymd("2020-10-02"), xmax = ymd("2020-10-08"),
          ymin = 0, ymax = 100, 
          alpha = 0.01, color = "orange", size = 0.1, fill = "magenta") +
  geom_rect(xmin = ymd("2020-10-09"), xmax = ymd("2020-10-24"),
            ymin = 0, ymax = 100, 
            alpha = 0.01, color = "orange", size = 0.1, fill = "magenta") +
  geom_rect(xmin = ymd("2020-10-25"), xmax = ymd("2020-11-08"),
            ymin = 0, ymax = 100, 
            alpha = 0.01, color = "orange", size = 0.1, fill = "magenta") +
  # geom_vline(aes(xintercept = ymd("2020-10-24"), color = "Cierre"), 
  #            linetype="dotted", size=1)+
  # geom_vline(aes(xintercept = ymd("2020-10-09"), color = "Cierre"), 
  #            linetype="dotted", size=1)+
  geom_point(aes(y = recent_shifted*100000, color = "Nuevos casos (7 días)"), 
             alpha = 0.5, size = 2) +
  geom_line(aes(y = recent_shifted_smooth*100000, color = "Nuevos casos (7 días)"), 
            linetype = "solid", size = 1, alpha = 0.6) +
  geom_ribbon(aes(ymin = (recent_shifted_smooth-recent_error_shifted)*100000, 
                  ymax = (recent_shifted_smooth+recent_error_shifted)*100000), 
              alpha = 0.1, color = "red", size = 0.1, fill = "red") +
  geom_point(aes(y = p_stillsick*100000, color = "Sintomáticos"), alpha = 0.5, size = 2) +
  geom_line(aes(y = p_stillsick_smooth*100000, color = "Sintomáticos"), 
            linetype = "solid", size = 1, alpha = 0.6) +
  geom_ribbon(aes(ymin = (p_stillsick_smooth-p_stillsick_error)*100000, 
                  ymax = (p_stillsick_smooth+p_stillsick_error)*100000), 
              alpha = 0.1, color = "blue", size = 0.1, fill = "blue") +
  labs(x = "Fecha", y =  "Casos por 100.000 habitantes") +
  # ylim(0, 3000)+
  theme_bw() + 
  ggtitle("Incidencia en Madrid") +
  scale_colour_manual(values = c("red", "blue", "blue"),
                      name="",
                      guide = guide_legend(override.aes = list(
                        linetype = c(#"dotted", 
                                     # "dotted", "blank", "solid", 
                                     "solid", "solid"),
                        shape = c(#NA, 
                                  # NA, 1, NA, 
                                  1, 1)))) +
  theme(legend.position = "bottom")
#p1

ggsave(plot = p1, 
       filename =  paste0(plots_path, "ESM-recent-plot.jpg"), 
       width = 9, height = 6)

# df_out <- smooth_column(df_in = df, 
#                         col_s = "p_cases", 
#                         basis_dim = 15, link_in = "log", monotone = T)
# 
# df_out$p_cases_smooth_log <- df_out$p_cases_smooth
# df_out <- df_out %>% select(date, p_cases_smooth_log, p_cases)
# 
# df_out <- smooth_column(df_in = df_out, 
#                         col_s = "p_cases", 
#                         basis_dim = 15, monotone = T)
# df_out$p_cases_smooth_id <- df_out$p_cases_smooth
# 
# colors <- c("cases" = "orange", "smooth_log" = "red", "smooth_id" = "blue")
# p2 <- ggplot(data = df_out, aes(x = date, color = Legend))  +
#   geom_point(aes(y = p_cases, color = "cases"), alpha = 0.4, size = 1) +
#   geom_line(aes(y = p_cases_smooth_log, color = "smooth_log"), size = 0.8, alpha = 0.6) +
#   geom_line(aes(y = p_cases_smooth_id, color = "smooth_id"), size = 0.8, alpha = 0.6) +
#   theme_bw() + ggtitle("Monotone smoothing (positive vs. unrestricted)") +
#   scale_color_manual(values = colors, name = "") + 
#   theme(legend.position = "bottom") 
# p2

