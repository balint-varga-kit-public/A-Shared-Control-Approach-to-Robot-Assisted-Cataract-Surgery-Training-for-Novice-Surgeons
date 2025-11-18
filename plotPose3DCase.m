function plotPose3DCase(bagFolder, topicName, caseLabel, gapThreshold)
% gapThreshold [meters] = maximum allowed distance to connect points

    if nargin < 4
        gapThreshold = 0.25; % default: 25 cm
    end
    close all;

    [time, data] = loadPoseTopic(bagFolder, topicName);
    if isempty(time)
        warning('No pose data found in %s on topic %s.', bagFolder, topicName);
        return;
    end

    X = data(:,1);
    Y = data(:,2);
    Z = data(:,3);

    % *** Hier die Zählung ergänzen ***
    targetThreshold = 0.030; % [Meter]
    endPt = [X(end), Y(end), Z(end)];
    distsToEnd = sqrt((X - endPt(1)).^2 + (Y - endPt(2)).^2 + (Z - endPt(3)).^2);
    
    isClose = distsToEnd < targetThreshold;
    nClose = sum(isClose);
    if nClose > 0
        avgDist = mean(distsToEnd(isClose));
        fprintf(['Anzahl der Punkte näher als %.1f mm am Zielpunkt: %d von %d; ' ...
                 'mittlerer Abstand dieser Punkte: %.2f mm\n'], ...
                 targetThreshold*1000, nClose, numel(X), avgDist*1000);
        disp(['Time spent in critical proximity region: ', num2str(nClose/numel(X)*time(end))])
    else
        fprintf('Keine Punkte näher als %.1f mm am Zielpunkt.\n', targetThreshold*1000);
    end
    % *** bis hier ***

    % Load start_point markers
    plotPoints = [];
    try
        bag = ros2bagreader(bagFolder);
        topicTable = bag.AvailableTopics;
        topicList  = topicTable.Properties.RowNames;
        if any(strcmp(topicList, '/plot/study/start_point'))
            sel = select(bag, 'Topic', '/plot/study/start_point');
            msgs = readMessages(sel);
            npts = numel(msgs);
            plotPoints = nan(npts, 3);
            for i = 1:npts
                pt = msgs{i}.point;
                plotPoints(i,1) = pt.x;
                plotPoints(i,2) = pt.y;
                plotPoints(i,3) = pt.z;
            end
        end
    catch
        warning('Could not load start points from /plot/study/start_point.');
    end

    % 3) Create the 3D plot
    figure('Name',['3D Pose Trajectory – ' caseLabel],'NumberTitle','off','Color','w');
    hold on;

    % -- Draw only short-enough segments --
    for i = 1:length(X)-1
        d = norm([X(i+1)-X(i), Y(i+1)-Y(i), Z(i+1)-Z(i)]);
        if d < gapThreshold
            plot3([X(i), X(i+1)], [Y(i), Y(i+1)], [Z(i), Z(i+1)], '-', 'LineWidth', 1.25, 'Color', [0 0.5 0.5]);
        end
    end

    % Start/end markers
    plot3(X(end), Y(end), Z(end), 'ro', 'MarkerFaceColor','r', 'DisplayName', 'End');

    % Overlay start_point markers if present
    if ~isempty(plotPoints)
        plot3(plotPoints(:,1), plotPoints(:,2), plotPoints(:,3), ...
            'bx', 'MarkerSize', 10, 'LineWidth', 1.5, 'DisplayName', 'Start points');
    end

    hold off;
    xlabel('X [m]');
    ylabel('Y [m]');
    zlabel('Z [m]');
    %title(['3D Pose Trajectory – ' caseLabel]);
    grid on; axis equal;
    view(45,30);

    % Save as TikZ (optional)
    safeLabel = regexprep(caseLabel, '\s+', '_');
    tikzName  = ['Pose3D_', safeLabel, '.tikz'];
    matlab2tikz(tikzName, ...
       'height','\figureheight', ...
       'width','\figurewidth', ...
       'showInfo',false);
    fprintf('Saved 3D-pose figure with start points as TikZ: %s\n', tikzName);

    % Save as PDF (added)
pdfName = ['Pose3D_', safeLabel, '.pdf'];
exportgraphics(gcf, pdfName, 'ContentType','vector');
fprintf('Saved 3D-pose figure as PDF: %s\n', pdfName);

disp(['Endtime: ',num2str(time(end)/12)])

end
