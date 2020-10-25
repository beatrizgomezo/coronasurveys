## Plots of batched-smoothed estimates (by country)

Plots represent the effect of several d = population / batch_size.

### Folders

Some trials comparing the effect of filling the blanks (NA's) due to the batching procedure (variable: *batched_pct_cli*). We tried different possibilities:

* **fill_pct_cli_smooth_pre_batched_smoothing_only_1st_and_last**: filling in only the first and last NA elements, using the first and last *pct_cli_smooth*. Only then, the estimates are smoothed. 

* **fill_pct_cli_smooth_pre_batched_smoothing**: filling in all the NA's before and after the first and last non-NA, respectively. We use *batched_pct_cli* to fill in and then the estimates are smoothed. 

* **fill_pct_cli_pre_batched_smoothing**: filling in all the NA's before and after the first and last non-NA, respectively. We use *pct_cli* to fill in and then the estimates are smoothed. 

* **fill_pct_cli_smooth_post_batched_smoothing**: we smooth the batched estimates. Then, we discard the estimates obtained for the NA's before and after the first and last non-NA, respectively. Instead, we use the *pct_cli_smooth* estimates.

* **d_15000**: estimates for all the countries using d = 15000.