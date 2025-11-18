function plotTrajectoryWithStartPoints(bagFolder, caseLabel)
% plotTrajectoryWithStartPoints
% Colors the trajectory alternatingly each time it reaches (within 0.3m) the next ordered start point.

    close all;

    %% Load trajectory data
    trajTopic = '/slave/state';
    bag = ros2bagreader(bagFolder);
    selTraj = select(bag, 'Topic', trajTopic);
    msgsTraj = readMessages(selTraj);
    nTraj = numel(msgsTraj);
    if nTraj == 0, error('No trajectory messages'); end

    traj = zeros(nTraj,3);
    for i = 1:nTraj
        pos = msgsTraj{i}.pose.position;
        traj(i,:) = [pos.x, pos.y, pos.z];
    end

    %% Load ordered start points
    spTopic = '/plot/study/start_point';
    topicList = bag.AvailableTopics.Properties.RowNames;
    if ~any(strcmp(topicList, spTopic)), error('No start points'); end

    selSP = select(bag, 'Topic', spTopic);
    msgsSP = readMessages(selSP);
    nSP = numel(msgsSP);
    startPoints = zeros(nSP,3);
    for i = 1:nSP
        pt = msgsSP{i}.point;
        startPoints(i,:) = [pt.x, pt.y, pt.z];
    end

    %% Find trajectory indices where each ordered start point is reached
    threshold = 0.3; % distance threshold
    segmentChangeIdx = [1]; % always start from index 1
    currentSP = 1;

    for i = 1:nTraj
        if currentSP > nSP
            break; % all start points have been reached
        end
        dist = norm(traj(i,:) - startPoints(currentSP,:));
        if dist < threshold
            segmentChangeIdx = [segmentChangeIdx, i]; %#ok<AGROW>
            currentSP = currentSP + 1; % move to next start point
        end
    end

    % Add last trajectory index if not already included
    if segmentChangeIdx(end) ~= nTraj
        segmentChangeIdx = [segmentChangeIdx, nTraj];
    end

    %% Plotting with alternating colors
    figure('Color','w');
    hold on;

    colors = {'r','b'}; % colors alternate
    nSegments = length(segmentChangeIdx) - 1;

    for k = 1:nSegments
        idxStart = segmentChangeIdx(k);
        idxEnd = segmentChangeIdx(k+1);

        plot3(traj(idxStart:idxEnd,1), traj(idxStart:idxEnd,2), traj(idxStart:idxEnd,3), ...
            'Color', colors{mod(k-1,2)+1}, 'LineWidth', 1.5);
    end

    % Plot start points (ordered, black ×)
    scatter3(startPoints(:,1), startPoints(:,2), startPoints(:,3), ...
        80, 'kx', 'LineWidth', 1.8, 'DisplayName','Start Points');

    % Mark trajectory start (green circle) and end (magenta circle)
    scatter3(traj(1,1), traj(1,2), traj(1,3), ...
        100, 'go', 'filled', 'DisplayName','Trajectory Start');
    scatter3(traj(end,1), traj(end,2), traj(end,3), ...
        100, 'mo', 'filled', 'DisplayName','Trajectory End');

    xlabel('X [m]'); ylabel('Y [m]'); zlabel('Z [m]');
    title(['Trajectory and Ordered Start Points – ', caseLabel]);
    grid on; axis equal;
    legend('Location','best');
    view(45,30);
    hold off;

    %% Save as TikZ
    safeLabel = regexprep(caseLabel, '\s+', '_');
    tikzName = ['Trajectory_', safeLabel, '.tikz'];
    matlab2tikz(tikzName, 'height','\figureheight', 'width','\figurewidth', 'showInfo',false);
    %fprintf('Saved as TikZ: %s\n', tikzName);
end
