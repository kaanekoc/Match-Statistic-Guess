function models = train_all_models(X, y_score, y_over25, y_result, y_cards, y_corners, feature_names)
% TRAIN_ALL_MODELS - Tum bahis tahmin modellerini egitir
%
% Skor tahmini, 2.5 alt/ust, mac sonucu, kart ve korner tahmini icin
% ayri ayri makine ogrenimi modelleri egitir.
%
% Kullanim:
%   models = train_all_models(X, y_score, y_over25, y_result, y_cards, y_corners, feature_names)
%
% Girdiler:
%   X             - Ozellik matrisi (N x F)
%   y_score       - Skor hedefi [ev_gol, dep_gol] (N x 2)
%   y_over25      - 2.5 ust/alt hedefi (N x 1)
%   y_result      - Mac sonucu (N x 1)
%   y_cards       - Kart sayisi (N x 1)
%   y_corners     - Korner sayisi (N x 1)
%   feature_names - Ozellik isimleri
%
% Ciktilar:
%   models - Egitilmis modelleri iceren struct

    fprintf('\n##################################################\n');
    fprintf('MODEL EGITIMI BASLATILIYOR\n');
    fprintf('##################################################\n');
    fprintf('Toplam ornek: %d, Ozellik: %d\n\n', size(X, 1), size(X, 2));
    
    models = struct();
    models.feature_names = feature_names;
    models.training_date = datestr(now, 'yyyy-mm-dd HH:MM:SS');
    models.n_samples = size(X, 1);
    
    % Veriyi normalize et
    [X_norm, mu, sigma] = zscore(X);
    sigma(sigma == 0) = 1; % Sifir varyansli ozellikleri koru
    models.normalization.mu = mu;
    models.normalization.sigma = sigma;
    
    % Train/Test bolme (%80/%20)
    rng(42); % Tekrarlanabilirlik icin
    n = size(X_norm, 1);
    idx = randperm(n);
    n_train = round(0.8 * n);
    
    train_idx = idx(1:n_train);
    test_idx = idx(n_train+1:end);
    
    X_train = X_norm(train_idx, :);
    X_test = X_norm(test_idx, :);
    
    fprintf('Egitim seti: %d, Test seti: %d\n\n', n_train, n - n_train);
    
    % ============================================================
    % 1. SKOR TAHMIN MODELI (Coklu Cikisli Regresyon)
    % ============================================================
    fprintf('--- [1/4] SKOR TAHMIN MODELI ---\n');
    
    y_home = y_score(:, 1);
    y_away = y_score(:, 2);
    
    % Ev sahibi gol modeli
    try
        models.score.home_model = train_ensemble_regression(X_train, y_home(train_idx));
        home_pred = predict_ensemble_regression(models.score.home_model, X_test);
        home_mae = mean(abs(home_pred - y_home(test_idx)));
        fprintf('  Ev sahibi gol MAE: %.3f\n', home_mae);
        models.score.home_mae = home_mae;
    catch ME
        warning('Ev sahibi gol modeli egitilemedi: %s', ME.message);
        models.score.home_model = train_linear_regression(X_train, y_home(train_idx));
        home_pred = X_test * models.score.home_model.weights + models.score.home_model.bias;
        home_mae = mean(abs(home_pred - y_home(test_idx)));
        models.score.home_mae = home_mae;
    end
    
    % Deplasman gol modeli
    try
        models.score.away_model = train_ensemble_regression(X_train, y_away(train_idx));
        away_pred = predict_ensemble_regression(models.score.away_model, X_test);
        away_mae = mean(abs(away_pred - y_away(test_idx)));
        fprintf('  Deplasman gol MAE: %.3f\n', away_mae);
        models.score.away_mae = away_mae;
    catch ME
        warning('Deplasman gol modeli egitilemedi: %s', ME.message);
        models.score.away_model = train_linear_regression(X_train, y_away(train_idx));
        away_pred = X_test * models.score.away_model.weights + models.score.away_model.bias;
        away_mae = mean(abs(away_pred - y_away(test_idx)));
        models.score.away_mae = away_mae;
    end
    
    % ============================================================
    % 2. 2.5 ALT/UST MODELI (Ikili Siniflandirma)
    % ============================================================
    fprintf('\n--- [2/4] 2.5 ALT/UST MODELI ---\n');
    
    models.over25 = train_logistic_model(X_train, y_over25(train_idx));
    over25_pred = predict_logistic_model(models.over25, X_test);
    over25_acc = mean(over25_pred == y_over25(test_idx));
    models.over25.accuracy = over25_acc;
    fprintf('  2.5 Alt/Ust Dogruluk: %.1f%%\n', over25_acc * 100);
    
    % ============================================================
    % 3. MAC SONUCU MODELI (Coklu Siniflandirma)
    % ============================================================
    fprintf('\n--- [3/4] MAC SONUCU MODELI ---\n');
    
    models.result = train_multiclass_model(X_train, y_result(train_idx));
    result_pred = predict_multiclass_model(models.result, X_test);
    result_acc = mean(result_pred == y_result(test_idx));
    models.result.accuracy = result_acc;
    fprintf('  Mac Sonucu Dogruluk: %.1f%%\n', result_acc * 100);
    
    % ============================================================
    % 4. KART TAHMIN MODELI (Regresyon)
    % ============================================================
    fprintf('\n--- [4/4] KART TAHMIN MODELI ---\n');
    
    models.cards = train_linear_regression(X_train, y_cards(train_idx));
    cards_pred = X_test * models.cards.weights + models.cards.bias;
    cards_mae = mean(abs(cards_pred - y_cards(test_idx)));
    models.cards.mae = cards_mae;
    fprintf('  Kart Tahmini MAE: %.3f\n', cards_mae);
    
    % ============================================================
    % 5. KORNER TAHMIN MODELI (Regresyon)
    % ============================================================
    fprintf('\n--- [5/5] KORNER TAHMIN MODELI ---\n');
    
    models.corners = train_linear_regression(X_train, y_corners(train_idx));
    corners_pred = X_test * models.corners.weights + models.corners.bias;
    corners_mae = mean(abs(corners_pred - y_corners(test_idx)));
    models.corners.mae = corners_mae;
    fprintf('  Korner Tahmini MAE: %.3f\n', corners_mae);
    
    % ============================================================
    % GENEL DEGERLENDIRME
    % ============================================================
    fprintf('\n##################################################\n');
    fprintf('MODEL EGITIMI TAMAMLANDI\n');
    fprintf('##################################################\n');
    fprintf('Skor Modeli - Ev MAE: %.3f, Dep MAE: %.3f\n', ...
        models.score.home_mae, models.score.away_mae);
    fprintf('2.5 Alt/Ust - Dogruluk: %.1f%%\n', models.over25.accuracy * 100);
    fprintf('Mac Sonucu  - Dogruluk: %.1f%%\n', models.result.accuracy * 100);
    fprintf('Kart Modeli - MAE: %.3f\n', models.cards.mae);
    fprintf('Korner Modeli - MAE: %.3f\n', models.corners.mae);
    fprintf('##################################################\n\n');
    
    % Modeli kaydet
    cfg = api_config();
    model_path = fullfile(cfg.model_dir, ...
        sprintf('trained_models_%s.mat', datestr(now, 'yyyymmdd')));
    save(model_path, 'models', '-v7.3');
    fprintf('Modeller kaydedildi: %s\n', model_path);
