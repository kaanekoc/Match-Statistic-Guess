function squad = get_team_squad(club_id)
% GET_TEAM_SQUAD - Takımın güncel kadrosunu getirir
%
% Kullanım:
%   squad = get_team_squad('36')  % Fenerbahçe kadrosu
%
% Girdiler:
%   club_id - Takım ID'si (string veya number)
%
% Çıktılar:
%   squad - Oyuncu bilgilerini içeren struct dizisi
%           .id          - Oyuncu ID'si
%           .name        - Oyuncu adı
%           .shirtNumber - Forma numarası
%           .positionId  - Mevki ID'si (1:Kaleci, 2:Defans, 3:OrtaSaha, 4:Forvet)

    cfg = api_config();
    club_id_str = num2str(club_id);
    endpoint = sprintf(cfg.endpoints.team_squad, club_id_str);
    url = [cfg.base_url, endpoint];
    
    fprintf('Takım kadrosu çekiliyor: ID=%s\n', club_id_str);
    
    [data, status] = http_get(url, 'Timeout', cfg.request.timeout);
    
    if status ~= 200 || isempty(data)
        warning('GET_TEAM_SQUAD:VeriYok', ...
            'Takım ID "%s" için kadro bulunamadı.', club_id_str);
        squad = [];
        return;
    end
    
    if iscell(data)
        squad = [data{:}];
    else
        squad = data;
    end
    
    fprintf('  %d oyuncu bulundu.\n', numel(squad));
end
