%% Woo

fgt_init; %initializes the fluigent sdk

pressureInfoArray = fgt_get_pressureChannelsInfo;
for i = 1:numel(pressureInfoArray)
    fprintf('Pressure channel info at index: %d\n', i-1);
    disp(pressureInfoArray(i));
end

%% Basic settings

% Pressure settings(probably dont need to set pressures)
Pressure_0 = 0;
Pressure_1 = 0;
Pressure_2 = 0;
Pressure_3 = 0;

% Get flowrate meter sensor ranges
[minSensor, maxSensor] = fgt_get_sensorRange(0);
[minSensor, maxSensor] = fgt_get_sensorRange(1);
[minSensor, maxSensor] = fgt_get_sensorRange(2);
[minSensor, maxSensor] = fgt_get_sensorRange(3);

% Warm up of the machine

% Camera settings
vid = videoinput('gentl', 1, 'BGR8');%vid = videoinput('gentl', 1, 'BGR8');
vid.ReturnedColorSpace = "rgb";
vid.FramesPerTrigger = 1;
src = getselectedsource(vid);
src.ExposureTime = 18019.7080078125;
src.Gain = 25;
src.Gamma = 0.8;
src.BlackLevel = 25;
src.ContrastBrightLimit = 4095;
src.ContrastDarkLimit = 400;
%vid.ROIPosition = [800 1000 2000 1500]; with keyence lens
%diskLogger.FrameRate = 24;
%diskLogger.Quality = 10;
%vid.FramesPerTrigger = 1;

% Imaging taking setting
Fig_num = 2;
Pause_time = 5; %in seconds

% Washing time setting
Washing_time = 3; %in minutes

% Experiment repeat
Repeat_num = 3;

% Flowrate check
Flowrate_check_interval = 30; %seconds

% Fractions of each component setting
Analyte_start = 0.2;
Analyte_end = 0.2;
Analyte_numpoint = 1; % now only 1 conc for analyte each time

Capstone_start = 0.2;
Capstone_end = 0.2; %0.4
Capstone_numpoint = 1; %3

HCsurf_start = 0.00;
HCsurf_end = 0.36;
HCsurf_numpoint = 19;

% Analyte define
Analyte = 'Weiss';

% Surfactant switching
SDS = 0;
SDBS = 1;

surfactant = '';
Surfactant_name = [SDS SDBS];

for i = 0:1
    Surfactant_position = surfactant_name(i)    
    
% Maths to calculate flowrates combinations with corresponding fractions

%Set each valve to all of its available positions
nValves = fgt_get_valveChannelCount;% Get number of valves

%% Machine running

Total_frac = 1;

