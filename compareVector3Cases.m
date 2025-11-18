function compareVector3Cases(bagFolders, topicName, vectorField, labels, mainTitle)
% compareVector3Cases  Overlay X, Y, Z from three different bag-folders.
%
%   compareVector3Cases(bagFolders, topicName, vectorField, labels, mainTitle)
%
%   Inputs:
%     - bagFolders : 1×3 cell array of folder paths, e.g.
%                      {'C:\bags\case1', 'C:\bags\case2', 'C:\bags\case3'}
%     - topicName   : the topic to read, e.g. '/force_feedback/virtFix'
%     - vectorField : name of the Vector3 field in that message, e.g. 'vector'
%     - labels      : 1×3 cell array of strings, e.g. {'Case 1','Case 2','Case 3'}
%     - mainTitle   : overall title for the figure, e.g. 'Force Feedback Comparison'
%
%   This produces a single figure with 3 subplots:
%     subplot(3,1,1): X vs time, with 3 distinct lines
%     subplot(3,1,2): Y vs time
%     subplot(3,1,3): Z vs time
%
%   Each case will have its own color (r,g,b) and line style ('-','--',':').
%   The figure is automatically saved as a PDF named '<mainTitle>.pdf'.
%

    % ----------------------------
    % 0) Close all existing figures
    % ----------------------------
    close all;

    % ----------------------------
    % 1) Validate inputs
    % ----------------------------
    if numel(bagFolders)~=3 || numel(labels)~=3
        error('bagFolders and labels must each be 1×3 cell arrays.');
    end

    % ----------------------------
    % 2) Preallocate storage
    % ----------------------------
    times = cell(3,1);
    data  = cell(3,1);

    % ----------------------------
    % 3) Load data for each of the three cases
    % ----------------------------
    for k = 1:3
        [times{k}, data{k}] = loadVector3Topic(bagFolders{k}, topicName, vectorField);
        if isempty(times{k})
            warning('Case %d returned no data. Check bagFolder = %s', k, bagFolders{k});
        end
    end

    % ----------------------------
    % 4) Create figure and plot
    % ----------------------------
    colors     = {'r','g','b'};       % Color for Case 1, 2, 3
    lineStyles = {'-','--','-.'};      % Line style for Case 1, 2, 3
    dims       = {'F_x','F_y','F_z'};

    figure('Color','w','Name',mainTitle,'NumberTitle','off', ...
    'Units','centimeters','Position',[2 2 22 18]); % Larger figure

    for dim = 1:3
        ax = subplot(3,1,dim);
        hold(ax,'on');
        for k = 1:3
            plot( ...
                ax, ...
                times{k}, ...
                data{k}(:,dim), ...
                'Color',      colors{k}, ...
                'LineStyle',  lineStyles{k}, ...
                'LineWidth',  1.8, ...
                'DisplayName', labels{k} ...
            );
        end
        hold(ax,'off');
    
        xlabel(ax, 'Time [s]');
        xlabel(ax, 'Time [s]', 'FontSize', 14); % Adjust 14 to desired size
        ylabel(ax, sprintf('%s', dims{dim}), 'FontSize', 14); % Adjust 14 to desired size
        % Larger font and more space for legend
        lgd = legend(ax,'Location','northeastoutside','FontSize',14);
        lgd.ItemTokenSize = [30,10];
        grid(ax,'on');
    end

    % Link x-axes so zoom/pan is synchronized
    linkaxes(findall(gcf,'Type','axes'), 'x');

    % ----------------------------
    % 5) Save the figure as PDF
    % ----------------------------
    % Sanitize mainTitle into a valid filename (replace spaces with underscores):
    safeTitle = regexprep(mainTitle, '\s+', '_');


    % Link x‐axes so zoom/pan is synchronized
    linkaxes(findall(gcf,'Type','axes'), 'x');

    % 5) Save figure as TikZ
    safeTitle = regexprep(mainTitle, '\s+', '_');
    tikzName  = [safeTitle, '.tikz'];

    % If you want default width/height placeholders:
    %matlab2tikz(tikzName, ...
    %            'height','\figureheight', ...
    %            'width','\figurewidth', ...
    %            'showInfo',false);

    fprintf('Saved figure as TikZ: %s\n', tikzName);
    
    pdfName   = [safeTitle, '.pdf'];
    exportgraphics(gcf, pdfName, 'ContentType','vector');
    fprintf('Saved figure as PDF: %s\n', pdfName);

    % Print the end time for each controller
    for k = 1:3
        if ~isempty(times{k})
            fprintf('Controller %s: end time = %.3f s\n', labels{k}, times{k}(end)/12);
        else
            fprintf('Controller %s: no data\n', labels{k});
        end
    end


        % ==============================
    % Separate Figure: Force Magnitude
    % ==============================
    figAbs = figure('Color','w','Name',[mainTitle ' — Abs'],'NumberTitle','off', ...
                    'Units','centimeters','Position',[2 2 24 8]); % Wide, single row

    axAbs = axes(figAbs);
    hold(axAbs, 'on');
    for k = 1:3
        mag = sqrt(sum(data{k}.^2, 2));  % Euclidean norm (force magnitude)
        plot(axAbs, times{k}, mag, ...
            'Color',      colors{k}, ...
            'LineStyle',  lineStyles{k}, ...
            'LineWidth',  1.8, ...
            'DisplayName', labels{k});
    end
    hold(axAbs, 'off');
    xlabel(axAbs, 'Time [s]','FontSize',14);
    ylabel(axAbs, '|F| [N]','FontSize',14);
    title(axAbs, [mainTitle ' — Absolute Force']);
    lgd = legend(axAbs, 'Location','northeastoutside','FontSize',14);
    lgd.ItemTokenSize = [30,10];
    grid(axAbs,'on');

    % Save as PDF (and optionally TikZ)
    absTitle  = [mainTitle ' Absolute Force'];
    safeAbs   = regexprep(absTitle, '\s+', '_');
    pdfAbs    = [safeAbs, '.pdf'];
    exportgraphics(figAbs, pdfAbs, 'ContentType','vector');
    fprintf('Saved force-absolute figure as PDF: %s\n', pdfAbs);

    
end
