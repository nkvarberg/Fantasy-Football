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
my_picks        <- c(3,14,19,30,35,46,51,62,67)
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

# Function to return values for each position at each pick with the players remaining
get_pick_values <- function(players_avail, my_picks_remain){
  for (pick in my_picks){
    # Filter to plyers in the next 2 rounds after pick
    df <- players_avail %>% 
      filter(DP>=pick & DP <= pick+2*PICKS_PER_ROUND) %>% 
      group_by(Pos) %>% 
      filter(points_arp == max(points_arp)) %>%
      mutate(pick = pick) %>%
      select(pick, Player, Pos, posrank, Points, DP, points_arp) %>%
      arrange(desc(points_arp)) %>%
      ungroup() %>%
      mutate(value = (points_arp - round(mean(points_arp),2)))
    if (pick == my_picks[1]){
      pick_values <- df
    }
    else{
      pick_values <- full_join(pick_values, df)
    }
  }
  return(pick_values)
}
pick_values     <- get_pick_values(ffa, my_picks)

