function match_table = parse_match_results(team_data)
% PARSE_MATCH_RESULTS - Ham mac verilerini analiz edilebilir tabloya donusturur
%
% API'den cekilen ham verileri isleyerek her mac icin ev/deplasman skoru,
% toplam gol, galibiyet/maglubiyet/beraberlik bilgisi cikarir.
%
% Kullanim:
%   match_table = parse_match_results(team_data)
%
% Girdiler:
%   team_data - collect_team_data() fonksiyonunun ciktisi
%
% Ciktilar:
%   match_table - MATLAB table formati:
%     MatchID, HomeTeamID, AwayTeamID, HomeGoals, AwayGoals,
%     TotalGoals, GoalDiff, IsHome, Result, Timestamp, Competition

    team_id = team_data.team_id;
    prev = team_data.previous_matches;
    
    if isempty(prev) || ~isfield(prev, 'matches') || isempty(prev.matches)
        match_table = table();
        warning('PARSE_MATCH_RESULTS:VeriYok', 'Ayristirilacak mac verisi yok.');
        return;
    end
    
    matches_raw = prev.matches;
    if iscell(matches_raw)
        n = numel(matches_raw);
    else
        n = numel(matches_raw);
    end
    
    % Degiskenleri hazirla
    MatchID = zeros(n, 1);
    HomeTeamID = zeros(n, 1);
    AwayTeamID = zeros(n, 1);
    HomeGoals = zeros(n, 1);
    AwayGoals = zeros(n, 1);
    TotalGoals = zeros(n, 1);
    GoalDiff = zeros(n, 1);
    IsHome = zeros(n, 1);
    Result = cell(n, 1);           % 'W', 'D', 'L'
    Over25 = zeros(n, 1);          % 2.5 ust: 1, alt: 0
    Timestamp = zeros(n, 1);
    Competition = cell(n, 1);
    
    valid_count = 0;
    
    for i = 1:n
        if iscell(matches_raw)
            m = matches_raw{i};
        else
            m = matches_raw(i);
        end
        
        % Sadece oynanan maclari isle
        match_info = m.match;
        if isfield(match_info, 'state') && ~strcmpi(match_info.state, 'Played')
            continue;
        end
        
        % Skoru ayristir
        result_str = match_info.result;
        if contains(result_str, ':')
            score_parts = strsplit(strtrim(result_str), ':');
            h_goals = str2double(strtrim(score_parts{1}));
            a_goals = str2double(strtrim(score_parts{2}));
            
            if isnan(h_goals) || isnan(a_goals)
                continue;
            end
        else
            continue;
        end
        
        valid_count = valid_count + 1;
        
        MatchID(valid_count) = m.id;
        HomeTeamID(valid_count) = match_info.home;
        AwayTeamID(valid_count) = match_info.away;
        HomeGoals(valid_count) = h_goals;
        AwayGoals(valid_count) = a_goals;
        TotalGoals(valid_count) = h_goals + a_goals;
        GoalDiff(valid_count) = h_goals - a_goals;
        IsHome(valid_count) = (match_info.home == team_id);
        Over25(valid_count) = (h_goals + a_goals) > 2.5;
        
        if isfield(match_info, 'time')
            Timestamp(valid_count) = match_info.time;
        end
        
        if isfield(m, 'competition') && isfield(m.competition, 'id')
            Competition{valid_count} = m.competition.id;
        else
            Competition{valid_count} = 'UNK';
        end
        
        % Sonuc belirleme (takimin perspektifinden)
        if IsHome(valid_count)
            team_goals = h_goals;
            opp_goals = a_goals;
        else
            team_goals = a_goals;
            opp_goals = h_goals;
        end
        
        if team_goals > opp_goals
            Result{valid_count} = 'W';
        elseif team_goals == opp_goals
            Result{valid_count} = 'D';
        else
            Result{valid_count} = 'L';
        end
    end
    
    % Gecerli verilerle tabloyu olustur
    if valid_count > 0
        match_table = table(...
            MatchID(1:valid_count), ...
            HomeTeamID(1:valid_count), ...
            AwayTeamID(1:valid_count), ...
            HomeGoals(1:valid_count), ...
            AwayGoals(1:valid_count), ...
            TotalGoals(1:valid_count), ...
            GoalDiff(1:valid_count), ...
            IsHome(1:valid_count), ...
            Result(1:valid_count), ...
            Over25(1:valid_count), ...
            Timestamp(1:valid_count), ...
            Competition(1:valid_count), ...
            'VariableNames', {'MatchID', 'HomeTeamID', 'AwayTeamID', ...
                              'HomeGoals', 'AwayGoals', 'TotalGoals', ...
                              'GoalDiff', 'IsHome', 'Result', 'Over25', ...
                              'Timestamp', 'Competition'});
        
        fprintf('  %d mac basariyla ayristirildi.\n', valid_count);
    else
        match_table = table();
        warning('PARSE_MATCH_RESULTS:GecerliMacYok', 'Gecerli mac verisi bulunamadi.');
    end
end
