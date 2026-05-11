function stats = extract_formation_stats(formation)
% EXTRACT_FORMATION_STATS - Mac dizilisinden kart/gol/korner istatistiklerini cikarir
%
% Son mac dizilisi verisinden gol atanlar, kart gorenler,
% oyuncu degisiklikleri gibi detaylari cikarir.
%
% Kullanim:
%   stats = extract_formation_stats(formation)
%
% Girdiler:
%   formation - get_team_last_formation() ciktisi
%
% Ciktilar:
%   stats - Cikarilan istatistikleri iceren struct
%           .total_goals, .total_yellow_cards, .total_red_cards,
%           .substitution_count, .goal_scorers, .card_holders

    stats = struct();
    stats.total_goals = 0;
    stats.total_yellow_cards = 0;
    stats.total_red_cards = 0;
    stats.substitution_count = 0;
    stats.goal_scorers = {};
    stats.card_holders = {};
    stats.goal_times = [];
    stats.card_times = [];
    stats.tactic = '';
    stats.result = '';
    
    if isempty(formation)
        return;
    end
    
    % Taktik bilgisi
    if isfield(formation, 'matchInfo') && isfield(formation.matchInfo, 'tactic')
        stats.tactic = formation.matchInfo.tactic;
    end
    
    % Mac sonucu
    if isfield(formation, 'matchReport') && isfield(formation.matchReport, 'result')
        stats.result = strtrim(formation.matchReport.result);
    end
    
    % Tum oyunculari birles (ilk 11 + yedekler)
    all_players = {};
    if isfield(formation, 'list')
        if isfield(formation.list, 'players')
            players = formation.list.players;
            if iscell(players)
                all_players = [all_players; players(:)];
            elseif isstruct(players)
                for p = 1:numel(players)
                    all_players{end+1} = players(p); %#ok<AGROW>
                end
            end
        end
        if isfield(formation.list, 'substitutes')
            subs = formation.list.substitutes;
            if iscell(subs)
                all_players = [all_players; subs(:)];
            elseif isstruct(subs)
                for p = 1:numel(subs)
                    all_players{end+1} = subs(p); %#ok<AGROW>
                end
            end
        end
    end
    
    % Her oyuncunun aksiyonlarini isle
    for i = 1:numel(all_players)
        if iscell(all_players)
            player = all_players{i};
        else
            player = all_players(i);
        end
        
        if ~isfield(player, 'actions')
            continue;
        end
        
        actions = player.actions;
        player_name = '';
        if isfield(player, 'name')
            player_name = player.name;
        elseif isfield(player, 'shortName')
            player_name = player.shortName;
        end
        
        % Golleri isle
        if isfield(actions, 'goals') && ~isempty(actions.goals)
            goals = actions.goals;
            if iscell(goals)
                for g = 1:numel(goals)
                    stats.total_goals = stats.total_goals + 1;
                    stats.goal_scorers{end+1} = player_name;
                    if isfield(goals{g}, 'time') && isfield(goals{g}.time, 'minute')
                        stats.goal_times(end+1) = str2double(goals{g}.time.minute);
                    end
                end
            elseif isstruct(goals)
                for g = 1:numel(goals)
                    stats.total_goals = stats.total_goals + 1;
                    stats.goal_scorers{end+1} = player_name;
                    if isfield(goals(g), 'time') && isfield(goals(g).time, 'minute')
                        stats.goal_times(end+1) = str2double(goals(g).time.minute);
                    end
                end
            end
        end
        
        % Kartlari isle
        if isfield(actions, 'cards') && ~isempty(actions.cards)
            cards = actions.cards;
            if iscell(cards)
                for c = 1:numel(cards)
                    card = cards{c};
                    if isfield(card, 'type')
                        if strcmpi(card.type, 'gelb')
                            stats.total_yellow_cards = stats.total_yellow_cards + 1;
                        elseif strcmpi(card.type, 'rot') || strcmpi(card.type, 'gelbrot')
                            stats.total_red_cards = stats.total_red_cards + 1;
                        end
                    end
                    stats.card_holders{end+1} = player_name;
                    if isfield(card, 'time') && isfield(card.time, 'minute')
                        stats.card_times(end+1) = str2double(card.time.minute);
                    end
                end
            elseif isstruct(cards)
                for c = 1:numel(cards)
                    card = cards(c);
                    if isfield(card, 'type')
                        if strcmpi(card.type, 'gelb')
                            stats.total_yellow_cards = stats.total_yellow_cards + 1;
                        elseif strcmpi(card.type, 'rot') || strcmpi(card.type, 'gelbrot')
                            stats.total_red_cards = stats.total_red_cards + 1;
                        end
                    end
                    stats.card_holders{end+1} = player_name;
                    if isfield(card, 'time') && isfield(card.time, 'minute')
                        stats.card_times(end+1) = str2double(card.time.minute);
                    end
                end
            end
        end
        
        % Degisiklikleri isle
        if isfield(actions, 'substitution') && ~isempty(actions.substitution)
            sub = actions.substitution;
            if isstruct(sub)
                stats.substitution_count = stats.substitution_count + 1;
            end
        end
    end
end
