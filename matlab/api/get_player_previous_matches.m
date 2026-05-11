function matches = get_player_previous_matches(player_id, limit)
% GET_PLAYER_PREVIOUS_MATCHES - Oyuncunun son maclarini getirir
%
% Kullanim:
%   matches = get_player_previous_matches('433049', 25)
%
% Girdiler:
%   player_id - Oyuncu ID'si (string veya number)
%   limit     - Maksimum mac sayisi (varsayilan: 25)
%
% Ciktilar:
%   matches - Mac bilgilerini iceren struct
%             .teams   - Takim bilgileri lookup tablosu
%             .matches - Mac listesi

    if nargin < 2, limit = 25; end
    
    cfg = api_config();
    player_id_str = num2str(player_id);
    endpoint = sprintf(cfg.endpoints.player_previous_matches, player_id_str);
    url = sprintf('%s%s?limit=%d', cfg.base_url, endpoint, limit);
    
    fprintf('Oyuncu son maclari cekiliyor: ID=%s (limit=%d)\n', player_id_str, limit);
    
    [data, status] = http_get(url, 'Timeout', cfg.request.timeout);
    
    if status ~= 200 || isempty(data)
        warning('GET_PLAYER_PREV_MATCHES:VeriYok', ...
            'Oyuncu ID "%s" icin mac bulunamadi.', player_id_str);
        matches = struct('teams', struct(), 'matches', []);
        return;
    end
    
    matches = data;
end
