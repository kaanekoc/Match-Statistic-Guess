function formation = get_team_last_formation(club_id)
% GET_TEAM_LAST_FORMATION - Takımın son maç dizilişini ve detaylarını getirir
%
% Son maçtaki ilk 11, yedekler, taktik diziliş, teknik direktör,
% goller, kartlar ve oyuncu değişiklikleri dahil tüm bilgileri döndürür.
%
% Kullanım:
%   formation = get_team_last_formation('36')
%
% Girdiler:
%   club_id - Takım ID'si (string veya number)
%
% Çıktılar:
%   formation - Maç diziliş bilgilerini içeren struct
%               .list       - İlk 11 ve yedekler
%               .matchInfo  - Maç bilgileri (turnuva, tarih, taktik)
%               .matchReport - Maç sonucu
%               .teams      - Karşılaşan takımlar
%               .trainer    - Teknik direktör bilgisi

    cfg = api_config();
    club_id_str = num2str(club_id);
    endpoint = sprintf(cfg.endpoints.team_last_formation, club_id_str);
    url = [cfg.base_url, endpoint];
    
    fprintf('Son maç dizilişi çekiliyor: ID=%s\n', club_id_str);
    
    [data, status] = http_get(url, 'Timeout', cfg.request.timeout);
    
    if status ~= 200 || isempty(data)
        warning('GET_TEAM_LAST_FORMATION:VeriYok', ...
            'Takım ID "%s" için diziliş bulunamadı.', club_id_str);
        formation = [];
        return;
    end
    
    formation = data;
    
    % Sonucu göster
    if isfield(formation, 'matchReport') && isfield(formation.matchReport, 'result')
        if isfield(formation, 'teams')
            fprintf('  Son Maç: %s vs %s => %s\n', ...
                formation.teams.team1.name, ...
                formation.teams.team2.name, ...
                strtrim(formation.matchReport.result));
        end
    end
end
