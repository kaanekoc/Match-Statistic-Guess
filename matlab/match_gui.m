function match_gui()
    % MATCH_GUI - Mac Istatistik Tahmin Uygulamasi Grafik Arayuzu
    
    % Yollari ayarla
    setup_paths();
    
    % Ana figuru olustur
    fig = uifigure('Name', 'Maç İstatistik Tahmin Uygulaması', 'Position', [100, 100, 900, 650]);
    
    % Grid layout olustur
    gl = uigridlayout(fig, [1, 2]);
    gl.ColumnWidth = {300, '1x'};
    
    % Sol panel (Kontroller)
    leftPanel = uipanel(gl, 'Title', 'Kontroller ve Ayarlar', 'FontSize', 14, 'FontWeight', 'bold');
    
    % Sag panel (Sonuclar)
    rightPanel = uipanel(gl, 'Title', 'Sonuçlar ve Loglar', 'FontSize', 14, 'FontWeight', 'bold');
    
    % --- KONTROLLER ---
    y_pos = 580;
    dy = 40;
    
    % Lig Secimi
    uilabel(leftPanel, 'Text', 'Lig Seçimi:', 'Position', [20 y_pos 260 22], 'FontWeight', 'bold');
    y_pos = y_pos - 25;
    ddLig = uidropdown(leftPanel, ...
        'Items', {'TR1 - Türkiye Süper Lig', 'GB1 - İngiltere Premier League', 'ES1 - İspanya La Liga', 'IT1 - İtalya Serie A', 'L1 - Almanya Bundesliga', 'FR1 - Fransa Ligue 1'}, ...
        'ItemsData', {'TR1', 'GB1', 'ES1', 'IT1', 'L1', 'FR1'}, ...
        'Position', [20 y_pos 260 30]);
        
    % Mac Sayisi
    y_pos = y_pos - dy;
    uilabel(leftPanel, 'Text', 'Takım Başı Maç Sayısı Limit:', 'Position', [20 y_pos 260 22], 'FontWeight', 'bold');
    y_pos = y_pos - 25;
    spnMatchLimit = uispinner(leftPanel, 'Limits', [5 50], 'Value', 20, 'Position', [20 y_pos 260 30]);
    
    % Mod Secimi
    y_pos = y_pos - dy - 10;
    uilabel(leftPanel, 'Text', 'İşlem Seçimi:', 'Position', [20 y_pos 260 22], 'FontWeight', 'bold');
    y_pos = y_pos - 25;
    ddMode = uidropdown(leftPanel, ...
        'Items', {'Demo Modu (Hızlı Test)', 'Sadece Veri Topla', 'Veri Topla + Model Eğit', 'Kayıtlı Model ile Tahmin'}, ...
        'ItemsData', {'DEMO', 'COLLECT', 'TRAIN', 'PREDICT'}, ...
        'Position', [20 y_pos 260 30], 'ValueChangedFcn', @modeChanged);
    
    % Tahmin Icin Takim Secimi (Sadece Tahmin Modunda Gorunur)
    y_pos = y_pos - dy - 10;
    btnLoadTeams = uibutton(leftPanel, 'push', 'Text', 'Takımları Getir', 'Position', [20 y_pos+5 260 25], 'Visible', 'off', 'ButtonPushedFcn', @loadTeams);
    
    y_pos = y_pos - 35;
    lblHome = uilabel(leftPanel, 'Text', 'Ev Sahibi Takım:', 'Position', [20 y_pos+5 120 22], 'Visible', 'off');
    ddHome = uidropdown(leftPanel, 'Position', [20 y_pos-20 120 25], 'Visible', 'off', 'Items', {'--'}, 'ItemsData', {NaN});
    
    lblAway = uilabel(leftPanel, 'Text', 'Deplasman Takımı:', 'Position', [160 y_pos+5 120 22], 'Visible', 'off');
    ddAway = uidropdown(leftPanel, 'Position', [160 y_pos-20 120 25], 'Visible', 'off', 'Items', {'--'}, 'ItemsData', {NaN});
    
    % Calistir Butonu
    y_pos = y_pos - dy - 50;
    btnRun = uibutton(leftPanel, 'push', 'Text', 'BAŞLAT', ...
        'Position', [20 y_pos 260 50], ...
        'BackgroundColor', [0.2 0.6 0.3], 'FontColor', 'w', 'FontSize', 16, 'FontWeight', 'bold', ...
        'ButtonPushedFcn', @runAction);
        
    % İlerleme Çubuğu (Progres)
    y_pos = y_pos - 40;
    lblStatus = uilabel(leftPanel, 'Text', 'Durum: Bekliyor', 'Position', [20 y_pos 260 22]);
    
    % --- SONUCLAR ---
    % Grid layout icindeki paneller uigridlayout kullanamaz kolayca, uix kullanalim veya dogrudan position.
    % Resize event eklemeden basitce uigridlayout ile saga text area koyalim.
    glRight = uigridlayout(rightPanel, [1, 1]);
    txtResult = uitextarea(glRight, 'Editable', 'off', 'FontSize', 12, 'FontName', 'Consolas');
    
    % Fonksiyonlar
    function modeChanged(~, ~)
        val = ddMode.Value;
        if strcmp(val, 'PREDICT')
            btnLoadTeams.Visible = 'on';
            lblHome.Visible = 'on'; ddHome.Visible = 'on';
            lblAway.Visible = 'on'; ddAway.Visible = 'on';
        else
            btnLoadTeams.Visible = 'off';
            lblHome.Visible = 'off'; ddHome.Visible = 'off';
            lblAway.Visible = 'off'; ddAway.Visible = 'off';
        end
    end

    function loadTeams(~, ~)
        league = ddLig.Value;
        btnLoadTeams.Enable = 'off';
        lblStatus.Text = 'Durum: Takımlar yükleniyor...';
        logMsg(sprintf('%s ligi takımları getiriliyor...', league));
        
        try
            teams = get_league_teams(league);
            if isempty(teams)
                logMsg('HATA: Takımlar bulunamadı!');
                btnLoadTeams.Enable = 'on';
                lblStatus.Text = 'Durum: Bekliyor';
                return;
            end
            
            names = {teams.name};
            ids = num2cell([teams.id]);
            
            ddHome.Items = names;
            ddHome.ItemsData = ids;
            
            ddAway.Items = names;
            ddAway.ItemsData = ids;
            if numel(teams) > 1
                ddAway.Value = ids{2};
            end
            
            logMsg(sprintf('%d takım başarıyla yüklendi.', numel(teams)));
            lblStatus.Text = 'Durum: Bekliyor';
        catch ME
            logMsg(['HATA: ' ME.message]);
            lblStatus.Text = 'Durum: Bekliyor';
        end
        btnLoadTeams.Enable = 'on';
    end

    function logMsg(msg)
        % Mesaji text area'ya ekle
        current = txtResult.Value;
        if ischar(current)
            current = {current};
        end
        if isempty(current) || (numel(current) == 1 && isempty(current{1}))
            txtResult.Value = {msg};
        else
            txtResult.Value = [current; {msg}];
        end
        scroll(txtResult, 'bottom');
        drawnow;
    end

    function runAction(~, ~)
        mode = ddMode.Value;
        league = ddLig.Value;
        limit = spnMatchLimit.Value;
        
        btnRun.Enable = 'off';
        txtResult.Value = {''};
        
        try
            switch mode
                case 'DEMO'
                    run_demo();
                case 'COLLECT'
                    run_collect(league, limit);
                case 'TRAIN'
                    run_train(league, limit);
                case 'PREDICT'
                    home_id = ddHome.Value;
                    away_id = ddAway.Value;
                    if isnan(home_id) || isnan(away_id)
                        logMsg('Lütfen önce takımları yükleyin ve geçerli bir seçim yapın.');
                    else
                        run_predict(home_id, away_id);
                    end
            end
        catch ME
            logMsg('');
            logMsg('HATA OLUŞTU:');
            logMsg(ME.message);
            for k=1:length(ME.stack)
                logMsg(sprintf('  %s (Satır: %d)', ME.stack(k).name, ME.stack(k).line));
            end
        end
        
        btnRun.Enable = 'on';
        lblStatus.Text = 'Durum: Bekliyor';
    end

    function run_demo()
        lblStatus.Text = 'Durum: Demo Çalışıyor...';
        logMsg('=== DEMO MODU ===');
        logMsg('Sentetik veri oluşturuluyor...');
        
        rng(42);
        n = 200; n_feat = 15;
        X = randn(n, n_feat);
        X(:,1) = abs(X(:,1)) * 1.5 + 0.5;   X(:,2) = abs(X(:,2)) * 1.2 + 0.3;
        X(:,3) = X(:,1) + X(:,2);            X(:,5) = rand(n,1);
        X(:,8) = rand(n,1);                   X(:,12) = randi([0,1], n, 1);
        X(:,14) = rand(n,1) * 3;
        
        y_home = max(0, round(X(:,1) .* 0.8 + X(:,12) .* 0.3 + randn(n,1)*0.5));
        y_away = max(0, round(X(:,2) .* 0.7 + randn(n,1)*0.5));
        y_score = [y_home, y_away];
        y_over25 = double((y_home + y_away) > 2.5);
        y_result = sign(y_home - y_away);
        y_cards = max(0, round(2 + X(:,1)*0.5 + randn(n,1)*0.8));
        y_corners = max(5, round(X(:,3)*2.5 + 5 + randn(n,1)*1.5));
        
        feature_names = {'avg_goals_scored', 'avg_goals_conceded', 'avg_total_goals', 'std_total_goals', 'win_rate', 'draw_rate', 'loss_rate', 'over25_rate', 'avg_goal_diff', 'max_goals', 'min_goals', 'is_home', 'home_ratio', 'form_points', 'form_goals'};
        
        logMsg('Modeller eğitiliyor (Bu işlem birkaç saniye sürebilir)...');
        models = train_all_models(X, y_score, y_over25, y_result, y_cards, y_corners, feature_names');
        
        logMsg('Eğitim tamamlandı!');
        logMsg('');
        logMsg('=== ÖRNEK TAHMİN (Fenerbahçe vs Galatasaray) ===');
        
        pred = struct();
        pred.home_goals = y_home(1);
        pred.away_goals = y_away(1);
        pred.score_text = sprintf('%d - %d', pred.home_goals, pred.away_goals);
        pred.over25_text = 'UST (2.5+)';
        pred.result_text = 'EV SAHIBI KAZANIR (1)';
        pred.home_win_prob = 0.55;
        pred.draw_prob = 0.25;
        pred.away_win_prob = 0.20;
        pred.estimated_cards = 4;
        pred.corners_text = '10 (9.5 UST)';
        pred.confidence = 68;
        
        logMsg(sprintf('Skor Tahmini:      %s', pred.score_text));
        logMsg(sprintf('Maç Sonucu:        %s', pred.result_text));
        logMsg(sprintf('2.5 Alt/Üst:       %s', pred.over25_text));
        logMsg(sprintf('İhtimaller:        Ev: %%%.1f | Beraberlik: %%%.1f | Dep: %%%.1f', pred.home_win_prob*100, pred.draw_prob*100, pred.away_win_prob*100));
        logMsg(sprintf('Beklenen Kart:     %d', pred.estimated_cards));
        logMsg(sprintf('Beklenen Korner:   %s', pred.corners_text));
        logMsg(sprintf('Güven Skoru:       %d/100', pred.confidence));
        logMsg('==================================================');
        lblStatus.Text = 'Durum: Tamamlandı';
    end

    function run_collect(league, limit)
        lblStatus.Text = 'Durum: Veri Toplanıyor...';
        logMsg(sprintf('Lig: %s için maksimum %d maç toplanacak.', league, limit));
        logMsg('API istekleri yapılıyor, lütfen bekleyin...');
        
        league_data = collect_league_data(league, limit);
        logMsg(sprintf('Veri toplama tamamlandı. %d takım verisi işlendi.', numel(league_data.team_details)));
        lblStatus.Text = 'Durum: Tamamlandı';
    end

    function run_train(league, limit)
        lblStatus.Text = 'Durum: Veri Toplanıyor...';
        logMsg(sprintf('Lig: %s için veriler toplanıyor...', league));
        league_data = collect_league_data(league, limit);
        
        lblStatus.Text = 'Durum: Özellikler Çıkarılıyor...';
        logMsg('Eğitim özellikleri (Feature Engineering) hazırlanıyor...');
        [X, y_score, y_over25, y_result, y_cards, y_corners, feat_names] = prepare_training_data(league_data);
        
        lblStatus.Text = 'Durum: Modeller Eğitiliyor...';
        logMsg(sprintf('Toplam örnek: %d, Özellik: %d', size(X, 1), size(X, 2)));
        models = train_all_models(X, y_score, y_over25, y_result, y_cards, y_corners, feat_names);
        
        logMsg('Modeller başarıyla eğitildi ve kaydedildi!');
        lblStatus.Text = 'Durum: Tamamlandı';
    end

    function run_predict(home_id, away_id)
        if isnan(home_id) || isnan(away_id)
            logMsg('HATA: Ev sahibi ve deplasman takımları için geçerli birer Takım ID girmelisiniz.');
            return;
        end
        
        lblStatus.Text = 'Durum: Modeller Yükleniyor...';
        cfg = api_config();
        model_files = dir(fullfile(cfg.model_dir, '*.mat'));
        if isempty(model_files)
            logMsg('HATA: Kayıtlı model bulunamadı. Lütfen önce "Veri Topla + Model Eğit" modunu çalıştırın.');
            return;
        end
        
        % En son modeli yukle
        [~, idx] = sort([model_files.datenum], 'descend');
        latest_model = model_files(idx(1)).name;
        logMsg(sprintf('Model yükleniyor: %s', latest_model));
        
        loaded = load(fullfile(cfg.model_dir, latest_model));
        models = loaded.models;
        
        lblStatus.Text = 'Durum: Takım Verileri İndiriliyor...';
        logMsg(sprintf('Ev sahibi (ID: %d) verileri alınıyor...', home_id));
        home_data = collect_team_data(home_id, 15);
        
        logMsg(sprintf('Deplasman (ID: %d) verileri alınıyor...', away_id));
        away_data = collect_team_data(away_id, 15);
        
        lblStatus.Text = 'Durum: Tahmin Yapılıyor...';
        logMsg('Özellikler çıkarılıp modele gönderiliyor...');
        predictions = predict_match(models, home_data, away_data);
        
        home_name = num2str(home_id);
        away_name = num2str(away_id);
        if isfield(home_data, 'team_name'), home_name = home_data.team_name; end
        if isfield(away_data, 'team_name'), away_name = away_data.team_name; end
        
        logMsg('');
        logMsg(sprintf('=== TAHMİN SONUCU: %s vs %s ===', home_name, away_name));
        logMsg(sprintf('Skor Tahmini:      %s', predictions.score_text));
        logMsg(sprintf('Maç Sonucu:        %s', predictions.result_text));
        logMsg(sprintf('2.5 Alt/Üst:       %s', predictions.over25_text));
        logMsg(sprintf('İhtimaller:        Ev: %%%.1f | Beraberlik: %%%.1f | Dep: %%%.1f', predictions.home_win_prob*100, predictions.draw_prob*100, predictions.away_win_prob*100));
        logMsg(sprintf('Beklenen Kart:     %d', predictions.estimated_cards));
        logMsg(sprintf('Beklenen Korner:   %s', predictions.corners_text));
        logMsg(sprintf('Güven Skoru:       %d/100', predictions.confidence));
        logMsg('==================================================');
        lblStatus.Text = 'Durum: Tamamlandı';
    end

end
