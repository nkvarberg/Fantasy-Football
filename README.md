# Fantasy-Football
Playoff predictions for managers in an ESPN Fantasy Football League.

### Playoff Projections for 2019 ESPN Fantasy Football Leagues
I use the preseason player projections from fantasyfootballanalytics.net to 
To get the team names, owners, schedule, team records and team rosters, I use an ESPN Fantasy Football API connection from https://github.com/cwendt94/ff-espn-api. (Check other ESPN API functions from this article https://stmorse.github.io/journal/espn-fantasy-v3.html).
I blend each team's preseaon player projections wtih the team's performance throughout the season to project the points per game of each team. Then, I similate the rest of the season and the playoffs 30,000 times to estimate how far each team is likely to go.

Here is what the homepage looks like:

![homepage](https://github.com/nkvarberg/Fantasy-Football/blob/master/Screenshots/Homepageright.png)


I show how predictions for each team's playoff chances have changed over time:

![playoffs](https://github.com/nkvarberg/Fantasy-Football/blob/master/Screenshots/Playoffs.png)

### Future Features
Predictions for whom each manager will select as a keeper.

Player rater that has rest-of-season and keeper values for each player.

Historical draft-rater and waivers-rater for each manager in league.

'Games' tab where you get predictions for each game and can see how potential outcome affects your playoff percentages.

## Optimized Draft Based on Preseason Rankings
