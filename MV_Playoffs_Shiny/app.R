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

LEAGUE <- 'MV'
df <- fread(paste0(LEAGUE,"_predictions_history_2019.csv"))
WEEK <- max(df$Week)

get_history_plot <- function(historydf, var_to_plot){
  history <- df %>% select(Week, Owner, var_to_plot) %>%
    arrange(desc(Week)) %>%
    arrange(desc(.[[3]]))
  history[,3] <- history[,3]*100
  # try dynamic legend
  if (var_to_plot == 'Playoffs'){
    ylimits=c(0,100)
  }
  else{
    ylimits=NULL
  }
    
  p <- ggplot(history,aes_string(x='Week', y=var_to_plot, group='Owner'), show.legend = FALSE) + 
    geom_line(aes(color=Owner)) + 
    geom_point(aes(color=Owner)) +
    theme_minimal() +
    geom_text(data=subset(history, Week == max(Week)),
              hjust = 0, nudge_x = rep_len(c(0.03,.3),length(unique(history$Owner))), 
              aes(label=Owner, color=Owner)) +
    scale_x_continuous(limits = c(0,WEEK+0.5), breaks=0:WEEK, labels=waiver()) +
    scale_y_continuous(name = paste(var_to_plot,'%'), limits = ylimits) +
    theme(legend.position = "none")
  return(p)
}

# Define UI for application that draws a histogram
ui <- fluidPage(
      
    # Show a plot of the generated distribution
    mainPanel(
      h2("Takes 12 To Tango 2019 Playoff Predictions", align = 'center'),
      
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
     current <- df %>% 
       filter(Week == WEEK) %>%
       select(-c(ID,Team, Week)) %>% 
       unite('Rec',c(Wins,Losses), sep='-', remove=TRUE) %>%
       rename('Proj_PPG' = proj_ppg) %>%
       mutate(Proj_PPG = round(Proj_PPG, 1)) %>%
       mutate('Playoffs' = percent(Playoffs, accuracy=1)) %>% 
       mutate('Semifinals' = percent(Semifinals, accuracy=1)) %>%
       mutate('Finals' = percent(Finals, accuracy=1)) %>%
       mutate('Champion' = percent(Champion, accuracy=1))
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

