function perf = get_player_seasonal_performance(player_id)
% GET_PLAYER_SEASONAL_PERFORMANCE - Oyuncunun sezonluk detayli performansini getirir
%
% Her sezon ve musabaka icin ayri ayri mac, gol, asist, kart,
% ilk 11 orani, dakika orani gibi detayli istatistikleri dondurur.
%
% Kullanim:
%   perf = get_player_seasonal_performance('433049')
%
% Girdiler:
%   player_id - Oyuncu ID'si (string veya number)
%
% Ciktilar:
%   perf - Sezonluk performans struct dizisi
%          Her eleman: .nameSeason, .competitionDescription,
%                      .gamesPlayed, .goalsScored, .assists,
%                      .yellowCards, .redCards, .minutesPlayed, vb.

    cfg = api_config();
    player_id_str = num2str(player_id);
    endpoint = sprintf(cfg.endpoints.player_club_perf, player_id_str);
    url = [cfg.base_url, endpoint];
    
    fprintf('Oyuncu sezonluk performansi cekiliyor: ID=%s\n', player_id_str);
    
    [data, status] = http_get(url, 'Timeout', cfg.request.timeout);
    
    if status ~= 200 || isempty(data)
        warning('GET_PLAYER_SEASONAL:VeriYok', ...
            'Oyuncu ID "%s" icin sezonluk performans bulunamadi.', player_id_str);
        perf = [];
        return;
    end
    
    perf = data;
    
    if isstruct(perf) && isfield(perf, 'performances')
        if iscell(perf.performances)
            n = numel(perf.performances);
        else
            n = numel(perf.performances);
        end
        fprintf('  %d kulup performansi bulundu.\n', n);
    elseif iscell(perf)
        fprintf('  %d sezonluk kayit bulundu.\n', numel(perf));
    end
end
