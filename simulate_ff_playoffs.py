if __name__ == "__main__":
    import pandas as pd
    import numpy as np
    from ff_espn_api import League

    swid = np.genfromtxt('espn_swid.txt', dtype='str')
    espn_s2 = np.genfromtxt('espn_s2.txt', dtype='str')

    for mv_or_vl in ['mv', 'vl']:
        YEAR = 2019

        if mv_or_vl == 'vl':
            # Varberg-Lindquist League
            league_id = 1086928
        else:
            # Mounds View League
            league_id = 200140
        league = League(league_id, YEAR, espn_s2, swid)

        # convert from ID to Owner
        if mv_or_vl == 'mv':
            id_to_owner = {1: 'Hunt', 2: 'Tim', 3: 'Henry', 4: 'Nick J', 5: 'Chance',
                           6: 'Plaz', 7: 'Tucker', 8: 'Varbs', 9: 'Griff', 10: 'TJ', 11: 'Peter',
                           12: 'Sam'}
        else:
            id_to_owner = {1: 'Nick', 2: 'Zach', 3: 'Jordan', 4: 'Andrew', 5: 'Tom',
                           6: 'Tim', 7: 'Nathan', 8: 'Timmy'}

        # get week number and weeks remaining
        WEEK = league.teams[0].wins + league.teams[0].losses

        if mv_or_vl == 'vl':
            NUM_WEEKS = 11
            NUM_PLAY_WEEKS = 6
        else:
            NUM_WEEKS = 12
            NUM_PLAY_WEEKS = 4

        #### Preseason
        if WEEK == 0:
            # Replacement points dict for all positions
            repl_points = {'QB': 263,
                           'WR': 100,
                           'TE': 83,
                           'K': 130,
                           'RB': 82,
                           'D/ST': 93}
            # Load FFA preseason projections
            data_name = 'FFA_Projections_2019.csv'
            pre_projections = pd.read_csv(data_name)
            pre_projections = pre_projections.set_index('name_espn')
            # give each player on roster preseason projections
            for team in league.teams:
                for player in team.roster:
                    if player.name in pre_projections.index:
                        player.pre_proj_ppg = np.round(pre_projections.loc[player.name, 'Points'] / 16, 2)
                    elif player.name == 'Mike Evans':
                        player.pre_proj_ppg = np.round(186 / 16, 2)
                    else:
                        player.pre_proj_ppg = np.round(repl_points[player.position] / 16, 2)
                        print(player.name + ' not found so I guess I\'ll give him ' + str(player.pre_proj_ppg))
            # Create Team best lineup pre_proj_ppg
            if mv_or_vl == 'vl':
                slots = ['QB', 'QB', 'RB', 'RB', 'WR', 'WR', 'WR', 'TE', 'RB/WR/TE', 'K']
                STD_DEV = 30
                half_ppr_factor = 1
            else:
                slots = ['QB', 'RB', 'RB', 'WR', 'WR', 'TE', 'RB/WR/TE', 'D/ST', 'K']
                STD_DEV = 25
                half_ppr_factor = 1.2
            for team in league.teams:
                team.pre_proj_std_dev = std_dev
                team.pre_proj_ppg = 0
                players_used = []
                while len(players_used) < len(slots):
                    for slot in slots:
                        max_points = 0
                        for player in team.roster:
                            if (slot in player.eligibleSlots) & (player not in players_used) & (
                                    player.pre_proj_ppg > max_points):
                                max_points = player.pre_proj_ppg
                                max_player = player
                        team.pre_proj_ppg += max_points
                        players_used.append(max_player)
            ave_pre_proj_ppg = sum(team.pre_proj_ppg for team in league.teams) / len(league.teams)
            for team in league.teams:
                team.pre_proj_ppg_mod = np.round((team.pre_proj_ppg + ave_pre_proj_ppg) / 2 * half_ppr_factor, 1)
        ## Midseason recover preseason predictions
        else:
            STOP_MEAN_UNC = 12
            mid_weight = min(WEEK / STOP_MEAN_UNC, 1) ** (1 / 2)
            if mv_or_vl == 'mv':
                path = 'MV_Playoffs_Shiny/'
                name = 'MV_predictions_history_' + str(YEAR) + '.csv'
                pre_proj = pd.read_csv(path + name)
                STD_DEV = 25
                # uncertainty in actual mean ppg going forward
                STD_DEV_MEAN = max(20 - WEEK, 10)
            else:
                path = 'VL_Playoffs_Shiny/'
                name = 'VL_predictions_history_' + str(YEAR) + '.csv'
                pre_proj = pd.read_csv(path + name)
                STD_DEV = 30
                # uncertainty in actual mean ppg going forward
                STD_DEV_MEAN = max(20 - WEEK, 10)
            for team in league.teams:
                pre_proj_ppg = pre_proj[(pre_proj['ID'] == team.team_id) &
                                        (pre_proj['Week'] == 0)]['proj_ppg'].values[0]
                team.pre_proj_ppg = pre_proj_ppg


        # create remaining schedule: list of weeks, each week is list of matchups
        schedule = []
        for game in range(WEEK, NUM_WEEKS):
            week_sched = []
            for team in league.teams:
                if ((team not in week_sched) & (team.schedule[game] not in week_sched)):
                    week_sched.append(team)
                    week_sched.append(team.schedule[game])
            schedule.append(week_sched)

        # Midseason
        if WEEK > 0:
            for team in league.teams:
                ppg = np.round(sum(team.scores[0:WEEK]) / WEEK, 2)
                team.ppg = ppg
                STOP_PRE_PROJ = 12
                mid_weight = min(WEEK / STOP_PRE_PROJ, 1) ** (1 / 2)
                team.proj_ppg = np.round(mid_weight * team.ppg + (1 - mid_weight) * team.pre_proj_ppg, 2)
                team.proj_std_dev = STD_DEV
        # Preseason
        else:
            for team in league.teams:
                team.proj_ppg = team.pre_proj_ppg_mod
                team.proj_std_dev = team.pre_proj_std_dev


        for team in league.teams:
            team.sim_fst = 0
            team.sim_semi = 0
            team.sim_final = 0
            team.sim_champ = 0
        #### Start iterations
        ## Sim Regular Season
        iters = 30000
        for iterations in range(0, iters):
            for team in league.teams:
                team.sim_wins = team.wins
                team.sim_losses = team.losses
                # simulate proj_ppg with some uncertainty in the mean
                team.sim_proj_ppg = np.random.normal(team.proj_ppg, STD_DEV_MEAN)
                team.sim_weeks = np.random.normal(team.sim_proj_ppg, team.proj_std_dev, NUM_WEEKS - WEEK)
                team.sim_points_for = sum(team.sim_weeks)
            for week in range(0, len(schedule)):
                for game_num in range(0, len(schedule[week]), 2):
                    team1 = schedule[week][game_num]
                    team2 = schedule[week][game_num + 1]
                    if (team1.sim_weeks[week] > team2.sim_weeks[week]):
                        team1.sim_wins += 1
                        team2.sim_losses += 1
                    else:
                        team1.sim_losses += 1
                        team2.sim_wins += 1
            # Sort by sim_points_for, then sort by sim_wins to get standing
            standings = sorted(league.teams, key=lambda x: x.sim_points_for, reverse=True)
            standings = sorted(standings, key=lambda x: x.sim_wins, reverse=True)
            ## Sim Playoffs
            # Varberg-Lindquist
            if mv_or_vl == 'vl':
                for team in standings[0:7]:
                    team.sim_fst += 1
                    team.sim_play = np.random.normal(team.sim_proj_ppg, team.proj_std_dev, NUM_PLAY_WEEKS)
                fst_rd = [0, 1]  # first two element of sim_play
                semi_1 = standings[0]
                if sum(standings[3].sim_play[fst_rd]) > sum(standings[4].sim_play[fst_rd]):
                    semi_2 = standings[3]
                else:
                    semi_2 = standings[4]
                if sum(standings[2].sim_play[fst_rd]) > sum(standings[5].sim_play[fst_rd]):
                    semi_3 = standings[2]
                else:
                    semi_3 = standings[5]
                if sum(standings[1].sim_play[fst_rd]) > sum(standings[6].sim_play[fst_rd]):
                    semi_4 = standings[1]
                else:
                    semi_4 = standings[6]
                semi_1.sim_semi += 1
                semi_2.sim_semi += 1
                semi_3.sim_semi += 1
                semi_4.sim_semi += 1
                semi = [2, 3]  # elements of sim_play
                if sum(semi_1.sim_play[semi]) > sum(semi_2.sim_play[semi]):
                    final_1 = semi_1
                else:
                    final_1 = semi_2
                if sum(semi_3.sim_play[semi]) > sum(semi_4.sim_play[semi]):
                    final_2 = semi_3
                else:
                    final_2 = semi_4
                final_1.sim_final += 1
                final_2.sim_final += 1
                champ = [4, 5]  # elements of sim_play
                if sum(final_1.sim_play[champ]) > sum(final_2.sim_play[champ]):
                    champ = final_1
                else:
                    champ = final_2
                champ.sim_champ += 1
            # Mounds View
            else:
                for team in standings[0:6]:
                    team.sim_fst += 1
                    team.sim_play = np.random.normal(team.sim_proj_ppg, team.proj_std_dev, NUM_PLAY_WEEKS)
                fst_rd = 0
                semi_1 = standings[0]
                semi_4 = standings[1]
                if standings[3].sim_play[fst_rd] > standings[4].sim_play[fst_rd]:
                    semi_2 = standings[3]
                else:
                    semi_2 = standings[4]
                if standings[2].sim_play[fst_rd] > standings[5].sim_play[fst_rd]:
                    semi_3 = standings[2]
                else:
                    semi_3 = standings[5]
                semi_1.sim_semi += 1
                semi_2.sim_semi += 1
                semi_3.sim_semi += 1
                semi_4.sim_semi += 1
                semi = 1  # 2nd element of sim_play
                if semi_1.sim_play[semi] > semi_2.sim_play[semi]:
                    final_1 = semi_1
                else:
                    final_1 = semi_2
                if semi_3.sim_play[semi] > semi_4.sim_play[semi]:
                    final_2 = semi_3
                else:
                    final_2 = semi_4
                final_1.sim_final += 1
                final_2.sim_final += 1
                champ = [2, 3]  # 3rd and 4th element of sim_play
                if sum(final_1.sim_play[champ]) > sum(final_2.sim_play[champ]):
                    champ = final_1
                else:
                    champ = final_2
                champ.sim_champ += 1

        # Create dataframe with teams data
        tm_ids = []
        tm_nm_list = []
        abbrev = []
        wins = []
        losses = []
        proj_ppg_list = []
        fst_list = []
        semi_list = []
        final_list = []
        champ_list = []
        for team in league.teams:
            tm_ids.append(team.team_id)
            tm_nm_list.append(team.team_name)
            abbrev.append(team.team_abbrev)
            wins.append(team.wins)
            losses.append(team.losses)
            proj_ppg_list.append(team.proj_ppg)
            fst_list.append(np.round(team.sim_fst / iters, 3))
            semi_list.append(np.round(team.sim_semi / iters, 3))
            final_list.append(np.round(team.sim_final / iters, 3))
            champ_list.append(np.round(team.sim_champ / iters, 3))
        teamsdf = pd.DataFrame({'ID': tm_ids})
        # teamsdf = teamsdf.set_index('ID')
        teamsdf['Owner'] = [id_to_owner[tm_id] for tm_id in tm_ids]
        teamsdf['Team'] = tm_nm_list
        teamsdf['Wins'] = wins
        teamsdf['Losses'] = losses
        teamsdf['proj_ppg'] = proj_ppg_list
        teamsdf['Playoffs'] = fst_list
        teamsdf['Semifinals'] = semi_list
        teamsdf['Finals'] = final_list
        teamsdf['Champion'] = champ_list
        teamsdf = teamsdf.sort_values(by='Playoffs', ascending=False)
        teamsdf = teamsdf.sort_values(by='Champion', ascending=False)

        # get teamsdf ready to merge with history
        # Mounds View
        if mv_or_vl == 'mv':
            path = 'MV_Playoffs_Shiny/'
            name = 'MV_predictions_history_' + str(YEAR) + '.csv'

        # VL
        if mv_or_vl == 'vl':
            path = 'VL_Playoffs_Shiny/'
            name = 'VL_predictions_history_' + str(YEAR) + '.csv'

        new = teamsdf.loc[:,
              ['ID', 'Owner', 'Team', 'Wins', 'Losses', 'proj_ppg', 'Playoffs', 'Semifinals', 'Finals', 'Champion']]
        new['Week'] = [str(WEEK)] * len(league.teams)

        # history df
        if WEEK == 0:
            historydf = new
        # When History already created
        else:
            old = pd.read_csv(path + name, index_col=False)
            old = old[old['Week'] < WEEK]
            historydf = pd.concat([old, new], sort=False)
        # save the dataframe
        pd.DataFrame.to_csv(historydf, path + name, index=False)