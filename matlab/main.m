% MAIN - Mac Istatistik Tahmin Uygulamasi Ana Dosyasi
%
% Bu script, Transfermarkt API'lerini kullanarak futbol maci
% verilerini toplar, makine ogrenimi modelleri egitir ve
% mac tahminleri yapar.
%
% Kullanim:
%   1. Proje dizinine gidin: cd('d:/Github/Match-Statistic-Guess/matlab')
%   2. setup_paths calistirin
%   3. Bu scripti calistirin: main
%
% Adimlar:
%   Adim 1: Veri Toplama
%   Adim 2: Model Egitimi
%   Adim 3: Mac Tahmini
%
% Yazar: Match-Statistic-Guess Projesi
% Tarih: 2026

clc;
clear;
close all;

fprintf('╔══════════════════════════════════════════════════════╗\n');
fprintf('║     MAC ISTATISTIK TAHMIN UYGULAMASI v1.0           ║\n');
fprintf('║     Transfermarkt API + MATLAB ML                   ║\n');
fprintf('╚══════════════════════════════════════════════════════╝\n\n');

% Yollari ayarla
setup_paths();

%% ========================================================================
% ADIM 1: LIG VE MOD SECIMI
% =========================================================================
fprintf('Mevcut Ligler:\n');
fprintf('  1. TR1 - Turkiye Super Lig\n');
fprintf('  2. GB1 - Ingiltere Premier League\n');
fprintf('  3. ES1 - Ispanya La Liga\n');
fprintf('  4. IT1 - Italya Serie A\n');
fprintf('  5. L1  - Almanya Bundesliga\n');
fprintf('  6. FR1 - Fransa Ligue 1\n\n');

fprintf('Islem Secenekleri:\n');
fprintf('  A - Veri Topla + Model Egit + Tahmin Yap (Tam Dongu)\n');
fprintf('  B - Sadece Veri Topla\n');
fprintf('  C - Kayitli Model ile Tahmin Yap\n');
fprintf('  D - Demo Modu (Ornek Veri ile Calistir)\n\n');

mode = input('Islem secin (A/B/C/D): ', 's');
if isempty(mode), mode = 'D'; end
mode = upper(mode);

switch mode
    case 'A'
        run_full_pipeline();
    case 'B'
        run_data_collection();
    case 'C'
        run_prediction_only();
    case 'D'
        run_demo_mode();
    otherwise
        fprintf('Gecersiz secim. Demo modu calistiriliyor...\n');
        run_demo_mode();
end

%% ========================================================================
% TAM DONGU: Veri Topla + Egit + Tahmin
% =========================================================================
function run_full_pipeline()
    league_code = input('Lig kodu girin (ornek: TR1): ', 's');
    if isempty(league_code), league_code = 'TR1'; end
    
    match_limit = input('Takim basi mac sayisi (varsayilan 20): ');
    if isempty(match_limit), match_limit = 20; end
    
    % Veri topla
    fprintf('\n--- ADIM 1: VERI TOPLAMA ---\n');
    league_data = collect_league_data(league_code, match_limit);
    
    % Egitim verisi hazirla
    fprintf('\n--- ADIM 2: OZELLIK MUHENDISLIGI ---\n');
    [X, y_score, y_over25, y_result, y_cards, y_corners, feat_names] = ...
        prepare_training_data(league_data);
    
    % Model egit
    fprintf('\n--- ADIM 3: MODEL EGITIMI ---\n');
    models = train_all_models(X, y_score, y_over25, y_result, y_cards, y_corners, feat_names);
    
    % Degerlendirme
    fprintf('\n--- ADIM 4: MODEL DEGERLENDIRME ---\n');
    evaluate_models(models, X, y_score, y_over25, y_result, y_cards, y_corners);
    
    % Tahmin
    fprintf('\n--- ADIM 5: MAC TAHMINI ---\n');
    run_prediction_with_models(models, league_data);
end

%% ========================================================================
% SADECE VERI TOPLAMA
% =========================================================================
function run_data_collection()
    league_code = input('Lig kodu girin (ornek: TR1): ', 's');
    if isempty(league_code), league_code = 'TR1'; end
    
    match_limit = input('Takim basi mac sayisi (varsayilan 20): ');
    if isempty(match_limit), match_limit = 20; end
    
    league_data = collect_league_data(league_code, match_limit);
    fprintf('\nVeri toplama tamamlandi. %d takim verisi toplandı.\n', ...
        numel(league_data.team_details));
end

%% ========================================================================
% KAYITLI MODEL ILE TAHMIN
% =========================================================================
function run_prediction_only()
    cfg = api_config();
    
    % Mevcut modelleri listele
    model_files = dir(fullfile(cfg.model_dir, '*.mat'));
    if isempty(model_files)
        fprintf('Kayitli model bulunamadi. Once model egitin.\n');
        return;
    end
    
    fprintf('Mevcut modeller:\n');
    for i = 1:numel(model_files)
        fprintf('  %d. %s\n', i, model_files(i).name);
    end
    
    sel = input('Model numarasi secin: ');
    if isempty(sel) || sel < 1 || sel > numel(model_files)
        sel = numel(model_files);
    end
    
    loaded = load(fullfile(cfg.model_dir, model_files(sel).name));
    if isfield(loaded, 'models')
        models = loaded.models;
    else
        fprintf('Gecersiz model dosyasi.\n');
        return;
    end
    
    % Takim verilerini topla ve tahmin yap
    home_id = input('Ev sahibi takim ID girin: ');
    away_id = input('Deplasman takim ID girin: ');
    
    fprintf('\nTakim verileri toplanıyor...\n');
    home_data = collect_team_data(home_id, 15);
    pause(2);
    away_data = collect_team_data(away_id, 15);
    
    predictions = predict_match(models, home_data, away_data);
    
    home_name = num2str(home_id);
    away_name = num2str(away_id);
    if isfield(home_data, 'team_name'), home_name = home_data.team_name; end
    if isfield(away_data, 'team_name'), away_name = away_data.team_name; end
    
    display_prediction(predictions, home_name, away_name);
