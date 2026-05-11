function features = build_match_features(home_data, away_data, n_recent)
% BUILD_MATCH_FEATURES - Iki takim icin mac tahmin ozellikleri olusturur
%
% Ev sahibi ve deplasman takimi verilerinden makine ogrenimi modelleri
% icin ozellik vektoru cikarir. Son N mac performansina dayali
% istatistiksel ozellikler hesaplar.
%
% Kullanim:
%   features = build_match_features(home_data, away_data, 5)
%
% Girdiler:
%   home_data - Ev sahibi takim verisi (collect_team_data ciktisi)
%   away_data - Deplasman takim verisi (collect_team_data ciktisi)
%   n_recent  - Son kac macin kullanilacagi (varsayilan: 5)
%
% Ciktilar:
%   features - Ozellik struct'i (tum numerik ozellikler)

    if nargin < 3, n_recent = 5; end
    
    features = struct();
    
    % ===== EV SAHIBI OZELLIKLERI =====
    home_matches = parse_match_results(home_data);
    if ~isempty(home_matches) && height(home_matches) > 0
        recent_home = home_matches(1:min(n_recent, height(home_matches)), :);
        
        % Gol istatistikleri
        features.home_avg_goals_scored = mean(cellfun(@(r, hg, ag, ih) ...
            ifthenelse(ih, hg, ag), ...
            recent_home.Result, num2cell(recent_home.HomeGoals), ...
            num2cell(recent_home.AwayGoals), num2cell(recent_home.IsHome)));
        features.home_avg_goals_conceded = mean(cellfun(@(r, hg, ag, ih) ...
            ifthenelse(ih, ag, hg), ...
            recent_home.Result, num2cell(recent_home.HomeGoals), ...
            num2cell(recent_home.AwayGoals), num2cell(recent_home.IsHome)));
        features.home_avg_total_goals = mean(recent_home.TotalGoals);
        
        % Sonuc istatistikleri
        features.home_win_rate = sum(strcmp(recent_home.Result, 'W')) / height(recent_home);
        features.home_draw_rate = sum(strcmp(recent_home.Result, 'D')) / height(recent_home);
        features.home_loss_rate = sum(strcmp(recent_home.Result, 'L')) / height(recent_home);
        
        % 2.5 ust/alt orani
        features.home_over25_rate = mean(recent_home.Over25);
        
        % Gol farki
        features.home_avg_goal_diff = mean(recent_home.GoalDiff);
        
        % Ev sahibi mac orani
        features.home_home_ratio = sum(recent_home.IsHome) / height(recent_home);
    else
        features.home_avg_goals_scored = 0;
        features.home_avg_goals_conceded = 0;
        features.home_avg_total_goals = 0;
        features.home_win_rate = 0;
        features.home_draw_rate = 0;
        features.home_loss_rate = 0;
        features.home_over25_rate = 0;
        features.home_avg_goal_diff = 0;
        features.home_home_ratio = 0;
    end
    
    % ===== DEPLASMAN OZELLIKLERI =====
    away_matches = parse_match_results(away_data);
    if ~isempty(away_matches) && height(away_matches) > 0
        recent_away = away_matches(1:min(n_recent, height(away_matches)), :);
        
        % Gol istatistikleri
        features.away_avg_goals_scored = mean(cellfun(@(r, hg, ag, ih) ...
            ifthenelse(ih, hg, ag), ...
            recent_away.Result, num2cell(recent_away.HomeGoals), ...
            num2cell(recent_away.AwayGoals), num2cell(recent_away.IsHome)));
        features.away_avg_goals_conceded = mean(cellfun(@(r, hg, ag, ih) ...
            ifthenelse(ih, ag, hg), ...
            recent_away.Result, num2cell(recent_away.HomeGoals), ...
            num2cell(recent_away.AwayGoals), num2cell(recent_away.IsHome)));
        features.away_avg_total_goals = mean(recent_away.TotalGoals);
        
        features.away_win_rate = sum(strcmp(recent_away.Result, 'W')) / height(recent_away);
        features.away_draw_rate = sum(strcmp(recent_away.Result, 'D')) / height(recent_away);
        features.away_loss_rate = sum(strcmp(recent_away.Result, 'L')) / height(recent_away);
        
        features.away_over25_rate = mean(recent_away.Over25);
        features.away_avg_goal_diff = mean(recent_away.GoalDiff);
        features.away_home_ratio = sum(recent_away.IsHome) / height(recent_away);
    else
        features.away_avg_goals_scored = 0;
        features.away_avg_goals_conceded = 0;
        features.away_avg_total_goals = 0;
        features.away_win_rate = 0;
        features.away_draw_rate = 0;
        features.away_loss_rate = 0;
        features.away_over25_rate = 0;
        features.away_avg_goal_diff = 0;
        features.away_home_ratio = 0;
    end
    
    % ===== KARSILASTIRMALI OZELLIKLER =====
    features.win_rate_diff = features.home_win_rate - features.away_win_rate;
    features.goal_diff_diff = features.home_avg_goal_diff - features.away_avg_goal_diff;
    features.attack_vs_defense = features.home_avg_goals_scored - features.away_avg_goals_conceded;
    features.combined_over25 = (features.home_over25_rate + features.away_over25_rate) / 2;
    features.combined_avg_total = (features.home_avg_total_goals + features.away_avg_total_goals) / 2;
    
    % ===== DIZILIS OZELLIKLERI =====
    if isfield(home_data, 'last_formation') && ~isempty(home_data.last_formation)
        home_form_stats = extract_formation_stats(home_data.last_formation);
        features.home_last_cards = home_form_stats.total_yellow_cards + home_form_stats.total_red_cards;
        features.home_last_goals = home_form_stats.total_goals;
    else
        features.home_last_cards = 0;
        features.home_last_goals = 0;
    end
    
    if isfield(away_data, 'last_formation') && ~isempty(away_data.last_formation)
        away_form_stats = extract_formation_stats(away_data.last_formation);
        features.away_last_cards = away_form_stats.total_yellow_cards + away_form_stats.total_red_cards;
        features.away_last_goals = away_form_stats.total_goals;
    else
        features.away_last_cards = 0;
        features.away_last_goals = 0;
    end
    
    features.combined_cards = features.home_last_cards + features.away_last_cards;
end

function val = ifthenelse(cond, true_val, false_val)
% Yardimci if-then-else fonksiyonu
    if cond
        val = true_val;
    else
        val = false_val;
    end
end