for valveIndex = 0:nValves-1 % to count how many valve(m-switch) in total, 0 means valve #1
    fprintf('valve %d is at position %d\n', valveIndex, fgt_get_valvePosition(valveIndex))% Get all available positions for this valve
    maxPosition = fgt_get_valveRange(valveIndex);% Set valve to each of the available positions, waiting for it to switch each time
    
    for position = Surfactant_position %0:0 % can be 0:maxPosition, Set valve to each of the available positions, waiting for it to switch each time, 0 means position 1 on m-switch, 9 means position 10
        fgt_set_valvePosition(valveIndex, position); % valveindex 0 means only 1 m-switch and numbered as valve 0
        
        for Analyte_frac = linspace(Analyte_start, Analyte_end, Analyte_numpoint) % depend on how many analyte concs want to test
            
            for Capstone_frac = linspace(Capstone_start, Capstone_end, Capstone_numpoint) % a for loop to get different Capstone fraction calibration curves
                
                for repeat = 1:Repeat_num % repeat to get exactly same parameter curves
                    
                    % pause(5*60);  to make droplets fully closed before starting a new calibration curve
                    
                    for HCsurf_frac = linspace(HCsurf_start, HCsurf_end, HCsurf_numpoint) %linspace(0.1,0.26,9) % a for loop for changing HCsurf fraction, and get a calibration curve
                        MilliQ_frac = Total_frac - Analyte_frac - Capstone_frac - HCsurf_frac;
                        
                        Flow_total = 7; % 13 for large barrier chamber chip
                        Flow_0 = Flow_total*MilliQ_frac; % Milli Q, maxSensor
                        Flow_1 = Flow_total*Capstone_frac; % 1wt% Capstone
                        Flow_2 = Flow_total*Analyte_frac; % Analyte
                        Flow_3 = Flow_total*HCsurf_frac; % 1wt% HC surfactant
                        
                        % Camera on
                        preview(vid);
                        
                        % set new surfactant siwtched to prerun longer
                        if HCsurf_frac = 0.00;
                            pause(60*5)
                        else
                            continue;
                            
                            % Nothing need to do about check valve
                            
                            % Record step response time
                            
                            % Video acquision
                            
                            %                         take_video = VideoWriter(num2str(HCsurf_frac,'%4.2f'),'SDBS-',num2str(Capstone_frac),'Capstone-',num2str(Analyte_frac),'Analyte-',num2str(repeat),'run-Calibration-',num2str(i),'.avi');
                            %                         open(take_video);
                            %                         for i = 1:3000
                            %                             writeVideo(take_video,1);
                            %                         end
                            %                         close(take_video);
                            
                            
                            %% Begin loop where we start the experiment
                            
                            % % Set pressures for four pumps
                            % fgt_set_pressure(0, Pressure_0); %first number 0,1,2,3 for four pumps 15470,15471,15472,15473 respectively, second number for set pressure value in mbar
                            % fgt_set_pressure(1, Pressure_1);
                            % fgt_set_pressure(2, Pressure_2);
                            % fgt_set_pressure(3, Pressure_3);
                            
                            % Set flowrates for four flowmeters, first number for flowmeter serial number, second for pump serial number, third for flowrate
                            fgt_set_sensorRegulation(0, 0, Flow_0); % Miili Q
                            fgt_set_sensorRegulation(1, 1, Flow_1); % 1 wt% Capstone
                            fgt_set_sensorRegulation(2, 2, Flow_2); % Analyte
                            fgt_set_sensorRegulation(3, 3, Flow_3); % 1 wt% HC surfactant
                            
                            % Set running time
                            pause(30) % 60s to reach steady state flowrates
                            run_time = 5; % Running time in minutes 3.5
                            pause(run_time*60)
                            
                            %set concentration for a certain amount of volume sent, need some
                            %calculations, c = n/V, n = m/Mw
                            
                            % Emergency situations to stop(e.g. backflow)
                            Flowrate_check_num = ((run_time*60)/Flowrate_check_interval)-1;
                            parfor j = 1:Flowrate_check_num
                                pause(30)
                                
                                % Record last flow rate of all sections
                                
                                % Read pressure value
                                pressureValue = fgt_get_pressure(0);
                                pressureUnit = fgt_get_pressureUnit(0);
                                fprintf('Current pressure: %f\n', pressureValue, pressureUnit)
                                pressureValue = fgt_get_pressure(1);
                                pressureUnit = fgt_get_pressureUnit(1);
                                fprintf('Current pressure: %f\n', pressureValue, pressureUnit)
                                pressureValue = fgt_get_pressure(2);
                                pressureUnit = fgt_get_pressureUnit(2);
                                fprintf('Current pressure: %f\n', pressureValue, pressureUnit)
                                pressureValue = fgt_get_pressure(3);
                                pressureUnit = fgt_get_pressureUnit(3);
                                fprintf('Current pressure: %f\n', pressureValue, pressureUnit)
                                
                                % Read sensor values
                                sensorValue_Flow_0 = fgt_get_sensorValue(0);
                                sensorUnit = fgt_get_sensorUnit(0);
                                fprintf('Current sensor value: %f\n', sensorValue_Flow_0, sensorUnit)
                                sensorValue_Flow_1 = fgt_get_sensorValue(1);
                                sensorUnit = fgt_get_sensorUnit(1);
                                fprintf('Current sensor value: %f\n', sensorValue_Flow_1, sensorUnit)
                                sensorValue_Flow_2 = fgt_get_sensorValue(2);
                                sensorUnit = fgt_get_sensorUnit(2);
                                fprintf('Current sensor value: %f\n', sensorValue_Flow_2, sensorUnit)
                                sensorValue_Flow_3 = fgt_get_sensorValue(3);
                                sensorUnit = fgt_get_sensorUnit(3);
                                fprintf('Current sensor value: %f\n', sensorValue_Flow_3, sensorUnit)
                                
                                if sensorValue_Flow_3 < -0.5 % or smaller than 0, but to except some random error so -0.5
                                    fgt_set_sensorRegulation(0, 0, 0.01); %first number for flowmeter serial number, second for pump serial number, third for flowrate
                                    fgt_set_sensorRegulation(1, 1, 0.01); %0.01 or 0.1 depends
                                    fgt_set_sensorRegulation(2, 2, 0.01);
                                    fgt_set_sensorRegulation(3, 3, 0.01);
                                    
                                    closepreview(vid);
                                    stop(vid);
                                    
                                    fgt_close;
                                    
                                else
                                    continue
                                end
                            end
                            
                            % Stop flows of four pumps, but not set to 0, just keep flowrates as low as
                            % possible and droplets stable in the sensing region for taking images
                            fgt_set_sensorRegulation(0, 0, 0.01); %first number for flowmeter serial number, second for pump serial number, third for flowrate
                            fgt_set_sensorRegulation(1, 1, 0.01); %0.01 or 0.1 depends
                            fgt_set_sensorRegulation(2, 2, 0.01);
                            fgt_set_sensorRegulation(3, 3, 0.01);
                            pause(45) % stop for 30s then take images
                            
                            %                         end
                            %                         close(take_video);
                            
                            %% Image acquisition
                            
                            start(vid);
                            
                            for i = 1:Fig_num
                                
                                pause(Pause_time); %wait for chosen seconds to continue the job
                                snapshot = getsnapshot(vid);
                                fname = 'Q:\CC-Droplab\sideview\2024\Katrina\Sensing(KS)\KS_83\KS_83.2';
                                filename = [num2str(HCsurf_frac,'%4.2f'),surfactant,'-',num2str(Capstone_frac),'Capstone-',num2str(Analyte_frac),Analyte,'-',num2str(repeat),'run-Calibration-',num2str(i),'.png']; %can be 'png','jpg','tif'
                                % '%4.2f' make 0.1 become 0.10, 0.2 become 0.20, so exactly two decimal places
                                reduced_snapshot = imresize(snapshot, 0.25, 'nearest'); % to reduced number of total pixels to 25%(only for this high resolution allied vision camera), therefore reduce image analysis time
                                imwrite(reduced_snapshot,fullfile(fname, filename));
                                
                                close all;
                                
                            end
                            
                            closepreview(vid);
                            stop(vid);
                            
                        end
                    end
                    %fgt_set_valvePosition(valveIndex, 9);% Return valve to default position, which 9 is position 10, connects to waste bottle
                end
            end
        end
    end