end

% ============================================================
% YARDIMCI FONKSIYONLAR
% ============================================================

function model = train_linear_regression(X, y)
% Basit dogrusal regresyon (en kucuk kareler)
    X_aug = [ones(size(X, 1), 1), X]; % Bias terimi ekle
    weights = (X_aug' * X_aug + 0.01 * eye(size(X_aug, 2))) \ (X_aug' * y);
    model.bias = weights(1);
    model.weights = weights(2:end);
    model.type = 'linear_regression';
end

function model = train_ensemble_regression(X, y)
% Ensemble regresyon (birden fazla model ortalamasiyla)
    n_models = 5;
    n = size(X, 1);
    model.sub_models = cell(n_models, 1);
    model.type = 'ensemble_regression';
    
    for i = 1:n_models
        % Bootstrap ornekleme
        boot_idx = randi(n, n, 1);
        X_boot = X(boot_idx, :);
        y_boot = y(boot_idx);
        
        % Ridge regresyon (farkli lambda)
        lambda = 0.01 * i;
        X_aug = [ones(size(X_boot, 1), 1), X_boot];
        w = (X_aug' * X_aug + lambda * eye(size(X_aug, 2))) \ (X_aug' * y_boot);
        
        sub = struct();
        sub.bias = w(1);
        sub.weights = w(2:end);
        model.sub_models{i} = sub;
    end
end

function y_pred = predict_ensemble_regression(model, X)
% Ensemble regresyon tahmini
    n = size(X, 1);
    preds = zeros(n, numel(model.sub_models));
    
    for i = 1:numel(model.sub_models)
        sub = model.sub_models{i};
        preds(:, i) = X * sub.weights + sub.bias;
    end
    
    y_pred = mean(preds, 2);
    y_pred = max(0, y_pred); % Negatif gol olmaz
end

function model = train_logistic_model(X, y)
% Lojistik regresyon (gradient descent ile)
    [n, d] = size(X);
    model.type = 'logistic_regression';
    
    % Agirlik baslatma
    w = zeros(d, 1);
    b = 0;
    lr = 0.01;
    n_iter = 1000;
    
    for iter = 1:n_iter
        % Sigmoid
        z = X * w + b;
        h = 1 ./ (1 + exp(-z));
        
        % Gradient
        grad_w = (1/n) * (X' * (h - y)) + 0.01 * w; % L2 regularizasyon
        grad_b = (1/n) * sum(h - y);
        
        % Guncelleme
        w = w - lr * grad_w;
        b = b - lr * grad_b;
    end
    
    model.weights = w;
    model.bias = b;
    model.threshold = 0.5;
end

function y_pred = predict_logistic_model(model, X)
% Lojistik regresyon tahmini
    z = X * model.weights + model.bias;
    probs = 1 ./ (1 + exp(-z));
    y_pred = double(probs >= model.threshold);
end

function model = train_multiclass_model(X, y)
% One-vs-Rest coklu siniflandirma
    classes = unique(y);
    model.type = 'multiclass_ovr';
    model.classes = classes;
    model.classifiers = cell(numel(classes), 1);
    
    for c = 1:numel(classes)
        y_binary = double(y == classes(c));
        model.classifiers{c} = train_logistic_model(X, y_binary);
    end
end

function y_pred = predict_multiclass_model(model, X)
% Coklu siniflandirma tahmini
    n = size(X, 1);
    scores = zeros(n, numel(model.classes));
    
    for c = 1:numel(model.classes)
        z = X * model.classifiers{c}.weights + model.classifiers{c}.bias;
        scores(:, c) = 1 ./ (1 + exp(-z));
    end
    
    [~, max_idx] = max(scores, [], 2);
    y_pred = model.classes(max_idx);
end
