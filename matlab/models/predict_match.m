function predictions = predict_match(models, home_data, away_data, n_recent)
% PREDICT_MATCH - Egitilmis modeller ile mac tahmini yapar
    if nargin < 4, n_recent = 5; end
    predictions = struct();
    features = build_match_features(home_data, away_data, n_recent);
    feature_names = models.feature_names;
    x = zeros(1, numel(feature_names));
    for i = 1:numel(feature_names)
        if isfield(features, feature_names{i})
            x(i) = features.(feature_names{i});
        end
    end
    x_norm = (x - models.normalization.mu) ./ models.normalization.sigma;
    
    % 1. SKOR TAHMINI
    home_goals_raw = predict_reg(models.score.home_model, x_norm);
    away_goals_raw = predict_reg(models.score.away_model, x_norm);
    predictions.home_goals_exact = max(0, home_goals_raw);
    predictions.away_goals_exact = max(0, away_goals_raw);
    predictions.home_goals = round(max(0, home_goals_raw));
    predictions.away_goals = round(max(0, away_goals_raw));
    predictions.total_goals = predictions.home_goals + predictions.away_goals;
    predictions.score_text = sprintf('%d - %d', predictions.home_goals, predictions.away_goals);
    
    % 2. 2.5 ALT/UST
    z = x_norm * models.over25.weights + models.over25.bias;
    predictions.over25_probability = 1 / (1 + exp(-z));
    predictions.over25_prediction = predictions.over25_probability >= 0.5;
    if predictions.over25_prediction
        predictions.over25_text = 'UST (2.5+)';
    else
        predictions.over25_text = 'ALT (2.5-)';
    end
    
    % 3. MAC SONUCU
    classes = models.result.classes;
    rp = zeros(1, numel(classes));
    for c = 1:numel(classes)
        zc = x_norm * models.result.classifiers{c}.weights + models.result.classifiers{c}.bias;
        rp(c) = 1 / (1 + exp(-zc));
    end
    rp = rp / sum(rp);
    [~, bi] = max(rp);
    predictions.result_code = classes(bi);
    predictions.result_probabilities = rp;
    switch predictions.result_code
        case 1,  predictions.result_text = 'EV SAHIBI KAZANIR (1)';
        case 0,  predictions.result_text = 'BERABERLIK (X)';
        case -1, predictions.result_text = 'DEPLASMAN KAZANIR (2)';
        otherwise, predictions.result_text = 'BELIRSIZ';
    end
    for c = 1:numel(classes)
        switch classes(c)
            case 1,  predictions.home_win_prob = rp(c);
            case 0,  predictions.draw_prob = rp(c);
            case -1, predictions.away_win_prob = rp(c);
        end
    end
    
    % 4. KART TAHMINI
    cards_raw = x_norm * models.cards.weights + models.cards.bias;
    predictions.estimated_cards = max(0, round(cards_raw));
    predictions.estimated_yellow_cards = max(0, round(cards_raw * 0.85));
    predictions.estimated_red_cards = max(0, round(cards_raw * 0.15));
    
    % 5. KORNER TAHMINI
    corners_raw = x_norm * models.corners.weights + models.corners.bias;
    predictions.estimated_corners = max(5, round(corners_raw));
    predictions.corners_over95 = predictions.estimated_corners > 9.5;
    if predictions.corners_over95
        predictions.corners_text = sprintf('%d (9.5 UST)', predictions.estimated_corners);
    else
        predictions.corners_text = sprintf('%d (9.5 ALT)', predictions.estimated_corners);
    end
    
    % 6. GUVEN SKORU
    conf = 50;
    conf = conf + (max(rp) - 0.33) * 50;
    if features.home_win_rate > 0, conf = conf + 10; end
    predictions.confidence = max(10, min(95, conf));
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
