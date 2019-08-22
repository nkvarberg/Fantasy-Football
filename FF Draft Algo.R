set_envir <- function(){
  library(data.table)
  library(dplyr) 
}
set_envir()

load_projections <- function(){
  cols <- c('Player', 'Pos', 'Points', 'Floor', 'Ceiling', 'ADP')
  ffa <- fread("/Users/nickvarberg/Downloads/FFA_projections - Sheet1.csv", col.names=cols)
  # Create draft position DP variable
  ffa <- ffa %>% arrange(ADP) %>% tibble::rowid_to_column("DP")
  ffa <- ffa %>% group_by(Pos) %>% arrange(DP) %>% 
    mutate(posrank=order(DP)) %>% ungroup()
}
ffa <- load_projections()

draft_attributes <- function(){
  #Attributes of snake draft
  positions        <- c(2, 3, 3, 1)
  names(positions) <- c('QB', 'RB', 'WR', 'TE')
  assign('positions', positions, envir=.GlobalEnv)
  assign('PICKS_PER_ROUND', 8, envir=.GlobalEnv)
  assign('my_picks', c(3,14,19,30,35,46,51,62,67), envir=.GlobalEnv)
}
draft_attributes()

calculate_parp <- function(projections){
  # My last pick is the replacement level pick
  REPL_PICK        <- tail(my_picks,1) 
  # Replaceent points are max points you could get at that position in the last round
  RB_REPL_POINTS <- max(filter(ffa, Pos=='RB' & DP >= REPL_PICK)$Points)
  QB_REPL_POINTS <- max(filter(ffa, Pos=='QB' & DP >= REPL_PICK)$Points)
  WR_REPL_POINTS <- max(filter(ffa, Pos=='WR' & DP >= REPL_PICK)$Points)
  TE_REPL_POINTS <- max(filter(ffa, Pos=='TE' & DP >= REPL_PICK)$Points)
  projections    <- mutate(ffa, points_arp = ifelse(Pos=='RB', Points-RB_REPL_POINTS,
                                         ifelse(Pos=='QB', Points-QB_REPL_POINTS,
                                                ifelse(Pos=='WR', Points-WR_REPL_POINTS,
                                                       ifelse(Pos=='TE', Points-TE_REPL_POINTS, 0)
                                                ))))
  return(projections)
}
projections <- calculate_parp(ffa)

#### Start of Draft
# Update who I've drafted and who other's have drafted (ShinyApp)
my_drafted <- NULL
others_drafted <- NULL

# Reduce to my picks remaining
my_picks_remain <- function(my_picks, my_drafted){
  if(is.null(my_drafted)){
    return(my_picks)
  }
  else{
    return(setdiff(my_picks, my_drafted$pick))
  }
}
my_picks_remain <- my_picks_remain(my_picks, my_drafted)

# Filter to players available
players_avail   <- function(projections, my_drafted, others_drafted){
  if(is.null(my_drafted)){
    players_avail <- projections
  }
  else{
    players_avail <- projections %>% filter(!Player %in% my_drafted$Player)
  }
  if(is.null(others_drafted)){
    players_avail <- players_avail
  }
  else{
    players_avail <- players_avail %>% filter(!Player %in% others_drafted$Player)
  }
}
players_avail <- players_avail(projections, my_drafted, others_drafted)

# get_pick_values: Function to return values for each position at each pick with the players remaining
pick_values <- function(players_avail, my_picks_remain){
  for (pick in my_picks_remain){
    # Filter to plyers in the next 2 rounds after pick
    df <- players_avail %>% 
      filter(DP>=pick & DP <= pick+2*PICKS_PER_ROUND) %>% 
      group_by(Pos) %>% 
      filter(points_arp == max(points_arp)) %>%
      mutate(pick = pick) %>%
      arrange(desc(points_arp)) %>%
      ungroup() %>%
      mutate(value = (points_arp - round(mean(points_arp),2)))
    if (pick == my_picks_remain[1]){
      pick_values <- df
    }
    else{
      pick_values <- full_join(pick_values, df)
    }
  }
  return(arrange(pick_values, desc(value)))
}
pick_values <- pick_values(players_avail, my_picks_remain)

# sim_my_draft: Function thats arranges by value and chooses best values
sim_my_draft <- function(pick_values){
  # Initialize variables and select first choice
  sim_my_picks_remain <- my_picks_remain
  sim_my_drafted <- slice(best_avail, 1)
  # Draft rest of round
  while (nrow(sim_my_drafted) < nrow(sim_my_picks_remain)){
    sim_my_picks_remain <- my_picks_remain(sim_my_picks_remain, sim_my_drafted) 
    pos_filled     <- pos_filled(my_drafted, sim_my_drafted)
    if(!is.null(pos_filled)){
      
    }
    
  }
}

pos_filled <- function(my_drafted, sim_my_drafted){
  full_drafted   <- full_join(my_drafted, sim_my_drafted, by = 'Player')
  df             <- drafted %>% group_by(Pos) %>% summarise(n = n())
  num_pos        <- df %>% pull(n)
  names(num_pos) <- df %>% pull(Pos)
  pos_filled     <- c()
  for (pos in names(num_pos)){
    if (num_pos[pos] == positions[pos]){
      pos_filled <- c(pos_filled, pos)
    }
  }
  return(pos_filled)
}
