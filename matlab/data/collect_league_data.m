function league_data = collect_league_data(league_code, match_limit)
% COLLECT_LEAGUE_DATA - Bir ligdeki tum takimlarin verilerini toplar
%
% Belirtilen ligdeki tum takimlari bulur ve her birinin son maclarini,
% kadrosunu ve dizilisini cekereren kapsamli bir veri seti olusturur.
%
% Kullanim:
%   league_data = collect_league_data('TR1', 25)
%
% Girdiler:
%   league_code - Lig kodu ('TR1', 'GB1', 'ES1', vb.)
%   match_limit - Her takim icin cekilecek mac sayisi (varsayilan: 20)
%
% Ciktilar:
%   league_data - Lig verilerini iceren struct
%                 .league_code   - Lig kodu
%                 .teams         - Takim listesi
%                 .team_details  - Her takim icin detayli veriler

    if nargin < 2, match_limit = 20; end
    
    league_data = struct();
    league_data.league_code = league_code;
    league_data.collection_date = datestr(now, 'yyyy-mm-dd HH:MM:SS');
    
    fprintf('\n################################################################\n');
    fprintf('LIG VERI TOPLAMA BASLATILIYOR: %s\n', league_code);
    fprintf('################################################################\n\n');
    
    % Takimlari cek
    teams = get_league_teams(league_code);
    if isempty(teams)
        warning('COLLECT_LEAGUE_DATA:TakimYok', ...
            'Lig "%s" icin takim bulunamadi.', league_code);
        return;
    end
    
    league_data.teams = teams;
    num_teams = numel(teams);
    
    fprintf('\nToplam %d takim icin veri toplanacak.\n\n', num_teams);
    
    % Her takim icin veri topla
    team_details = cell(num_teams, 1);
    
    for i = 1:num_teams
        if isstruct(teams)
            team = teams(i);
        else
            team = teams{i};
        end
        
        fprintf('\n--- [%d/%d] %s (ID: %d) ---\n', ...
            i, num_teams, team.name, team.id);
        
        try
            team_details{i} = collect_team_data(team.id, match_limit);
            team_details{i}.team_name = team.name;
        catch ME
            warning('Takim verisi toplanamadi: %s - %s', team.name, ME.message);
            team_details{i} = struct('team_id', team.id, ...
                                     'team_name', team.name, ...
                                     'error', ME.message);
        end
        
        % API rate limit icin takimlar arasi bekleme
        if i < num_teams
            fprintf('API bekleme suresi (3 saniye)...\n');
            pause(3);
        end
    end
    
    league_data.team_details = team_details;
    
    % Veriyi kaydet
    cfg = api_config();
    save_path = fullfile(cfg.data_dir, ...
        sprintf('%s_league_data_%s.mat', league_code, datestr(now, 'yyyymmdd')));
    save(save_path, 'league_data', '-v7.3');
    fprintf('\nLig verisi kaydedildi: %s\n', save_path);
    
    fprintf('\n################################################################\n');
    fprintf('LIG VERI TOPLAMA TAMAMLANDI: %s\n', league_code);
    fprintf('################################################################\n\n');
end
