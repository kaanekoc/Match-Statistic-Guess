function team_data = collect_team_data(team_id, match_limit)
% COLLECT_TEAM_DATA - Bir takim icin tum verileri toplar
%
% API'lerden takimin son maclari, kadrosu, dizilisi ve oyuncu
% performanslarini cezip tek bir struct icerisinde birlestirir.
%
% Kullanim:
%   team_data = collect_team_data(36, 25)
%
% Girdiler:
%   team_id     - Takim Transfermarkt ID'si
%   match_limit - Cekilecek mac sayisi (varsayilan: 25)
%
% Ciktilar:
%   team_data - Tum takim verilerini iceren kapsamli struct

    if nargin < 2, match_limit = 25; end
    
    team_id_str = num2str(team_id);
    team_data = struct();
    team_data.team_id = team_id;
    team_data.collection_date = datestr(now, 'yyyy-mm-dd HH:MM:SS');
    
    fprintf('\n========================================\n');
    fprintf('TAKIM VERI TOPLAMA BASLATILIYOR\n');
    fprintf('Takim ID: %s\n', team_id_str);
    fprintf('========================================\n\n');
    
    % 1. Son maclari cek
    fprintf('[1/4] Son maclar cekiliyor...\n');
    try
        prev_matches = get_team_previous_matches(team_id, match_limit);
        team_data.previous_matches = prev_matches;
    catch ME
        warning('Son maclar cekilemedi: %s', ME.message);
        team_data.previous_matches = struct('teams', struct(), 'matches', []);
    end
    pause(1); % API rate limit icin bekleme
    
    % 2. Gelecek maclari cek
    fprintf('\n[2/4] Gelecek maclar cekiliyor...\n');
    try
        next_matches = get_team_next_matches(team_id, 10);
        team_data.next_matches = next_matches;
    catch ME
        warning('Gelecek maclar cekilemedi: %s', ME.message);
        team_data.next_matches = struct('teams', struct(), 'matches', []);
    end
    pause(1);
    
    % 3. Son mac dizilisini cek
    fprintf('\n[3/4] Son mac dizilisi cekiliyor...\n');
    try
        formation = get_team_last_formation(team_id);
        team_data.last_formation = formation;
    catch ME
        warning('Dizilis cekilemedi: %s', ME.message);
        team_data.last_formation = [];
    end
    pause(1);
    
    % 4. Kadro bilgilerini cek
    fprintf('\n[4/4] Kadro bilgileri cekiliyor...\n');
    try
        squad = get_team_squad(team_id);
        team_data.squad = squad;
    catch ME
        warning('Kadro cekilemedi: %s', ME.message);
        team_data.squad = [];
    end
    
    fprintf('\n========================================\n');
    fprintf('TAKIM VERI TOPLAMA TAMAMLANDI\n');
    fprintf('========================================\n\n');
end
