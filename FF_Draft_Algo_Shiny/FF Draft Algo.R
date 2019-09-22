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
  assign('MY_PICKS', c(3,14,19,30,35,46,51,62,67), envir=.GlobalEnv)
}
draft_attributes()

calculate_parp <- function(projections){
  # My last pick is the replacement level pick
  REPL_PICK        <- tail(MY_PICKS,1) 
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


# Update who I've drafted and who other's have drafted (ShinyApp)
my_drafted <- NULL
others_drafted <- slice(projections, 21)

#### Start of Rest-of-Draft Simulation
# Reduce to my picks remaining
get_picks_remain <- function(my_picks, my_drafted){
  if(is.null(my_drafted)){ return(my_picks)
  } else{ return(setdiff(my_picks, my_drafted$pick))}
}
# Filter to players available
get_players_avail <- function(projections, my_drafted, others_drafted){
  if(is.null(my_drafted)){ players_avail <- projections
  } else{
    players_avail <- projections %>% filter(!Player %in% my_drafted$Player)
  }
  if(is.null(others_drafted)){ players_avail <- players_avail
  } else{
    players_avail <- players_avail %>% filter(!Player %in% others_drafted$Player)
  }
}
# Return value of each position at each pick among players remaining
get_pick_values <- function(players_avail, my_picks_remain){
  for (pick in my_picks_remain){
    # Filter to plyers in the next 2 rounds after pick
    df <- players_avail %>% 
      filter(DP>=pick & DP <= pick+2*PICKS_PER_ROUND) %>% 
      group_by(Pos) %>% 
      filter(points_arp == max(points_arp)) %>%
      mutate(pick = pick) %>%
      arrange(desc(points_arp)) %>%
      ungroup() %>%
      mutate(value = (points_arp - round(mean(points_arp),2))) %>%
      select('pick', 'Player', 'Pos', 'Points', 'points_arp', 'DP', 'value')
    if (pick == my_picks_remain[1]){
      pick_values <- df
    }
    else{
      pick_values <- full_join(pick_values, df)
    }
  }
  return(arrange(pick_values, desc(value)))
}
# Check if postions are filled by my drafted players
get_pos_filled <- function(all_drafted){
  df             <- all_drafted %>% group_by(Pos) %>% summarise(n = n())
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

# Choose best value at any pick first, then recalculate values
sim_my_draft <- function(projections, my_picks_remain){
  # Initialize variables and select first choice
  my_picks_remain <- get_picks_remain(MY_PICKS, my_drafted)
  players_avail <- get_players_avail(projections, my_drafted, others_drafted)
  pick_values <- get_pick_values(players_avail, my_picks_remain)
  sim_my_drafted <- slice(pick_values, 1)
  my_picks_remain <- get_picks_remain(my_picks_remain, sim_my_drafted)
  # Draft rest of round
  while (length(my_picks_remain) > 0){
    if(is.null(my_drafted)){all_drafted <- sim_my_drafted 
    } else{all_drafted <- full_join(my_drafted, sim_my_drafted, by='Player')}
    players_avail  <- players_avail %>% filter(!Player %in% all_drafted$Player)
    pos_filled     <- get_pos_filled(all_drafted)
    if(!is.null(pos_filled)){
      players_avail <- players_avail %>% filter(!Pos %in% pos_filled)
    }
    pick_values <- get_pick_values(players_avail, my_picks_remain)
    sim_my_drafted <- full_join(sim_my_drafted, slice(pick_values,1))
    my_picks_remain <- get_picks_remain(my_picks_remain, sim_my_drafted)
  }
  print(arrange(sim_my_drafted, pick))
}

# test
sim_my_draft(projections, my_picks_remain)

##
library('shiny')
runExample('01_Hello')
runApp("FF_Draft_Algo_Shiny")
