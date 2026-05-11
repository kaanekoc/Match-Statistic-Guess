function cfg = api_config()
% API_CONFIG - Transfermarkt API yapılandırma dosyası
%
% Bu fonksiyon, Transfermarkt API'sine bağlanmak için gerekli olan
% tüm endpoint URL'lerini ve temel ayarları döndürür.
%
% Kullanım:
%   cfg = api_config();
%   disp(cfg.base_url);
%
% Çıktı:
%   cfg - API yapılandırma struct'ı

    % Temel URL
    cfg.base_url = 'https://www.transfermarkt.com.tr';
    
    % ---- Takım Endpoint'leri ----
    % Lige göre takım listesi: /quickselect/teams/{lig_kodu}
    cfg.endpoints.teams_by_league = '/quickselect/teams/%s';
    
    % Takım kadrosu (oyuncu listesi): /quickselect/players/{club_id}
    cfg.endpoints.team_squad = '/quickselect/players/%s';
    
    % Takımın son maç dizilişi: /ceapi/FinalFormation/ClubId/{club_id}
    cfg.endpoints.team_last_formation = '/ceapi/FinalFormation/ClubId/%s';
    
    % Takımın son maçları: /ceapi/previousMatches/team/{team_id}
    cfg.endpoints.team_previous_matches = '/ceapi/previousMatches/team/%s';
    
    % Takımın gelecek maçları: /ceapi/nextMatches/team/{team_id}
    cfg.endpoints.team_next_matches = '/ceapi/nextMatches/team/%s';
    
    % ---- Oyuncu Endpoint'leri ----
    % Oyuncu müsabaka performansı: /ceapi/player/{player_id}/performancepercompetition
    cfg.endpoints.player_competition_perf = '/ceapi/player/%s/performancepercompetition';
    
    % Oyuncu kulüp performansı: /ceapi/player/{player_id}/performance
    cfg.endpoints.player_club_perf = '/ceapi/player/%s/performance';
    
    % Oyuncunun son maçları: /ceapi/previousMatches/player/{player_id}
    cfg.endpoints.player_previous_matches = '/ceapi/previousMatches/player/%s';
    
    % Oyuncunun gelecek maçları: /ceapi/nextMatches/player/{player_id}
    cfg.endpoints.player_next_matches = '/ceapi/nextMatches/player/%s';
    
    % Oyuncu Sorare kart bilgileri: /ceapi/sorare/fetchPlayersCard/{player_id}
    cfg.endpoints.player_sorare = '/ceapi/sorare/fetchPlayersCard/%s';
    
    % ---- HTTP İstek Ayarları ----
    cfg.request.timeout = 30;           % Saniye cinsinden zaman aşımı
    cfg.request.retry_count = 3;        % Başarısız isteklerde tekrar deneme sayısı
    cfg.request.retry_delay = 2;        % Tekrar denemeler arası bekleme (saniye)
    cfg.request.user_agent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36';
    
    % ---- Lig Kodları ----
    cfg.leagues.TR1 = 'Türkiye Süper Lig';
    cfg.leagues.GB1 = 'İngiltere Premier League';
    cfg.leagues.ES1 = 'İspanya La Liga';
    cfg.leagues.IT1 = 'İtalya Serie A';
    cfg.leagues.L1  = 'Almanya Bundesliga';
    cfg.leagues.FR1 = 'Fransa Ligue 1';
    
    % ---- Veri Kayıt Ayarları ----
    cfg.data_dir = fullfile(fileparts(fileparts(mfilename('fullpath'))), 'data');
    cfg.model_dir = fullfile(fileparts(fileparts(mfilename('fullpath'))), 'models');
    
    % Klasörleri oluştur (yoksa)
    if ~exist(cfg.data_dir, 'dir')
        mkdir(cfg.data_dir);
    end
    if ~exist(cfg.model_dir, 'dir')
        mkdir(cfg.model_dir);
    end
end