end

end
% Flow parameters saving

%% Second loop

%start flow, stop flow
%record last flow rate
%take image
%start flow, stop flow
%record last flow rate
%take image
%There is n=3 image
%end loop

%% Washing (one-way check valves pluged in)(for multiple HC surfactants)

% fgt_set_sensorRegulation(0, 0, Flow_total/2); % pump in MilliQ water
% fgt_set_sensorRegulation(1, 1, Flow_total/2); % pump in Capstone to keep droplets alive
% fgt_set_sensorRegulation(2, 2, 0.00);
% fgt_set_sensorRegulation(3, 3, 0.00);
%
% pause(Washing_time*60);
%
% % Droplets conditions checking after washing
% pause(60); %wait for chosen seconds to continue the job
% snapshot = getsnapshot(vid);
% fname = 'Q:\CC-Droplab\sideview\2023\Katrina\Sensing(KS)\KS_23\KS_23.1';
% filename = [num2str(HCsurf_frac),'SDS-',num2str(Capstone_frac),'Capstone_Cali_washcheck',num2str(i),'.tif']; %can be 'png','jpg','tif'
% imwrite(snapshot,fullfile(fname, filename));
%
% close all;

%% Stop flows of four pumps at the very end

fgt_set_sensorRegulation(0, 0, 0.01); %first number for flowmeter serial number, second for pump serial number, third for flowrate
fgt_set_sensorRegulation(1, 1, 0.01);
fgt_set_sensorRegulation(2, 2, 0.01);
fgt_set_sensorRegulation(3, 3, 0.01);

% fgt_set_pressure(0, 0);
% fgt_set_pressure(1, 0);
% fgt_set_pressure(2, 0);
% fgt_set_pressure(3, 0);

fgt_close;
