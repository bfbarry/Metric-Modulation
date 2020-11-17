function SI = plingSubjinfo(code, date)
% plingSubjinfo return subject info/demographics for member of pling study
%
% data are taken from admin db (?) and pling portal downloads
%
%   subjects = plingSubjinfo; %list of subjects
% 
%         SI = plingSubjinfo(SubjID, date) ; %return demographic info
%
%   SubjID = Pxxxx PLING code
%   date   = optional, returns timepoint-specific info
%
%   without specifying date, returns basic info
%     .SubjID
%     .Gender
%     .BD'
%     .Study
%
%   specifying data returns timepoint and snapping info
%     SI = plingSubjinfo('P0838','2014-04-26')
%                   SI.
%                      SubjID: 'P0838'
%                      Gender: 'F'
%                          BD: '2006-10-15'
%                       Study: 'PLING'
%                     VisitID: 'P0838_20140427_110237'
%                   studyDate: '20140427'
%                  portalDate: '2014-04-27'
%     plingTimepointStartDate: '2014-04-26'
%       plingTimepointEndDate: '2014-04-27'
%              plingTimePoint: '3'
%        plingTimepontMriDate: '2014-04-27 10:00:00'
%          plingTimepointNote: 'NULL'
%              testDateToSnap: '2014-04-26'
%                         Age: 7.5291
%                   portalAge: 7.5318
%                meanBehavAge: 7.5305
%                       Grade: 3
%     
%
%
% JRI 11/19/12
% JRI 8/1/13 updated to use new demographics database
% JRI 7/6/15 updated to use database admin info, old version is in _old

global G

%memoize slow-loading tables
persistent sheet portal

%define files to load
% ADMIN database (defived from Melanie's original Participant *Sheet*, parsed by
% parseAdminDB, but now maintained manually in the master database
% So, must visit chd-kvm-01.ucsd.edu/phpmyadmin, and get the most recent
% admin (and scheduling?) tables
%     export to CSV using the following name template: @TABLE@_%Y-%m-%d
%     and be sure to check box to include column titles in frist row
% finally, one field has a string with returns in it, which messes with the basic
%   parser we're using to read it, so be sure to check "Remove carriage 
%     return/line feed characters within columns" in the exporter, too.

sheetfile = 'admin_2015-07-07.csv';
sheetfile = fullfile(G.paths.root, 'projects','simphony','Data','CHD',sheetfile);

% PORTAL data
%   PLING portal http://mmil-dataportal.ucsd.edu:3000/
%   
%   1) export from PLING portal, (go to data exploration and then expert mode, download data and model --> package)
%   2) rename directory to package_date
%   3) Copy 'extractDemographics.R' to portal_date and edit it to make paths match
%   4) Open RStudio and run it
%   
% package = 'package_2015_07';
% portalfile = fullfile(G.paths.root, ...
%   ['projects/simphony/Data/Portal/PLING/' package '/PLING_portal_demographic.csv']);
% 

