clear all; clc;
close all;

% ------------ USER SETTINGS ------------
airfoilFile = 'mh115.dat';    % must be in working folder
AoA   = 5;
Re    = 0.276e6;
Mach  = 0.04;

xh    = 0.720;   % hinge x/c
use_rel_yt = true;
rel_yt = 0.50;  % y/t if using relative mode; ignored if use_rel_yt=false
y_abs = 0.25;    % absolute y (chord units) if use_rel_yt=false

flap_angles = -5:1:5;

% ------------ WHICH XFOIL ------------
% Prefer console build; fallback to GUI if that's all you have
if exist('xfoilP.exe','file')
    xfoil_cmd = 'xfoilP.exe';
elseif exist('xfoil.exe','file')
    xfoil_cmd = 'xfoil.exe';
else
    error('Could not find xfoilP.exe or xfoil.exe in the current folder.');
end

CH = nan(numel(flap_angles),1);

resultsFile = 'hinge_moment_results.txt'; 

% Delete old results file if it exists
if exist(resultsFile, 'file')
    delete(resultsFile);
end

fprintf('Running XFOIL automation for MH115...\n');


for k = 1:numel(flap_angles)
    delta = flap_angles(k);

    % --- write the input file EXACTLY as XFOIL expects ---
    fid = fopen('xfoil_input.txt','w');
    fprintf(fid,'LOAD %s\n', airfoilFile);
    fprintf(fid,'GDES\n');
    fprintf(fid,'FLAP\n');
    fprintf(fid,'%g\n', xh);
    if use_rel_yt
        fprintf(fid,'999\n');           % select relative y/t mode
        fprintf(fid,'%g\n', rel_yt);    % y/t value
    else
        fprintf(fid,'%g\n', y_abs);     % absolute y value
    end
    fprintf(fid,'%g\n', delta);         % flap deflection (+ down)
    fprintf(fid,'EXEC\n\n');

    fprintf(fid,'OPER\n');
    fprintf(fid,'r %g\n', Re);
    fprintf(fid,'m %g\n', Mach);
    fprintf(fid,'VISC\n');
    fprintf(fid,'ITER 250\n');
    fprintf(fid,'ALFA %g\n', AoA);
    fprintf(fid,'FMOM\n\n');            % blank line ensures execution
    %fprintf(fid,'QUIT\n');
    fclose(fid);

    % --- run XFOIL and CAPTURE output robustly ---
    % > redirect stdout, 2>&1 also captures stderr (some builds print there)
    cmd = sprintf('%s < xfoil_input.txt > xfoil_out.txt 2>&1', xfoil_cmd);
    [status,~] = system(cmd);

    if status ~= 0
        fprintf('XFOIL returned nonzero status for delta=%g\n', delta);
    end

    % --- parse hinge moment from output file ---
    txt = fileread('xfoil_out.txt');

    % 1) normal: "Hinge moment/span = 0.007297 x 1/2 rho V^2 c^2"
    m = regexp(txt,'Hinge\s*moment/span\s*=\s*([\-+0-9.eE]+)','tokens','once');

    % 2) some builds print without '/span' or with extra spaces
    if isempty(m)
        m = regexp(txt,'Hinge\s*moment.*=\s*([\-+0-9.eE]+)','tokens','once');
    end

    if ~isempty(m)
        CH(k) = str2double(m{1});
        fprintf('delta = %+g deg | CH = %.6g\n', delta, CH(k));
    else
        % helpful dump if parsing failed
        fprintf('delta = %+g deg | CH not found. Showing last FMOM block:\n', delta);
        blk = regexp(txt,'FMOM[\s\S]*?(?=QUIT|$)','match','once');
        if ~isempty(blk), fprintf('%s\n', blk); end
    end
    
     % Save to results file
    fid2 = fopen(resultsFile, 'a');
    fprintf(fid2, 'Deflection = %g deg, CH = %.6f\n', delta, CH(k));
    fclose(fid2);

    fprintf('Completed delta = %g deg | CH = %.6f\n', delta, CH(k));
end

figure; plot(flap_angles, CH,'o-','LineWidth',1.8);
xlabel('Flap deflection (deg)'); ylabel('C_H (per ½\rhoV^2c^2)');
title(sprintf('Hinge moment vs flap deflection @ \\alpha = %.1f°', AoA));
grid on;
