#
# This is a Shiny web application. You can run the application by clicking
# the 'Run App' button above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)
library(DT)
library(data.table)
library(tibble)
library(scales)
library(dplyr)
#library(ggplot2)
library(plotly)
library(tidyr)

LEAGUE <- 'VL'
df <- fread(paste0(LEAGUE,"_predictions_history_2019.csv"))
WEEK <- max(df$Week)

get_history_plot <- function(historydf, var_to_plot){
  history <- df %>% select(Week, Owner, var_to_plot) %>%
    arrange(desc(Week)) %>%
    arrange(desc(.[[3]]))
  history[,3] <- history[,3]*100
  color_palette = c('#66FF33', '#000000', '#FF6666', '#006600',
                    '#0033FF', '#660066', '#663300', '#FFCC00',
                    '#FF9966', '#FF0033', '#3399FF', '#666666')
  p <- ggplot(history,aes_string(x='Week', y=var_to_plot, group='Owner'), show.legend = FALSE) + 
    geom_line(aes(color=Owner)) + 
    geom_point(aes(color=Owner)) +
    theme_minimal() +
    geom_text(data=subset(history, Week == max(Week)),
              hjust = 0, nudge_x = rep_len(c(0.03,.4),length(unique(history$Owner))), 
              aes(label=Owner, color=Owner)) +
    scale_color_manual(values=color_palette) +
    scale_x_continuous(limits = c(0,WEEK+0.75), breaks=0:WEEK, labels=waiver(), name = 'After Week') +
    scale_y_continuous(name = paste(var_to_plot,'%')) +
    theme(legend.position = "none")
  return(p)
}

# Define UI for application that draws a histogram
ui <- fluidPage(
      
    # Show a plot of the generated distribution
    mainPanel(
      
      h2("Varberg-Lindquist 2019 Playoff Predictions", align = 'center'),
      
        h3("How these predictions work:", align = 'center'),
              
              h6("I gather preseason point projections for each player from fantasyfootballanlytics.net, who claim
                 to have the most accurate projections. From these player projections and from the performance of each
                 team so far in the season, I project the points per game (proj_ppg) for each team. 
                 I model each team's score each remaining week as a normal distribution with their
                 proj_ppg as the mean and 25 (arbitrary) as the standard deviation. Then I similate the rest of the
                 season 30,000 times to determine how far each team is likely to go.", align = 'center'),
              
              tabsetPanel(
                tabPanel("Current Prediction", div(DT::dataTableOutput("preds2019"),
                                                   style = "font-size: 80%; width: 10%"
                                                   )
                         ), 
                tabPanel("Playoff History", plotOutput("Playoffplot")),
                tabPanel("Champion History", plotOutput("Championplot"))
              )
    )
)

# Define server logic required to draw a histogram
server <- function(input, output) {
  
  output$preds2019 <- DT::renderDataTable({
    
    P_Change = rep(0, length(unique(df$ID)))
    Ch_Change = rep(0, length(unique(df$ID)))
    Win_Change = rep('L', length(unique(df$ID)))
    if (WEEK > 0){
      ids <- filter(df, Week == WEEK)$ID
      for (i  in 1:length(ids)){
        id = ids[i]
        current = df %>% filter(Week == WEEK) %>% filter(ID == id) %>% select(Playoffs, Champion, Wins)
        last = df %>% filter(Week == WEEK-1) %>% filter(ID == id) %>% select(Playoffs, Champion, Wins)
        P_Change[i] = round(current$Playoffs - last$Playoffs, 3)
        Ch_Change[i] = round(current$Champion - last$Champion, 3)
        if (current$Wins - last$Wins == 1){
          Win_Change[i] = 'W' 
        }
      }
    }
    
    current <- df %>% 
      filter(Week == WEEK) %>%
      unite('Rec',c(Wins,Losses), sep='-', remove=TRUE) %>%
      mutate('Last' = Win_Change) %>%
      rename('Proj_PPG' = proj_ppg) %>%
      mutate(Proj_PPG = round(Proj_PPG, 1)) %>%
      mutate('Playoffs' = Playoffs*100) %>% 
      mutate('±Plyf' = P_Change*100) %>%
      mutate('Champion' = Champion*100) %>%
      mutate('±Chmp' = Ch_Change*100) %>%
      select(Owner, Rec, Last, Proj_PPG, Playoffs, '±Plyf', Champion, '±Chmp') %>%
      arrange(Champion)
    currentDT <- DT::datatable(current,
                               options = list(dom = 't', pageLength = 12,
                                              fixedColumns = list(leftColumns = 1, rightColumns = 0),
                                              autoWidth = TRUE,
                                              columnDefs = list( list( className = 'dt-center', targets = 1:7),
                                                                 list(width = '100px', targets = "_all"))
                               )
    )
    return(currentDT)
  })
   
  output$Playoffplot <- renderPlot({
     p <- get_history_plot(df, 'Playoffs')
     return(p)
  })
  
  output$Championplot <- renderPlot({
    p <- get_history_plot(df, 'Champion')
    return(p)
  })
   
}

# Run the application 
shinyApp(ui = ui, server = server)

