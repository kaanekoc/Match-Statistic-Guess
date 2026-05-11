function display_prediction(predictions, home_name, away_name)
% DISPLAY_PREDICTION - Tahmin sonuclarini gorsel olarak gosterir
%
% Kullanim:
%   display_prediction(predictions, 'Fenerbahce', 'Galatasaray')

    fprintf('\n');
    fprintf('╔══════════════════════════════════════════════════════╗\n');
    fprintf('║             MAC TAHMIN RAPORU                       ║\n');
    fprintf('╠══════════════════════════════════════════════════════╣\n');
    fprintf('║  %s vs %s\n', home_name, away_name);
    fprintf('║  Tarih: %s\n', datestr(now, 'dd.mm.yyyy HH:MM'));
    fprintf('╠══════════════════════════════════════════════════════╣\n');
    fprintf('║                                                      ║\n');
    fprintf('║  SKOR TAHMINI:    %s\n', predictions.score_text);
    fprintf('║  (Detay: %.2f - %.2f)\n', ...
        predictions.home_goals_exact, predictions.away_goals_exact);
    fprintf('║                                                      ║\n');
    fprintf('╠══════════════════════════════════════════════════════╣\n');
    fprintf('║  MAC SONUCU:      %s\n', predictions.result_text);
    
    if isfield(predictions, 'home_win_prob')
        fprintf('║  1 (Ev):     %%%.1f\n', predictions.home_win_prob * 100);
    end
    if isfield(predictions, 'draw_prob')
        fprintf('║  X (Ber):    %%%.1f\n', predictions.draw_prob * 100);
    end
    if isfield(predictions, 'away_win_prob')
        fprintf('║  2 (Dep):    %%%.1f\n', predictions.away_win_prob * 100);
    end
    
    fprintf('╠══════════════════════════════════════════════════════╣\n');
    fprintf('║  2.5 ALT/UST:    %s (%%%.1f)\n', ...
        predictions.over25_text, predictions.over25_probability * 100);
    fprintf('╠══════════════════════════════════════════════════════╣\n');
    fprintf('║  KART TAHMINI:   %d kart\n', predictions.estimated_cards);
    fprintf('║    Sari: ~%d  Kirmizi: ~%d\n', ...
        predictions.estimated_yellow_cards, predictions.estimated_red_cards);
    fprintf('╠══════════════════════════════════════════════════════╣\n');
    fprintf('║  KORNER TAHMINI: %s\n', predictions.corners_text);
    fprintf('╠══════════════════════════════════════════════════════╣\n');
    fprintf('║  GUVEN SKORU:    %%%.0f\n', predictions.confidence);
    fprintf('╚══════════════════════════════════════════════════════╝\n\n');
end
