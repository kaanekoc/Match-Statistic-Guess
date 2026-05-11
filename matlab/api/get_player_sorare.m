function card = get_player_sorare(player_id)
% GET_PLAYER_SORARE - Oyuncunun Sorare kart bilgilerini getirir
%
% Sorare fantazi futbol entegrasyonu uzerinden oyuncunun performans puani,
% ikili mucadele, pas isabeti gibi ozel metrikleri dondurur.
%
% Kullanim:
%   card = get_player_sorare('396638')
%
% Girdiler:
%   player_id - Oyuncu ID'si (string veya number)
%
% Ciktilar:
%   card - Sorare kart bilgileri struct
%          .score_so5              - Son 5 mac puani
%          .goals / .assists       - Gol ve asist
%          .duels_won              - Ikili mucadele
%          .pass_accuracy_quota    - Pas isabeti (0-1 arasi)
%          .clean_sheet            - Gol yenmeme sayisi

    cfg = api_config();
    player_id_str = num2str(player_id);
    endpoint = sprintf(cfg.endpoints.player_sorare, player_id_str);
    url = [cfg.base_url, endpoint];
    
    fprintf('Oyuncu Sorare bilgileri cekiliyor: ID=%s\n', player_id_str);
    
    [data, status] = http_get(url, 'Timeout', cfg.request.timeout);
    
    if status ~= 200 || isempty(data)
        warning('GET_PLAYER_SORARE:VeriYok', ...
            'Oyuncu ID "%s" icin Sorare verisi bulunamadi.', player_id_str);
        card = [];
        return;
    end
    
    card = data;
    
    if isfield(card, 'score_so5')
        fprintf('  Sorare Puani: %d\n', card.score_so5);
    end
end
