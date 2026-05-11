function data = json_load(filepath)
% JSON_LOAD - JSON dosyasından MATLAB verisine yükler
%
% Kullanım:
%   data = json_load('data/takim_verileri.json')
%
% Girdiler:
%   filepath - Yüklenecek JSON dosya yolu (string)
%
% Çıktılar:
%   data - Ayrıştırılmış veri (struct/cell/array)

    if ~exist(filepath, 'file')
        error('JSON_LOAD:DosyaBulunamadi', ...
            'Dosya bulunamadı: %s', filepath);
    end
    
    fid = fopen(filepath, 'r', 'n', 'UTF-8');
    if fid == -1
        error('JSON_LOAD:DosyaAcilamadi', ...
            'Dosya okuma için açılamadı: %s', filepath);
    end
    
    json_str = fread(fid, '*char')';
    fclose(fid);
    
    data = jsondecode(json_str);
end
