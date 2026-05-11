function evaluate_models(models, X, y_score, y_over25, y_result, y_cards, y_corners)
% EVALUATE_MODELS - Egitilmis modellerin performansini detayli degerlendirir
%
% Kullanim:
%   evaluate_models(models, X, y_score, y_over25, y_result, y_cards, y_corners)

    fprintf('\n##################################################\n');
    fprintf('MODEL DEGERLENDIRME RAPORU\n');
    fprintf('Tarih: %s\n', datestr(now));
    fprintf('##################################################\n\n');
    
    % Normalize et
    X_norm = (X - models.normalization.mu) ./ models.normalization.sigma;
    n = size(X, 1);
    
    % 1. Skor Modeli
    fprintf('=== 1. SKOR TAHMIN MODELI ===\n');
    home_pred = predict_reg(models.score.home_model, X_norm);
    away_pred = predict_reg(models.score.away_model, X_norm);
    
    home_mae = mean(abs(home_pred - y_score(:,1)));
    away_mae = mean(abs(away_pred - y_score(:,2)));
    home_rmse = sqrt(mean((home_pred - y_score(:,1)).^2));
    away_rmse = sqrt(mean((away_pred - y_score(:,2)).^2));
    
    % Tam skor isabet orani
    exact_score = sum(round(max(0,home_pred)) == y_score(:,1) & ...
                      round(max(0,away_pred)) == y_score(:,2)) / n;
    
    fprintf('  Ev Gol  - MAE: %.3f, RMSE: %.3f\n', home_mae, home_rmse);
    fprintf('  Dep Gol - MAE: %.3f, RMSE: %.3f\n', away_mae, away_rmse);
    fprintf('  Tam Skor Isabet: %.1f%%\n\n', exact_score * 100);
    
    % 2. 2.5 Alt/Ust Modeli
    fprintf('=== 2. 2.5 ALT/UST MODELI ===\n');
    z = X_norm * models.over25.weights + models.over25.bias;
    over25_prob = 1 ./ (1 + exp(-z));
    over25_pred = double(over25_prob >= 0.5);
    
    acc = mean(over25_pred == y_over25);
    tp = sum(over25_pred == 1 & y_over25 == 1);
    fp = sum(over25_pred == 1 & y_over25 == 0);
    fn = sum(over25_pred == 0 & y_over25 == 1);
    precision = tp / max(1, tp + fp);
    recall = tp / max(1, tp + fn);
    f1 = 2 * precision * recall / max(0.001, precision + recall);
    
    fprintf('  Dogruluk:  %.1f%%\n', acc * 100);
    fprintf('  Precision: %.1f%%\n', precision * 100);
    fprintf('  Recall:    %.1f%%\n', recall * 100);
    fprintf('  F1-Skor:   %.3f\n\n', f1);
    
    % 3. Mac Sonucu Modeli
    fprintf('=== 3. MAC SONUCU MODELI ===\n');
    classes = models.result.classes;
    scores = zeros(n, numel(classes));
    for c = 1:numel(classes)
        zc = X_norm * models.result.classifiers{c}.weights + models.result.classifiers{c}.bias;
        scores(:, c) = 1 ./ (1 + exp(-zc));
    end
    [~, max_idx] = max(scores, [], 2);
    result_pred = classes(max_idx);
    
    result_acc = mean(result_pred == y_result);
    fprintf('  Dogruluk: %.1f%%\n', result_acc * 100);
    
    % Sinif bazli dogruluk
    for c = 1:numel(classes)
        mask = y_result == classes(c);
        if sum(mask) > 0
            c_acc = mean(result_pred(mask) == classes(c));
            labels = {'DEPLASMAN', 'BERABERLIK', 'EV SAHIBI'};
            fprintf('  %s: %.1f%% (%d ornek)\n', labels{c}, c_acc*100, sum(mask));
        end
    end
    
    % 4. Kart Modeli
    fprintf('\n=== 4. KART TAHMIN MODELI ===\n');
    cards_pred = X_norm * models.cards.weights + models.cards.bias;
    cards_mae = mean(abs(cards_pred - y_cards));
    cards_rmse = sqrt(mean((cards_pred - y_cards).^2));
    fprintf('  MAE:  %.3f\n', cards_mae);
    fprintf('  RMSE: %.3f\n', cards_rmse);
    
    % 5. Korner Modeli
    fprintf('\n=== 5. KORNER TAHMIN MODELI ===\n');
    corners_pred = X_norm * models.corners.weights + models.corners.bias;
    corners_mae = mean(abs(corners_pred - y_corners));
    corners_rmse = sqrt(mean((corners_pred - y_corners).^2));
    fprintf('  MAE:  %.3f\n', corners_mae);
    fprintf('  RMSE: %.3f\n', corners_rmse);
    
    fprintf('\n##################################################\n');
    fprintf('DEGERLENDIRME TAMAMLANDI\n');
    fprintf('##################################################\n');
end

function y = predict_reg(model, X)
    if strcmp(model.type, 'ensemble_regression')
        preds = zeros(size(X,1), numel(model.sub_models));
        for i = 1:numel(model.sub_models)
            s = model.sub_models{i};
            preds(:,i) = X * s.weights + s.bias;
        end
        y = max(0, mean(preds, 2));
    else
        y = X * model.weights + model.bias;
    end
end
