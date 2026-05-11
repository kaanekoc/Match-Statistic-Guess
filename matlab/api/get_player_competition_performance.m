function perf = get_player_competition_performance(player_id)
% GET_PLAYER_COMPETITION_PERFORMANCE - Oyuncunun musabakalara gore performansini getirir
%
% Kullanim:
%   perf = get_player_competition_performance('433049')
%
% Girdiler:
%   player_id - Oyuncu ID'si (string veya number)
%
% Ciktilar:
%   perf - Performans verilerini iceren struct
%          .playerName   - Oyuncu adi
%          .goalkeeper    - Kaleci mi? (boolean)
%          .performances  - Musabaka bazli performans dizisi

    cfg = api_config();
    player_id_str = num2str(player_id);
    endpoint = sprintf(cfg.endpoints.player_competition_perf, player_id_str);
    url = [cfg.base_url, endpoint];
    
    fprintf('Oyuncu musabaka performansi cekiliyor: ID=%s\n', player_id_str);
    
    [data, status] = http_get(url, 'Timeout', cfg.request.timeout);
    
    if status ~= 200 || isempty(data)
        warning('GET_PLAYER_COMP_PERF:VeriYok', ...
            'Oyuncu ID "%s" icin performans bulunamadi.', player_id_str);
        perf = [];
        return;
    end
    
    perf = data;
    
    if isfield(perf, 'playerName')
        fprintf('  Oyuncu: %s\n', perf.playerName);
    end
end
