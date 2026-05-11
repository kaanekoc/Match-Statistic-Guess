function setup_paths()
% SETUP_PATHS - MATLAB yollarini ayarlar
%
% Projenin tum alt klasorlerini MATLAB path'ine ekler.
% main.m calistirilmadan once bu fonksiyonun cagirilmasi gerekir.
%
% Kullanim:
%   setup_paths()

    % Proje kok dizinini bul
    this_file = mfilename('fullpath');
    project_root = fileparts(this_file);
    
    % Alt klasorleri ekle
    addpath(fullfile(project_root, 'config'));
    addpath(fullfile(project_root, 'utils'));
    addpath(fullfile(project_root, 'api'));
    addpath(fullfile(project_root, 'data'));
    addpath(fullfile(project_root, 'features'));
    addpath(fullfile(project_root, 'models'));
    
    % Veri ve model klasorlerini olustur
    cfg = api_config();
    
    fprintf('MATLAB yollari ayarlandi.\n');
    fprintf('Proje dizini: %s\n', project_root);
end
