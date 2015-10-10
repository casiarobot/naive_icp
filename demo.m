% This demo uses ICP to perform scan-match based dead-reckoning. It plots a
% map based on these dead-reckoning results.
%
% Tim Bailey & Fabio Tozeto Ramos 2004.
% revised by Samuel on March 23 2009
% Fix bug and built the new GUI by Samuel on October 10 2015
close all; clear; clc;
path(path, genpath('./lib'));
dbstop if error;
rob = [0 -3 -3; 0 -1 1] * 0.5;

%%
% load '../data/rose.mat'
load ./data/upstairs.mat % logged laser range scans from indoor robot
% upstairs.mat contains the "laser" which is 2610*361

%% Configuration
maxR  = 7.8; 
vedio = 0;
n     = 3;
len   = size(laser, 1) - 1;
%
interp = 0; % 0 - simple ICP, 1 - ICP with interpolation
nit    = 100;   % number of ICP iterations for each scan-match
gate1  = 2.5; % 1st data association gate for each point in scan
gate2  = 0.1;% 2nd data association gate for each point in scan

%% Initialize vedio maker
if vedio
    videoObj           = VideoWriter('map.avi');
    videoObj.FrameRate = 5;
    videoObj.Quality   = 50;
    open(videoObj);
end
%% Initialize figure
figPos    = get(0, 'ScreenSize'); % [left, bottom, width, height]
figPos(3) = figPos(3) - 100;
figure('name', 'Naive ICP Demo',...
       'position', figPos,...
       'color', 'w', 'Menu', 'none');
hold on; box on; grid off;
robPlot  = patch(0, 0, 'b', 'erasemode', 'normal');
pathPlot = plot (0, 0, 'r-', 'linewidth', 5, 'erasemode','normal');
lsrPlot  = plot (0, 0, 'g.', 'markersize', 7, 'erasemode','normal');
xlabel('X(m)');
ylabel('Y(m)');
axis equal;
% axis([-5  15  -5 15]);
% set(gca,'Visible','off');
%%
pos      = zeros(3, 1);
path     = zeros(3, len + 1);
invDelta = zeros(3, 1);
delta    = zeros(3, 1);
for i = 1 : len
    %% Run ICP
    invDelta     = icp(laser(i,:), laser(i+1,:), invDelta,...
                    gate2, nit, interp,0);
    delta        = inverse(invDelta);
    %%
    pos          = compound(pos, delta);
    path(:, i+1) = pos;
    robPos       = compound(pos, rob);
    points       = getLaserPoint(laser(i+1, :), maxR);
    pointsWorld  = compound(pos, points);
    set(robPlot,  'xdata', robPos(1, :), 'ydata', robPos(2, :));
    set(pathPlot, 'xdata', path(1, 1:i), 'ydata', path(2, 1:i));
    set(lsrPlot,  'xdata', pointsWorld(1, :), ...
                  'ydata', pointsWorld(2, :));
    plot(pointsWorld(1, 1: n : end), pointsWorld(2, 1: n : end),...
        '.', 'markersize', 3, 'color', [169,169,169] / 255);
    drawnow;
    if mod(i, 6) == 0 && vedio
        frame = getframe;
        writeVideo(videoObj, frame);
    end
    fprintf('step %d\n', i);
end
if vedio
    close(videoObj);
end
print('-dpng', 'map.png');
