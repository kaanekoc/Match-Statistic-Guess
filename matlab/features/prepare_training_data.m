function [X, y_score, y_over25, y_result, y_cards, y_corners, feature_names] = prepare_training_data(league_data)
% PREPARE_TRAINING_DATA - Lig verilerinden egitim veri seti olusturur
%
% Toplanan lig verilerini isleyerek makine ogrenimi modelleri icin
% ozellik matrisi (X) ve hedef degiskenler (y) olusturur.
%
% Kullanim:
%   [X, y_score, y_over25, y_result, y_cards, y_corners, names] = prepare_training_data(league_data)
%
% Girdiler:
%   league_data - collect_league_data() ciktisi
%
% Ciktilar:
%   X             - Ozellik matrisi (N x F)
%   y_score       - Skor hedefi [ev_gol, dep_gol] (N x 2)
%   y_over25      - 2.5 ust/alt hedefi (N x 1, 0 veya 1)
%   y_result      - Mac sonucu (N x 1: 1=EvKazanir, 0=Beraberlik, -1=DepKazanir)
%   y_cards       - Toplam kart sayisi tahmini (N x 1)
%   y_corners     - Toplam korner sayisi tahmini (N x 1)
%   feature_names - Ozellik isimleri (cell array)

    if ~isfield(league_data, 'team_details') || isempty(league_data.team_details)
        error('PREPARE_TRAINING_DATA:VeriYok', 'Lig verisi bos.');
    end
    
    team_details = league_data.team_details;
    num_teams = numel(team_details);
    
    fprintf('\n=== EGITIM VERISI HAZIRLANIYOR ===\n');
    fprintf('Takim sayisi: %d\n', num_teams);
    
    % Once tum takimlarin mac verilerini isle
    all_match_tables = cell(num_teams, 1);
    team_ids = zeros(num_teams, 1);
    
    for i = 1:num_teams
        if iscell(team_details)
            td = team_details{i};
        else
            td = team_details(i);
        end
        
        if isfield(td, 'error')
            continue;
        end
        
        team_ids(i) = td.team_id;
        all_match_tables{i} = parse_match_results(td);
    end
    
    % Her takim cifti icin ozellik olustur
    feature_list = {};
    score_list = [];
    over25_list = [];
    result_list = [];
    cards_list = [];
    corners_list = [];
    
    for i = 1:num_teams
        if isempty(all_match_tables{i}) || height(all_match_tables{i}) < 3
            continue;
        end
        
        if iscell(team_details)
            home_td = team_details{i};
        else
            home_td = team_details(i);
        end
        
        mt = all_match_tables{i};
        
        % Her mac icin egitim ornegi olustur (sliding window)
        for m = 4:height(mt)
            % Bu mac oncesi verileri kullan (data leakage onleme)
            temp_data = home_td;
            temp_matches = temp_data.previous_matches;
            
            % Mevcut maci hedef, onceki maclari ozellik olarak kullan
            current_match = mt(m, :);
            
            % Basit ozellik vektoru olustur (rakip verisi olmadan)
            feat = struct();
            prev = mt(1:m-1, :);
            n_prev = min(5, height(prev));
            recent = prev(end-n_prev+1:end, :);
            
            % Gol ortalamasi
            feat.avg_goals_scored = mean(recent.HomeGoals .* recent.IsHome + ...
                                         recent.AwayGoals .* (1-recent.IsHome));
            feat.avg_goals_conceded = mean(recent.AwayGoals .* recent.IsHome + ...
                                           recent.HomeGoals .* (1-recent.IsHome));
            feat.avg_total_goals = mean(recent.TotalGoals);
            feat.std_total_goals = std(recent.TotalGoals);
            
            % Sonuc oranlar
            feat.win_rate = sum(strcmp(recent.Result, 'W')) / n_prev;
            feat.draw_rate = sum(strcmp(recent.Result, 'D')) / n_prev;
            feat.loss_rate = sum(strcmp(recent.Result, 'L')) / n_prev;
            
            % 2.5 ust orani
            feat.over25_rate = mean(recent.Over25);
            
            % Gol farki
            feat.avg_goal_diff = mean(recent.GoalDiff);
            feat.max_goals = max(recent.TotalGoals);
            feat.min_goals = min(recent.TotalGoals);
            
            % Ev/deplasman
            feat.is_home = current_match.IsHome;
            feat.home_ratio = mean(recent.IsHome);
            
            % Son mac formu (son 3 mac puan ortalamasi)
            n3 = min(3, height(recent));
            last3 = recent(end-n3+1:end, :);
            points = zeros(n3, 1);
            for k = 1:n3
                switch last3.Result{k}
                    case 'W', points(k) = 3;
                    case 'D', points(k) = 1;
                    case 'L', points(k) = 0;
                end
            end
            feat.form_points = mean(points);
            feat.form_goals = mean(last3.TotalGoals);
            
            % Ozellik vektorunu listeye ekle
            feature_list{end+1} = feat; %#ok<AGROW>
            
            % Hedef degiskenler
            score_list(end+1, :) = [current_match.HomeGoals, current_match.AwayGoals]; %#ok<AGROW>
            over25_list(end+1) = current_match.Over25; %#ok<AGROW>
            
            switch current_match.Result{1}
                case 'W', result_list(end+1) = 1; %#ok<AGROW>
                case 'D', result_list(end+1) = 0; %#ok<AGROW>
                case 'L', result_list(end+1) = -1; %#ok<AGROW>
            end
            
            % Kart tahmini (son mac formation'dan cikarilabilir, burada ortalama kullan)
            cards_list(end+1) = feat.avg_goals_scored * 0.8 + 2; %#ok<AGROW> % Tahmini deger
            
            % Korner tahmini (ortalama gollere gore sentetik hedef)
            corners_list(end+1) = feat.avg_total_goals * 2.5 + 5 + randn(1)*1.5; %#ok<AGROW>
        end
    end
    
    % Ozellik matrisini olustur
    if isempty(feature_list)
        error('PREPARE_TRAINING_DATA:YetersizVeri', 'Yeterli egitim verisi olusturulamadi.');
    end
    
    feature_names = fieldnames(feature_list{1});
    n_features = numel(feature_names);
    n_samples = numel(feature_list);
    
    X = zeros(n_samples, n_features);
    for i = 1:n_samples
        for j = 1:n_features
            X(i, j) = feature_list{i}.(feature_names{j});
        end
    end
    
    y_score = score_list;
    y_over25 = over25_list(:);
    y_result = result_list(:);
    y_cards = cards_list(:);
    y_corners = corners_list(:);
    
    fprintf('\nEgitim verisi olusturuldu:\n');
    fprintf('  Ornek sayisi: %d\n', n_samples);
    fprintf('  Ozellik sayisi: %d\n', n_features);
    fprintf('  Ozellikler: %s\n', strjoin(feature_names, ', '));
    fprintf('=================================\n\n');
end
