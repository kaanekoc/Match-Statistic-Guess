function json_save(data, filepath)
% JSON_SAVE - MATLAB verisini JSON dosyası olarak kaydeder
%
% Kullanım:
%   json_save(data, 'data/takim_verileri.json')
%
% Girdiler:
%   data     - Kaydedilecek MATLAB struct/cell/array
%   filepath - Hedef dosya yolu (string)

    % Klasörü oluştur (yoksa)
    folder = fileparts(filepath);
    if ~isempty(folder) && ~exist(folder, 'dir')
        mkdir(folder);
    end
    
    % JSON'a dönüştür
    json_str = jsonencode(data, 'PrettyPrint', true);
    
    % Dosyaya yaz
    fid = fopen(filepath, 'w', 'n', 'UTF-8');
    if fid == -1
        error('JSON_SAVE:DosyaAcilamadi', ...
            'Dosya yazma için açılamadı: %s', filepath);
    end
    
    fwrite(fid, json_str, 'char');
    fclose(fid);
    
    fprintf('  [OK] Veri kaydedildi: %s\n', filepath);
end