% better: operate only from the imaging spreadsheet under "Data Portal Documents"
%   1) Download imaginag spread sheet, rename with date (e.g. PLING_MRI_DTI_Complete_2015-07-06.csv')
%   
portalfile = fullfile(G.paths.root, ...
  'projects/simphony/Data/Portal/PLING/PLING_MRI_DTI_Complete_2015-07-06.csv');

%load 

if isempty(sheet),
  sheet = readtable(sheetfile);
end

if isempty(portal),
  portal = readtable(portalfile,[],{'SubjID','VisitID','StudyDate','ProcDate'});
end

subjects = {sheet.subjectID}; %how handle timepoints?

if nargin < 1,
  SI = unique(subjects);
  return 
end

%find matching row in admin and portal
iSubj_sheet = strmatch(lower(code), lower(subjects));
iSubj_portal = strmatch(lower(code), lower({portal.SubjID}));

% not found in sheet--error
if isempty(iSubj_sheet),
  warning('%s not found in subject sheet!',code)
  if isempty(iSubj_portal),
    warning(' not in portal either!')
  else
    warning(' does appear to be in portal--check this out!')
  end
  SI = [];
  return
end

%subject-wide info, take only first entry (of possible multiple timepoints)
%SI = copyfields(sheet(iSubj_sheet(1)),[],{'SubjID','Gender','BD'});
%SI = copyfields(sheet(iSubj_sheet(1)),[],{'subjectID','Gender','bDay'});
SI.SubjID = sheet(iSubj_sheet(1)).subjectID;
SI.Gender = sheet(iSubj_sheet(1)).Gender;
SI.BD = sheet(iSubj_sheet(1)).bDay;

%parse study identity (lump reach with PLING)
study = 'PLING';
if sheet(iSubj_sheet(1)).SIMPHONY,
  study = 'SIMPHONY';
elseif sheet(iSubj_sheet(1)).ACTION,
  study = 'ACTION';
end
SI.Study = study;

%if not looking for a specific timepoint, return basic info
if nargin == 1,
  return
end

%timepoint-specific information, find best match in portal and participant sheet
tpAge = ageAt(SI.BD, date);
tpGrade = round(tpAge-5); %HACK: quick and dirty grade calculation

%find portal match
% take age that's closest, reject if > 6 months difference
if ~isempty(iSubj_portal),
  for i = 1:length(iSubj_portal),
    try,
      portalAge(i) = str2num(portal(iSubj_portal(i)).Age);
    catch
      studyDate{i} = portal(iSubj_portal(i)).StudyDate; %7/15 study date is now yyyymmdd
      if isnumeric(studyDate{i}), studyDate{i} = num2str(studyDate{i}); end
%       studyDate = split(studyDate,' ');
%       studyDate = studyDate{1};
      %new portal  has dates as yyyymmdd, need to add delimiters to be able
      %to parse it
      if length(studyDate{i}) ~= 8, error('date must be yyyymmdd'), end
      tok = regexp(studyDate{i},'[^\d]*','start');
      if ~isempty(tok),
          error('date must be yyyymmdd')
      end
      portalDate{i} = [studyDate{i}(1:4) '-' studyDate{i}(5:6) '-' studyDate{i}(7:8)];
      portalAge(i) = ageAt(SI.BD, portalDate{i});
    end
    %  portalAge2(i) = str2num(portal(iSubj_portal(i)).Age_at_Imaging);
  end
  [minAgeDiff, portalMatch] = min(abs(tpAge - portalAge));
  % [minAgeDiff2, portalMatch2] = min(abs(tpAge - portalAge2));
  % if portalMatch == portalMatch2,
  %   minAgeDiff = min([minAgeDiff minAgeDiff2]);
  % end
else
  minAgeDiff = inf;
end
if (minAgeDiff < 0.5),
  SI.VisitID = portal(iSubj_portal(portalMatch)).VisitID;
  SI.studyDate = studyDate{portalMatch};
  SI.portalDate = portalDate{portalMatch};
  SI.portalAge = portalAge(portalMatch);
  
  if sum( abs(tpAge - portalAge) < 0.5) > 1,
      dbstop if error
      warning('multiple portal matches (%s, %s)',SI.SubjID,date)
  end
else
  warning('%s (%s) no match found in portal data within +/- 6 months (%.2f y)',SI.SubjID,date,minAgeDiff)
  SI.VisitID = '';
  SI.studyDate = '';
  SI.portalDate = '';
  SI.portalAge = [];
end

%find participant sheet match
for i = 1:length(iSubj_sheet),
  sheetAge_start = ageAt(SI.BD, sheet(iSubj_sheet(i)).startDate);
  sheetAge_end = ageAt(SI.BD, sheet(iSubj_sheet(i)).endDate);
  sheetAge(i) = mean([sheetAge_start sheetAge_end]);
end
[minAgeDiff, sheetMatch] = min(abs(tpAge - sheetAge));
if (minAgeDiff < 0.5),
  SI.plingTimepointStartDate = sheet(iSubj_sheet(sheetMatch)).startDate;
  SI.plingTimepointEndDate = sheet(iSubj_sheet(sheetMatch)).endDate;
  SI.plingTimePoint = sheet(iSubj_sheet(sheetMatch)).timePoint;
  SI.plingTimepontMriDate = sheet(iSubj_sheet(sheetMatch)).mriDate;
  SI.plingTimepointNote = sheet(iSubj_sheet(sheetMatch)).note;
  SI.meanBehavAge = sheetAge(sheetMatch);
  
  if sum( abs(tpAge - sheetAge) < 0.5) > 1,
      dbstop if error
      warning('multiple sheet matches (%s, %s)',SI.SubjID, date)
  end
else
  warning('%s (%s) no match found in sheet within +/- 6 months  (%.2f y)',SI.SubjID,date,minAgeDiff)
  SI.plingTimepointStartDate = '';
  SI.plingTimepointEndDate = '';
  SI.plingTimePoint = '';
  SI.plingTimepontMriDate = '';
  SI.plingTimepointNote = '';
  SI.meanBehavAge = [];
end

SI.testDateToSnap = date;
SI.Age = tpAge;
SI.Grade = tpGrade;


