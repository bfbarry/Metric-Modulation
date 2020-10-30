function coords = ERP_diff_plot(STUDY, ALLEEG, clus_range, group_range)
    % Design has be manually adjusted before function call
    % clus_range is range of cluster numbers e.g. 3:14
    % group_range is a boolean of whether to show range of groups (like error bars)
    
    
    % extract number of clusters from STUDY
    %clus_shape = size(STUDY.cluster); num_cl = clus_shape(2);         
    
    if nargin < 4
        group_range = 1;
    end
    
    bar = 1; % bar chart displaying individual vals for line segments
    
    x = []; % x coordinates (hand for now)
    y = []; % y coordinates (event type for now
    XH = []; YH = []; % x, y coordinates of horz line segments
    XV = []; YV = []; % x, y coordinates of vert line segments
    
    P = [] ; T = []; R = []; L = [];
    
    for clus = clus_range %clus_range(1):clus_range(end)
        %[STUDY, erpdata, erptimes] = std_erpplot(STUDY, ALLEEG, 'noplot', 'on', 'clusters', clus); % one erpdata for each condition
        load(strcat('~/Desktop/IversenLab/external/ERPs/diponly_',int2str(clus),'_erps.mat'));
        diffs = []; % contains the max OR ranges of: PL, PR, TL, TR (in that order)
        
        
        for d = 1:numel(erpdata) % specific to study design!
            erp_mean = mean(erpdata{d}, 2);  %have to avg across axis 2
            diffs = [diffs, max(erp_mean)]; % trying either max() or range()
        end
        
        RL_P = diffs(2) - diffs(1); RL_T = diffs(4) - diffs(3); % PR - PL; TR- TL
        PT_L = diffs(1) - diffs(3); PT_R = diffs(2) - diffs(4); % PL - TL ; PR - TR
        
        RL = mean([RL_P, RL_T]); % mean([(PR - PL), (TR - TL)])
        PT = mean([PT_L, PT_R]); % mean([(PL - TL), (PR - TR)]) 

        x = [x, RL];
        y = [y, PT];
        
        P = [P, RL_P]; T = [T, RL_T]; R = [R, PT_R]; L = [L, PT_L];
        if group_range
            %individual R-L, P-T line segments for each cluster
            
            XH = [XH, nan, RL_P, RL_T]; YH = [YH, nan, PT, PT];   
            XV = [XV, nan, RL, RL]; YV = [YV, nan, PT_L, PT_R];
            
            %XH = [XH, nan, PT - .025, PT + .05]; YH = [YH, nan, PT, PT];   % debugging
            %XV = [XV, nan, RL, RL]; YV = [YV, nan, PT_L, PT_R];
            
        end
    end
    
    coords = [x,y]; 
    colors = linspace(1,8,length(x));
    scatter(x, y, 50, colors, 'filled'); %plotting here
    xlabel('Right-Left'); ylabel('Press-Tap');
    title(sprintf('%s, %s', 'cluster 1', '2 way comparison '));
    hold on
    
    %Labels
    cl_label = [clus_range]'; cl_label = num2str(cl_label); cl_label = cellstr(cl_label);
    text(double(x),double(y),cl_label); %label points with cluster names
    
    %plot line segments for individual T,P,L,R points
    if group_range
        plot([XH, XV], [YH, YV], '-r');
    end
    
    xlim([-0.12, 0.12]); %resize x-axis
    ylim([-0.12, 0.12]); %resize y-axis
    plot([0 0], ylim, '-k'); %plot a vertical line through (0,0)
    plot(xlim, [0 0],  '-k'); %plot a horizontal line through (0,0)
    axis equal 
    %axis auto to compare
    
    if bar
        hold off
        bar([P; T; R; L]);
    end
    %'VerticalAlignment','bottom','HorizontalAlignment','right'

