function makeFigures()
% makeFigures Thesis figures from the experiment CSVs, saved as PNG
%   makeFigures()
%
%   Reads experiments/results.csv and experiments/generative_results.csv and writes
%   to experiments/figures/:
%     fig_e1_architecture_dataset.png   test accuracy per architecture x dataset
%     fig_accuracy_vs_time.png          test accuracy vs training time, all runs
%     fig_e3_optimizer_lr.png           optimizer / learning-rate comparison
%     fig_e4_normalization.png          None / MinMax / Mean-Std
%     fig_e5_augmentation.png           augmentation off vs on
%     fig_e2_resolution.png             resolution vs accuracy and vs training time
%     fig_confusion_<dataset>.png       confusion matrix of the best model per dataset
%     fig_vae_loss.png                  VAE loss curves
%   Only runs with status "ok" are used. A figure whose runs are missing is skipped
%   with a note, so the script works after a partial experiment run.

    expDir = fileparts(mfilename('fullpath'));
    repoRoot = fileparts(expDir);
    figDir = fullfile(expDir, 'figures');
    if ~isfolder(figDir), mkdir(figDir); end

    resultsFile = fullfile(expDir, 'results.csv');
    if isfile(resultsFile)
        T = readResults(resultsFile);
        T = T(T.status == "ok", :);
    else
        T = table();
        fprintf('No %s, skipping the classification figures.\n', resultsFile);
    end

    if ~isempty(T)
        figArchitectureDataset(T, figDir);
        figAccuracyVsTime(T, figDir);
        figOptimizer(T, figDir);
        figNormalization(T, figDir);
        figAugmentation(T, figDir);
        figResolution(T, figDir);
        figConfusion(T, repoRoot, figDir);
    end

    genFile = fullfile(expDir, 'generative_results.csv');
    if isfile(genFile)
        G = readtable(genFile, 'TextType', 'string');
        G = G(G.status == "ok", :);
        figVaeLoss(G, repoRoot, figDir);
    else
        fprintf('No %s, skipping the VAE figure.\n', genFile);
    end
    fprintf('Figures written to %s\n', figDir);
end

%% ---- data ------------------------------------------------------------------

function T = readResults(file)
    T = readtable(file, 'TextType', 'string');
    if ~islogical(T.augmentation)
        T.augmentation = ismember(lower(string(T.augmentation)), ["true", "1"]);
    end
    % Width of the network input from "28x28x1"; 28x28 for the plan's native sizes
    T.width = cellfun(@(s) sscanf(char(s), '%d', 1), cellstr(T.inputSize));
    T.optLr = T.optimizer + " " + compose('%g', T.learnRate);
end

function ok = haveRuns(T, minRows, name)
    ok = height(T) >= minRows;
    if ~ok
        fprintf('Skipping %s: not enough finished runs.\n', name);
    end
end

function fig = newFigure(w, h)
    fig = figure('Visible', 'off', 'Color', 'w', 'Position', [100 100 w h]);
end

function saveFigure(fig, file)
    exportgraphics(fig, file, 'Resolution', 150);
    close(fig);
    fprintf('  wrote %s\n', file);
end

