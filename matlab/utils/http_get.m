function [data, status] = http_get(url, varargin)
% HTTP_GET - URL'den JSON verisi çeken yardımcı fonksiyon
%
% Transfermarkt API'sine HTTP GET isteği gönderir ve JSON yanıtını
% MATLAB struct/cell olarak ayrıştırır. Hata yönetimi ve tekrar deneme
% mekanizması içerir.
%
% Kullanım:
%   [data, status] = http_get(url)
%   [data, status] = http_get(url, 'Timeout', 30)
%   [data, status] = http_get(url, 'RetryCount', 3)
%
% Girdiler:
%   url        - İstek gönderilecek tam URL (string)
%
% İsteğe Bağlı Parametreler:
%   Timeout    - Zaman aşımı süresi (saniye), varsayılan: 30
%   RetryCount - Tekrar deneme sayısı, varsayılan: 3
%   RetryDelay - Denemeler arası bekleme (saniye), varsayılan: 2
%
% Çıktılar:
%   data   - Ayrıştırılmış JSON verisi (struct/cell/array)
%   status - HTTP durum kodu (200, 404, vb.)

    p = inputParser;
    addRequired(p, 'url', @ischar);
    addParameter(p, 'Timeout', 30, @isnumeric);
    addParameter(p, 'RetryCount', 3, @isnumeric);
    addParameter(p, 'RetryDelay', 2, @isnumeric);
    parse(p, url, varargin{:});
    
    timeout = p.Results.Timeout;
    retryCount = p.Results.RetryCount;
    retryDelay = p.Results.RetryDelay;
    
    data = [];
    status = 0;
    
    % HTTP seçeneklerini ayarla
    options = weboptions(...
        'Timeout', timeout, ...
        'ContentType', 'json', ...
        'UserAgent', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36', ...
        'HeaderFields', {'Accept', 'application/json'; ...
                         'Accept-Language', 'tr-TR,tr;q=0.9'});
    
    % Tekrar deneme mekanizması ile istek gönder
    for attempt = 1:retryCount
        try
            data = webread(url, options);
            status = 200;
            return;
        catch ME
            % HTTP hata kodunu çıkar
            if contains(ME.message, '404')
                status = 404;
                warning('HTTP_GET:NotFound', ...
                    'Kaynak bulunamadı (404): %s', url);
                return;
            elseif contains(ME.message, '429')
                status = 429;
                warning('HTTP_GET:RateLimited', ...
                    'İstek sınırına ulaşıldı (429). Bekleniyor...');
                pause(retryDelay * attempt * 2);
            elseif contains(ME.message, '500')
                status = 500;
                warning('HTTP_GET:ServerError', ...
                    'Sunucu hatası (500): %s', url);
            else
                status = -1;
            end
            
            if attempt < retryCount
                fprintf('  [Deneme %d/%d] Bağlantı hatası. %d saniye sonra tekrar denenecek...\n', ...
                    attempt, retryCount, retryDelay * attempt);
                pause(retryDelay * attempt);
            else
                warning('HTTP_GET:AllRetries', ...
                    'Tüm denemeler başarısız oldu: %s\nHata: %s', url, ME.message);
            end
        end
    end
end
