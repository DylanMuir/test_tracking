function GACollect(strTrackingID, strHitType, ...
   strUserID, strClientUUID, ...
   strDocURL, strDocHost, strDocPath, strDocTitle, ...
   strScreenName, strAppName, strAppVersion, ...
   strEventCategory, strEventAction, strEventLabel, nEventValue, ...
   strDataSource, strSessionControl, bNonInteractive) %#ok<*INUSL>

% GACollect - FUNCTION General interface to Google Analytics 'collect' API
%
% Usage: GACollect(strTrackingID, strHitType, ...
%                  < strUserID, strClientUUID >, ...
%                  < strDocURL, strDocHost, strDocPath, strDocTitle >, ...
%                  < strScreenName >, ...
%                  < strEventCategory, strEventAction, strEventLabel, nEventValue >, ...
%                  < strAppName, strAppVersion >, ...
%                  < strDataSource, strSessionControl, bNonInteractive >)
%
% `strTrackingID` must be a valid Google Analytics tracking ID.
% `strHitType` must be one of 'pageview', 'screenview', 'event'.
% pageview: `strDocURL`, `strDocHost`, `strDocPath`, `strDocTitle` are used
% screenview: `strScreenName` is used
% event: `strEventCategory`, `strEventAction`, `strEventLabel`,
% `nEventValue` are used
%
% Other arguments are option. See Google Analytics Measurement Protocol
% documentation for details:
% https://developers.google.com/analytics/devguides/collection/protocol/v1/

% - Set up required request parameters
sReq.v = 1;
sReq.ds = 'matlab';
sReq.tid = strTrackingID;


if exist('strSessionControl', 'var') && ~isempty(strSessionControl)
   strSessionControl = lower(strSessionControl);
   
   switch strSessionControl
      case {'start', 'end'}
         
      otherwise
         error('GACollect:Arguments', ...
               '''strSessionControl'' must be one of {''start'', ''end''}.');
   end
end

% - Include session control
R('strSessionControl', 'sc');

% - Include data source
R('strDataSource', 'ds');

% -- Check client identifier
NeedAtLeastOne('strUserID', 'strClientUUID');

R('strUserID', 'uid');
R('strClientUUID', 'cid');

% -- Check hit type
strHitType = lower(strHitType);

switch strHitType
   case 'pageview'
      NeedAtLeastOne('strDocURL', 'strDocHost');
      R('strDocURL', 'dl');
      R('strDocHost', 'dh');
      R('strDocPath', 'dp');
      R('strDocTitle', 'dt');
      
   case 'screenview'
      NeedAll('strScreenName');
      R('strScreenName', 'cd');
     
   case 'event'
      NeedAll('strEventCategory', 'strEventAction');
      R('strEventCategory', 'ec');
      R('strEventAction', 'ea');
      R('strEventLabel', 'el');
      R('nEventValue', 'ev', @(o)isnumeric(o) && (o>0) && (floor(o) == o));
      
   case 'transaction'
      error('GACollect:UnsupportedHitType', ...
            'The hit type ''%s'' is unsupported.', strHitType);
      NeedAll('strTransID'); %#ok<*UNRCH>
      
   case 'item'
      error('GACollect:UnsupportedHitType', ...
            'The hit type ''%s'' is unsupported.', strHitType);
      NeedAll('strTransID', 'strItemName');
      
   case 'social'
      error('GACollect:UnsupportedHitType', ...
            'The hit type ''%s'' is unsupported.', strHitType);
      NeedAll('strSocialNetwork', 'strSocialAction', 'strSocialActionTarget');
      
   case 'exception'
      error('GACollect:UnsupportedHitType', ...
            'The hit type ''%s'' is unsupported.', strHitType);
      
   case 'timing'
      error('GACollect:UnsupportedHitType', ...
            'The hit type ''%s'' is unsupported.', strHitType);
      NeedAll('strUserTimingCat', 'strUserTimingVar', 'nUserTimingTime');
      
   otherwise
      error('GACollect:Arguments', ...
         '''strHitType'' must be one of {''pageview'', ''screenview'', ''event'', ''transaction'', ''item'', ''social'', ''exception'', ''timing''}.');
end

% - Set hit type
sReq.t = strHitType;


% - Check bNonInteractive
if exist('bNonInteractive', 'var')
   bNonInteractive = double(logical(bNonInteractive)); %#ok<NASGU>
end
R('bNonInteractive', 'ni');

% - App fields
R('strAppName', 'an');
R('strAppVersion', 'av');

% -- Event fields
strURL = 'https://www.google-analytics.com/collect';
weboptions('RequestMethod','post');

cRequest = [fieldnames(sReq) struct2cell(sReq)]';
ans = webwrite(strURL, cRequest{:});


   function R(strVarName, strReqFieldName, fhValidate, oDefaultValue)
      if exist(strVarName, 'var') && ~isempty(eval(strVarName))
         if exist('fhValidate', 'var')
            assert(fhValidate(eval(strVarName)), ...
                   'GACollect:Arguments', ...
                   'Incorrect value for ''%s''.', strVarName);
         end
         
         sReq.(strReqFieldName) = eval(strVarName);
      
      elseif exist('oDefaultValue', 'var') && ~isempty(oDefaultValue)
         sReq.(strReqFieldName) = oDefaultValue;
      end
   end

   function bOk = NeedAll(varargin)
      sWS = who();
      vbArgExists = cellfun(@(s)ismember(s, sWS) && ~isempty(evalin('caller', s)), varargin);
      bOk = all(vbArgExists);
      
      if ~bOk
         error('GACollect:Arguments', ...
               'All of {%s} are required.', ...
               sprintf('%s, ', varargin{:}));
      end
   end

   function bOk = NeedAtLeastOne(varargin)
      sWS = who();
      vbArgExists = cellfun(@(s)ismember(s, sWS) && ~isempty(evalin('caller', s)), varargin);
      bOk = any(vbArgExists);
      
      if ~bOk
         error('GACollect:Arguments', ...
               'At least one of {%s} is required.', ...
               sprintf('%s, ', varargin{:}));
      end
   end

end


