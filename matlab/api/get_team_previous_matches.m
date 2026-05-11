function matches = get_team_previous_matches(team_id, limit)
% GET_TEAM_PREVIOUS_MATCHES - Takimin son maclarini getirir
%
% Kullanim:
%   matches = get_team_previous_matches('36', 25)
%
% Girdiler:
%   team_id - Takim ID'si (string veya number)
%   limit   - Maksimum mac sayisi (varsayilan: 25)
%
% Ciktilar:
%   matches - Mac bilgilerini iceren struct
%             .teams   - Takim bilgileri lookup tablosu
%             .matches - Mac listesi

    if nargin < 2, limit = 25; end
    
    cfg = api_config();
    team_id_str = num2str(team_id);
    endpoint = sprintf(cfg.endpoints.team_previous_matches, team_id_str);
    url = sprintf('%s%s?limit=%d', cfg.base_url, endpoint, limit);
    
    fprintf('Takim son maclari cekiliyor: ID=%s (limit=%d)\n', team_id_str, limit);
    
    [data, status] = http_get(url, 'Timeout', cfg.request.timeout);
    
    if status ~= 200 || isempty(data)
        warning('GET_TEAM_PREVIOUS_MATCHES:VeriYok', ...
            'Takim ID "%s" icin mac bulunamadi.', team_id_str);
        matches = struct('teams', struct(), 'matches', []);
        return;
    end
    
    matches = data;
    
    if isfield(matches, 'matches')
        if iscell(matches.matches)
            n = numel(matches.matches);
        else
            n = numel(matches.matches);
        end
        fprintf('  %d mac bulundu.\n', n);
    end
end
