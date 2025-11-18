function plotPose3DCase_segments(bagFolder, topicName, caseLabel)
% Plots all 'guidance to start' segments for a bag.
%
% Each segment is plotted as a line (color: red, but changeable).
% Start and end of each segment are shown as green and magenta markers.
% Overlays /plot/study/start_point if available.

    close all;

    % --- Get segments (cell array, each is struct with .time, .data) ---
    segList = splitPoseOnGuidanceTransitions(bagFolder, topicName);
    if isempty(segList)
        warning('No guidance-to-start segments in %s.', bagFolder);
        return;
    end

    % --- Load start_point markers, if any ---
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
        warning('Could not load start points.');
    end

    % --- Plot all segments ---
    figure('Name', ['3D Guidance Segments – ' caseLabel],'NumberTitle','off','Color','w');
    hold on;

    color = [1 0 0 0.7]; % transparent red

    for s = 1:numel(segList)
        X = segList{s}.data(:,1);
        Y = segList{s}.data(:,2);
        Z = segList{s}.data(:,3);
    
        if s == 1
            plot3(X, Y, Z, '-', 'LineWidth', 1.6, 'Color', color, 'DisplayName', 'Trajectory Segment');
            plot3(X(1), Y(1), Z(1), 'go', 'MarkerFaceColor','g', 'MarkerSize',8, 'DisplayName', 'Segment Start');
            plot3(X(end), Y(end), Z(end), 'mo', 'MarkerFaceColor','m', 'MarkerSize',8, 'DisplayName', 'Segment End');
        else
            plot3(X, Y, Z, '-', 'LineWidth', 1.6, 'Color', color, 'HandleVisibility', 'off');
            plot3(X(1), Y(1), Z(1), 'go', 'MarkerFaceColor','g', 'MarkerSize',8, 'HandleVisibility', 'off');
            plot3(X(end), Y(end), Z(end), 'mo', 'MarkerFaceColor','m', 'MarkerSize',8, 'HandleVisibility', 'off');
        end
    end

    % Overlay start points, if any
    if ~isempty(plotPoints)
        plot3(plotPoints(:,1), plotPoints(:,2), plotPoints(:,3), ...
            'bx', 'MarkerSize', 10, 'LineWidth', 1.5, 'DisplayName', 'Start Points');
    end

    hold off;
    xlabel('X [m]'); ylabel('Y [m]'); zlabel('Z [m]');
    title(['3D Guidance Segments – ' caseLabel]);
    grid on; axis equal;
    legend('Location','best');
    view(45,30);

    % Save as TikZ (uncomment to use)
    % safeLabel = regexprep(caseLabel, '\s+', '_');
    % tikzName  = ['Pose3D_', safeLabel, '.tikz'];
    % matlab2tikz(tikzName, ...
    %    'height','\figureheight', ...
    %    'width','\figurewidth', ...
    %    'showInfo',false);
    % fprintf('Saved 3D-pose figure as TikZ: %s\n', tikzName);
end
