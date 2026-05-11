function teams = get_league_teams(league_code)
% GET_LEAGUE_TEAMS - Belirtilen ligdeki tüm takımları getirir
%
% Transfermarkt API'sinden belirtilen lig koduna ait takım listesini çeker.
%
% Kullanım:
%   teams = get_league_teams('TR1')    % Türkiye Süper Lig
%   teams = get_league_teams('GB1')    % İngiltere Premier League
%
% Girdiler:
%   league_code - Lig kodu (string): 'TR1', 'GB1', 'ES1', 'IT1', 'L1', 'FR1'
%
% Çıktılar:
%   teams - Takım bilgilerini içeren struct dizisi
%           .id   - Takım ID'si (number)
%           .name - Takım adı (string)
%           .link - Transfermarkt profil linki (string)

    cfg = api_config();
    endpoint = sprintf(cfg.endpoints.teams_by_league, league_code);
    url = [cfg.base_url, endpoint];
    
    fprintf('Lig takımları çekiliyor: %s\n', league_code);
    
    [data, status] = http_get(url, ...
        'Timeout', cfg.request.timeout, ...
        'RetryCount', cfg.request.retry_count);
    
    if status ~= 200 || isempty(data)
        warning('GET_LEAGUE_TEAMS:VeriYok', ...
            'Lig kodu "%s" için takım bulunamadı.', league_code);
        teams = [];
        return;
    end
    
    % Cell array ise struct dizisine çevir
    if iscell(data)
        teams = [data{:}];
    else
        teams = data;
    end
    
    fprintf('  %d takım bulundu.\n', numel(teams));
end