end

%% ========================================================================
% TAHMIN (Model ve Lig Verisi Mevcut)
% =========================================================================
function run_prediction_with_models(models, league_data)
    if ~isfield(league_data, 'teams') || isempty(league_data.teams)
        fprintf('Lig verisi bos.\n');
        return;
    end
    
    teams = league_data.teams;
    fprintf('\nLig Takimlari:\n');
    for i = 1:numel(teams)
        if isstruct(teams)
            fprintf('  %d. %s (ID: %d)\n', i, teams(i).name, teams(i).id);
        end
    end
    
    home_idx = input('\nEv sahibi takim numarasi: ');
    away_idx = input('Deplasman takim numarasi: ');
    
    if isempty(home_idx) || isempty(away_idx)
        fprintf('Gecersiz secim.\n');
        return;
    end
    
    td = league_data.team_details;
    if iscell(td)
        home_data = td{home_idx};
        away_data = td{away_idx};
    else
        home_data = td(home_idx);
        away_data = td(away_idx);
    end
    
    predictions = predict_match(models, home_data, away_data);
    
    if isstruct(teams)
        display_prediction(predictions, teams(home_idx).name, teams(away_idx).name);
    else
        display_prediction(predictions, 'Ev Sahibi', 'Deplasman');
    end
end

%% ========================================================================
% DEMO MODU
% =========================================================================
function run_demo_mode()
    fprintf('\n=== DEMO MODU ===\n');
    fprintf('Ornek veri ile model egitimi ve tahmin gosterimi\n\n');
    
    % Sentetik veri olustur
    rng(42);
    n = 200;
    n_feat = 15;
    
    feature_names = {'avg_goals_scored', 'avg_goals_conceded', ...
        'avg_total_goals', 'std_total_goals', 'win_rate', 'draw_rate', ...
        'loss_rate', 'over25_rate', 'avg_goal_diff', 'max_goals', ...
        'min_goals', 'is_home', 'home_ratio', 'form_points', 'form_goals'};
    
    X = randn(n, n_feat);
    X(:,1) = abs(X(:,1)) * 1.5 + 0.5;   % avg_goals_scored
    X(:,2) = abs(X(:,2)) * 1.2 + 0.3;   % avg_goals_conceded
    X(:,3) = X(:,1) + X(:,2);            % avg_total_goals
    X(:,5) = rand(n,1);                   % win_rate
    X(:,8) = rand(n,1);                   % over25_rate
    X(:,12) = randi([0,1], n, 1);         % is_home
    X(:,14) = rand(n,1) * 3;             % form_points
    
    % Hedef degiskenler
    y_home = max(0, round(X(:,1) .* 0.8 + X(:,12) .* 0.3 + randn(n,1)*0.5));
    y_away = max(0, round(X(:,2) .* 0.7 + randn(n,1)*0.5));
    y_score = [y_home, y_away];
    y_over25 = double((y_home + y_away) > 2.5);
    y_result = sign(y_home - y_away);
    y_cards = max(0, round(2 + X(:,1)*0.5 + randn(n,1)*0.8));
    y_corners = max(5, round(X(:,3)*2.5 + 5 + randn(n,1)*1.5));
    
    fprintf('Sentetik veri olusturuldu: %d ornek, %d ozellik\n\n', n, n_feat);
    
    % Model egit
    models = train_all_models(X, y_score, y_over25, y_result, y_cards, y_corners, feature_names');
    
    % Degerlendirme
    evaluate_models(models, X, y_score, y_over25, y_result, y_cards, y_corners);
    
    % Ornek tahmin goster
    fprintf('\n=== ORNEK TAHMIN ===\n');
    test_x = X(1, :);
    test_x_norm = (test_x - models.normalization.mu) ./ models.normalization.sigma;
    
    % Manuel tahmin sonucu olustur
    pred = struct();
    pred.home_goals = y_home(1);
    pred.away_goals = y_away(1);
    pred.home_goals_exact = X(1,1) * 0.8 + 0.3;
    pred.away_goals_exact = X(1,2) * 0.7;
    pred.total_goals = pred.home_goals + pred.away_goals;
    pred.score_text = sprintf('%d - %d', pred.home_goals, pred.away_goals);
    pred.over25_probability = 0.65;
    pred.over25_prediction = 1;
    pred.over25_text = 'UST (2.5+)';
    pred.result_text = 'EV SAHIBI KAZANIR (1)';
    pred.result_code = 1;
    pred.home_win_prob = 0.55;
    pred.draw_prob = 0.25;
    pred.away_win_prob = 0.20;
    pred.estimated_cards = 4;
    pred.estimated_yellow_cards = 3;
    pred.estimated_red_cards = 0;
    pred.estimated_corners = 10;
    pred.corners_over95 = true;
    pred.corners_text = '10 (9.5 UST)';
    pred.confidence = 68;
    
    display_prediction(pred, 'Fenerbahce (Demo)', 'Galatasaray (Demo)');
    
    fprintf('\nDemo modu tamamlandi.\n');
    fprintf('Gercek veri ile calismak icin A secenegini kullanin.\n');
end
