function [time, data] = loadPoseTopic(bagFolder, topicName)
% loadPoseTopic  Read X,Y,Z (Pose.position) from any topic in a ROS2 bag.
%
%   [time, data] = loadPoseTopic(bagFolder, topicName)
%
%   Inputs:
%     - bagFolder : folder containing your .bag_0.db3 (e.g., 'C:\...\Case1')
%     - topicName : exact topic string, e.g. '/slave/state'
%
%   Outputs:
%     - time : n×1 array of message timestamps [s], shifted so time(1)=0.
%     - data : n×3 array of [X, Y, Z] from msg.pose.position.
%
%   Workflow (R2024b):
%     1) bag = ros2bagreader(bagFolder);
%     2) topicList = bag.AvailableTopics.Properties.RowNames;
%     3) sel = select(bag, 'Topic', topicName);
%     4) [msgs, msgTimes] = readMessages(sel);
%     5) time = seconds(msgTimes); time = time - time(1);
%     6) data(i,:) = [msgs{i}.pose.position.x, .y, .z];


    % 1) Open the ROS2 bag (folder containing .db3)
    bag = ros2bagreader(bagFolder);

    % 2) Extract the list of topic names (row names of the table)
    topicTable = bag.AvailableTopics; 
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

    sel_state = select(bag, 'Topic', '/mode_from_motion_rec');
    msgs_state = readMessages(sel_state);

    

    all_data_state = cell(size(msgs)); 
    
    for i = 1:numel(msgs_state)
        all_data_state{i} = msgs_state{i}.data;  % Assuming 'data' is the field name
        
    end
    % TODO I  wnat to chech based on the change of all_data_state from the
    % state 'guidance to start' to 
    for i = 1:n
        header = msgs{i}.header.stamp;
        time(i) = double(header.sec) + double(header.nanosec)*1e-9;
        pos = msgs{i}.pose.position;
        data(i,1) = pos.x;
        data(i,2) = pos.y;
        data(i,3) = pos.z;
    end
    % 7) Normalize so first timestamp is zero
    time = time - time(1);
end