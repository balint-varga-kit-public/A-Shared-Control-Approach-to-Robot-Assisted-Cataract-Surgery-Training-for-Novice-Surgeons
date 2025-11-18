function [time, data] = loadVector3Topic(bagFolder, topicName, vectorField)
% loadVector3Topic  Read X,Y,Z from any Vector3‐based topic in a ROS2 bag.
%
%   [time, data] = loadVector3Topic(bagFolder, topicName, vectorField)
%
%   Inputs:
%     - bagFolder   : folder containing your .bag_0.db3 (e.g. 'C:\...\ws_with_custom_msgs')
%     - topicName   : the exact topic string, e.g. '/force_feedback/virtFix'
%     - vectorField : the field‐name inside the message struct that is a Vector3.
%                     For example:
%                        '/force_feedback/virtFix' → 'vector'
%                        '/slave/state'           → 'force'   (or 'torque')
%                        '/master/feedback'       → 'feedback_vector'
%
%   Outputs:
%     - time : n×1 array of message timestamps [s], shifted so time(1)=0.
%     - data : n×3 array of [X, Y, Z] from msg.(vectorField).(x,y,z)
%
%  Example:
%     [t, xyz] = loadVector3Topic('C:\bags\case1', '/force_feedback/virtFix', 'vector');
%

    % 1) Open the ROS2 bag (folder containing .db3)
    bag = ros2bagreader(bagFolder);

    % 2) Extract the list of topic names (row names of the table)
    topicTable = bag.AvailableTopics 
    topicList  = topicTable.Properties.RowNames;

    if ~any(strcmp(topicList, topicName))
        error('Topic "%s" not found in %s', topicName, bagFolder);
    end

    % 3) Select only that topic
    sel = select(bag, 'Topic', topicName);

     % 4) Read all messages from that selection
    msgs = readMessages(sel);
    n    = numel(msgs);
    if n == 0
        warning('No messages found on topic %s in %s.', topicName, bagFolder);
        time = [];
        data = [];
        return;
    end

    % 5) Preallocate
    time = zeros(n,1);
    data = zeros(n,3);

    % 6) Loop through each message to extract timestamp & Vector3
    for i = 1:n
        header = msgs{i}.header.stamp;
        time(i) = double(header.sec) + double(header.nanosec)*1e-9;

        % Access the Vector3 field dynamically
        vec = msgs{i}.(vectorField);  
        data(i,1) = vec.x;
        data(i,2) = vec.y;
        data(i,3) = vec.z;
    end

    % 7) Normalize so first timestamp is zero
    time = time - time(1);
end