function labelBars(ax, bars, fmt)
    for b = bars
        text(ax, b.XEndPoints, b.YEndPoints, compose(fmt, b.YData'), ...
            'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', 'FontSize', 9);
    end
end

function setAccuracyAxis(ax, values)
    lo = max(0, floor(min(values(:), [], 'omitnan') / 5) * 5 - 5);
    ylim(ax, [lo 100]);
    ylabel(ax, 'Tačnost na test skupu (%)');
    grid(ax, 'on');
    box(ax, 'off');
end

%% ---- figures ---------------------------------------------------------------

function figArchitectureDataset(T, figDir)
    S = T(T.experiment == "E1", :);
    if ~haveRuns(S, 1, 'fig_e1_architecture_dataset'), return; end
    datasets = unique(S.dataset, 'stable');
    archs = unique(S.architecture, 'stable');
    acc = nan(numel(datasets), numel(archs));
    for i = 1:numel(datasets)
        for j = 1:numel(archs)
            r = S(S.dataset == datasets(i) & S.architecture == archs(j), :);
            if ~isempty(r), acc(i, j) = r.testAccuracy(1) * 100; end
        end
    end
    fig = newFigure(640, 420);
    ax = axes(fig);
    bars = bar(ax, categorical(datasets, datasets), acc);
    labelBars(ax, bars, '%.2f');
    legend(ax, archs, 'Location', 'southeast');
    setAccuracyAxis(ax, acc);
    title(ax, 'Tačnost po arhitekturi i datasetu');
    saveFigure(fig, fullfile(figDir, 'fig_e1_architecture_dataset.png'));
end

function figAccuracyVsTime(T, figDir)
    if ~haveRuns(T, 1, 'fig_accuracy_vs_time'), return; end
    fig = newFigure(700, 480);
    ax = axes(fig);
    archs = unique(T.architecture, 'stable');
    hold(ax, 'on');
    markers = {'o', 's', '^', 'd'};
    for a = 1:numel(archs)
        m = T.architecture == archs(a);
        scatter(ax, T.trainTimeSec(m), T.testAccuracy(m) * 100, 55, 'filled', ...
            'Marker', markers{mod(a - 1, numel(markers)) + 1});
    end
    text(ax, T.trainTimeSec, T.testAccuracy * 100, "  " + T.runId, 'FontSize', 8);
    hold(ax, 'off');
    set(ax, 'XScale', 'log');
    xlabel(ax, 'Vreme treniranja (s, log skala)');
    setAccuracyAxis(ax, T.testAccuracy * 100);
    legend(ax, archs, 'Location', 'southeast');
    title(ax, 'Tačnost naspram vremena treniranja');
    saveFigure(fig, fullfile(figDir, 'fig_accuracy_vs_time.png'));
end

function figOptimizer(T, figDir)
    % LeNet on Fashion-MNIST, baseline normalization, no augmentation, native size
    S = T(T.architecture == "LeNet" & T.dataset == "FashionMNIST" & T.normalization == "MinMax" ...
        & ~T.augmentation & T.width == 28, :);
    if ~haveRuns(S, 2, 'fig_e3_optimizer_lr'), return; end
    [~, order] = sortrows([double(categorical(S.optimizer)), -S.learnRate]);
    S = S(order, :);
    fig = newFigure(720, 420);
    ax = axes(fig);
    bars = bar(ax, categorical(S.optLr, S.optLr), S.testAccuracy * 100);
    labelBars(ax, bars, '%.2f');
    setAccuracyAxis(ax, S.testAccuracy * 100);
    xlabel(ax, 'Optimizator i learning rate');
    title(ax, 'Optimizatori i learning rate (LeNet, Fashion-MNIST)');
    saveFigure(fig, fullfile(figDir, 'fig_e3_optimizer_lr.png'));
end

function figNormalization(T, figDir)
    S = T(T.architecture == "LeNet" & T.dataset == "FashionMNIST" & T.optimizer == "adam" ...
        & T.learnRate == 1e-3 & ~T.augmentation & T.width == 28, :);
    if ~haveRuns(S, 2, 'fig_e4_normalization'), return; end
    names = ["None", "MinMax", "Mean-Std"];
    acc = nan(1, 3);
    for i = 1:3
        r = S(S.normalization == names(i), :);
        if ~isempty(r), acc(i) = r.testAccuracy(1) * 100; end
    end
    fig = newFigure(560, 420);
    ax = axes(fig);
    bars = bar(ax, categorical(names, names), acc);
    labelBars(ax, bars, '%.2f');
    setAccuracyAxis(ax, acc);
    xlabel(ax, 'Normalizacija');
    title(ax, 'Uticaj normalizacije (LeNet, Fashion-MNIST)');
    saveFigure(fig, fullfile(figDir, 'fig_e4_normalization.png'));
end

function figAugmentation(T, figDir)
    A = T(T.augmentation, :);
    if ~haveRuns(A, 1, 'fig_e5_augmentation'), return; end
    labels = strings(0, 1);
    acc = zeros(0, 2);
    for i = 1:height(A)
        base = T(~T.augmentation & T.architecture == A.architecture(i) & T.dataset == A.dataset(i) ...
            & T.optimizer == "adam" & T.learnRate == 1e-3 & T.normalization == "MinMax" ...
            & T.width == A.width(i), :);
        if isempty(base), continue; end
        labels(end+1, 1) = A.architecture(i) + " " + A.dataset(i); %#ok<AGROW>
        acc(end+1, :) = [base.testAccuracy(1), A.testAccuracy(i)] * 100; %#ok<AGROW>
    end
    if isempty(labels)
        fprintf('Skipping fig_e5_augmentation: no matching baseline runs.\n');
        return;
    end
    fig = newFigure(640, 420);
    ax = axes(fig);
    bars = bar(ax, categorical(labels, labels), acc);
    labelBars(ax, bars, '%.2f');
    legend(ax, {'Bez augmentacije', 'Sa augmentacijom'}, 'Location', 'southeast');
    setAccuracyAxis(ax, acc);
    title(ax, 'Uticaj augmentacije');
    saveFigure(fig, fullfile(figDir, 'fig_e5_augmentation.png'));
end

function figResolution(T, figDir)
    S = T(T.architecture == "LeNet" & T.dataset == "MNIST" & T.optimizer == "adam" ...
        & T.learnRate == 1e-3 & T.normalization == "MinMax" & ~T.augmentation, :);
    if ~haveRuns(S, 2, 'fig_e2_resolution'), return; end
    S = sortrows(S, 'width');
    fig = newFigure(900, 400);
    tl = tiledlayout(fig, 1, 2, 'TileSpacing', 'compact');
    ax1 = nexttile(tl);
    plot(ax1, S.width, S.testAccuracy * 100, '-o', 'LineWidth', 1.5, 'MarkerFaceColor', 'auto');
    xticks(ax1, S.width);
    xlabel(ax1, 'Rezolucija (piksela po strani)');
    setAccuracyAxis(ax1, S.testAccuracy * 100);
    title(ax1, 'Rezolucija i tačnost');
    ax2 = nexttile(tl);
    plot(ax2, S.width, S.trainTimeSec, '-o', 'LineWidth', 1.5, 'MarkerFaceColor', 'auto');
    xticks(ax2, S.width);
    xlabel(ax2, 'Rezolucija (piksela po strani)');
    ylabel(ax2, 'Vreme treniranja (s)');
    grid(ax2, 'on'); box(ax2, 'off');
    title(ax2, 'Rezolucija i vreme treniranja');
    saveFigure(fig, fullfile(figDir, 'fig_e2_resolution.png'));
end

function figConfusion(T, repoRoot, figDir)
    datasets = unique(T.dataset, 'stable');
    for d = 1:numel(datasets)
        S = T(T.dataset == datasets(d), :);
        [~, best] = max(S.testAccuracy);
        file = fullfile(repoRoot, S.modelFile(best));
        if ~isfile(file)
            fprintf('Skipping confusion matrix for %s: %s missing.\n', datasets(d), file);
            continue;
        end
        m = load(file, 'yTrue', 'yPred', 'classNames');
        classes = categories(m.yTrue);
        cm = confusionmat(m.yTrue, m.yPred, 'Order', classes);
        n = numel(classes);
        fig = newFigure(640, 560);
        ax = axes(fig);
        imagesc(ax, cm);
        colormap(ax, parula);
        colorbar(ax);
        axis(ax, 'image');
        xticks(ax, 1:n); yticks(ax, 1:n);
        xticklabels(ax, classes); yticklabels(ax, classes);
        xtickangle(ax, 45);
        xlabel(ax, 'Predviđena klasa');
        ylabel(ax, 'Stvarna klasa');
        if n <= 12
            hi = max(cm(:)) / 2;
            for i = 1:n
                for j = 1:n
                    if cm(i, j) > hi, c = 'k'; else, c = 'w'; end
                    text(ax, j, i, num2str(cm(i, j)), 'HorizontalAlignment', 'center', ...
                        'Color', c, 'FontSize', 9);
                end
            end
        end
        title(ax, sprintf('%s, %s (%s): %.2f%%', datasets(d), S.architecture(best), ...
            S.runId(best), S.testAccuracy(best) * 100));
        saveFigure(fig, fullfile(figDir, "fig_confusion_" + datasets(d) + ".png"));
    end
end

function figVaeLoss(G, repoRoot, figDir)
    if ~haveRuns(G, 1, 'fig_vae_loss'), return; end
    fig = newFigure(1000, 620);
    tl = tiledlayout(fig, 2, 2, 'TileSpacing', 'compact');
    for i = 1:height(G)
        file = fullfile(repoRoot, G.modelFile(i));
        if ~isfile(file), continue; end
        m = load(file, 'lossHistory');
        ax = nexttile(tl);
        h = m.lossHistory;
        plot(ax, h.total, '-', 'LineWidth', 1.5); hold(ax, 'on');
        plot(ax, h.recon, '--', 'LineWidth', 1.5);
        plot(ax, h.kl, ':', 'LineWidth', 1.8);
        hold(ax, 'off');
        xlabel(ax, 'Epoha'); ylabel(ax, 'Gubitak');
        grid(ax, 'on'); box(ax, 'off');
        title(ax, sprintf('%s, latentna dimenzija %d', G.dataset(i), G.latentDim(i)));
        if i == 1, legend(ax, {'Ukupni', 'Rekonstrukcija', 'KL'}); end
    end
    saveFigure(fig, fullfile(figDir, 'fig_vae_loss.png'));
end
