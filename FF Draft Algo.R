library(data.table)
library(dplyr)
cols <- c('Player', 'Pos', 'Points', 'Floor', 'Ceiling', 'ADP')
ffa <- fread("/Users/nickvarberg/Downloads/FFA_projections - Sheet1.csv", col.names=cols)
# Create draft position DP variable
ffa <- ffa %>% arrange(ADP) %>% tibble::rowid_to_column("DP")
ffa <- ffa %>% group_by(Pos) %>% arrange(DP) %>% 
  mutate(posrank=order(DP)) %>% ungroup()

#Attributes of snake draft
positions       <- c('QB', 'RB', 'WR', 'TE')
PICKS_PER_ROUND <- 8
my_picks        <- c(6,11,22,27,38,43,54,59,70)
# My last pick is the replacement level pick
REPL_PICK       <- tail(my_picks,1) 
# Replaceent points are max points you could get at that position in the last round
RB_REPL_POINTS <- max(filter(ffa, Pos=='RB' & DP >= REPL_PICK)$Points)
QB_REPL_POINTS <- max(filter(ffa, Pos=='QB' & DP >= REPL_PICK)$Points)
WR_REPL_POINTS <- max(filter(ffa, Pos=='WR' & DP >= REPL_PICK)$Points)
TE_REPL_POINTS <- max(filter(ffa, Pos=='TE' & DP >= REPL_PICK)$Points)
ffa <- mutate(ffa, points_arp = ifelse(Pos=='RB', Points-RB_REPL_POINTS,
                                ifelse(Pos=='QB', Points-QB_REPL_POINTS,
                                ifelse(Pos=='WR', Points-WR_REPL_POINTS,
                                ifelse(Pos=='TE', Points-TE_REPL_POINTS, 0)
                                ))))
tbl_list <- c()
for (pick in my_picks){
  # Filter to plyers in the next 2 rounds after pick
  pick_vals <- ffa %>% 
    filter(DP>=pick & DP <= pick+2*PICKS_PER_ROUND) %>% 
    group_by(Pos) %>% 
    filter(points_arp == max(points_arp)) %>%
    mutate(pick = pick) %>%
    mutate(posvalue = (points_arp - max(points_arp))) %>%
    select(pick, Player, Pos, posrank, Points, DP, points_arp, posvalue) %>%
    arrange(desc(points_arp)) %>%
    ungroup() %>%
    mutate(points_arp_value = (points_arp - mean(points_arp)))
  tbl_list <- c(tbl_list, pick_vals)
  #row_add <- c(max_vals$QB, max_vals$RB, max_vals$WR, max_vals$TE)
  #for(pos in 'RB'){
    # Filter to the players at the position of interest
    #pot_players_pos <- filter(pot_players, Pos==pos)
    #if (dim(pot_players_pos[1] > 0)){
    #  max_points_pos <- max(pot_players_pos$Points)
    #}
    #else{
    #  max_points_pos = NA
    #}
  #}
}



# Nick: create function, linear or logistic for points expected at pick.
#  Then calculate points above expected at the pick.

# In general our goal is to optimize set of players at position 
#  i.e. draft RBs in 1st, 3rd, 5th, and 6th rounds.