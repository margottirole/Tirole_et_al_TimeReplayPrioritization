function corrTable= stabilisationMap(varargin)

p= inputParser;
addParameter(p,'maxLaps',10);
parse(p,varargin{:});
maxLaps= p.Results.maxLaps;

parameters= list_of_parameters;
load('extracted_laps.mat');
load('extracted_place_fields_BAYESIAN.mat');
cell_selection= place_fields_BAYESIAN.good_place_cells;

% calculate place fields lap by lap
place_field_laps= calculate_place_fields_laps('direction','bidirectional', ...
                                        'grouping','each',...
                                        'size',parameters.x_bins_width_bayesian,...
                                        'save_option',1);

all_cells_corr= nan(3,maxLaps);
for thisT=1:length(place_field_laps)
    nonEmptyFields= find(arrayfun(@(x) ~isempty(place_field_laps(thisT).(['lap' num2str(x)])),1:length(fieldnames(place_field_laps))));
    for thisLap=2:max(nonEmptyFields)

        % pop vector version
        maps1= cell2mat(place_field_laps(thisT).(['lap' num2str(thisLap)]).track.raw(cell_selection)');
        maps2=  cell2mat(place_field_laps(thisT).(['lap' num2str(thisLap-1)]).track.raw(cell_selection)');
        all_cells_corr(thisT,thisLap-1)= median(arrayfun(@(x) corr(maps1(:,x),maps2(:,x),'type','pearson'),1:size(maps1,2)),'omitmissing');            

    end
end

thisF= pwd;
thisFsplit= strsplit(thisF,'\');
RAT= thisFsplit{end-1};
SESSION= thisFsplit{end};

kk=1;
corrTable = table;
for thisT=1:size(all_cells_corr,1)
    for thisLap=1:maxLaps
        corrTable.rat(kk)= string(RAT);
        corrTable.session(kk)= string(SESSION);
        corrTable.track(kk)= thisT;
        corrTable.lap(kk)= thisLap;
        corrTable.corrValue(kk)=  all_cells_corr(thisT,thisLap);
        kk=kk+1;
    end
end


end