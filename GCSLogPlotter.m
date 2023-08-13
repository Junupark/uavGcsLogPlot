classdef GCSLogPlotter < handle
    properties (Access = private)
        mav
        msg_ids_
        msg_info_
        msg_counts_
        parsed
    end
    properties % (Access = private)
        msg_names
        data
    end
    
    methods (Access = public)
        function self = GCSLogPlotter(opt)
            arguments
                opt.logfile {mustBeA(opt.logfile, ["char", "string"])}
            end
            if not(isfolder("./mavlink"))
                system("git clone https://github.com/mavlink/mavlink")
            end
            addpath("./mavlink/message_definitions/v1.0/");
            
            self.mav = mavlinkdialect("common.xml");
            self.parsed = false;
            if isfield(opt, 'logfile')
                self.Parse(opt.logfile);
            end
        end
        
        function self = Parse(self, logfile)
            arguments
                self {mustBeA(self, "GCSLogPlotter")}
                logfile
                % any useful options?
            end
            try
                f = csvread(logfile);
            catch
                self.parsed = false;
                error("No such file");
            end
            self.msg_ids_ = unique(f(:,1));
            n_msg_types = length(self.msg_ids_);
            self.msg_names = cell(n_msg_types, 1);
            info = cell(n_msg_types, 1);
            msg_counts = zeros(n_msg_types, 1);
            
            data_dict = cell(n_msg_types, 1);
            for i = 1:n_msg_types
                id = self.msg_ids_(i);
                msg_name = self.mav.msginfo(id).MessageName;
                field = self.mav.msginfo(id).Fields{1};
                
                slice = find(f(:,1)==id);
                n_fields = size(field, 1);
                
                data_dict{i} = containers.Map(field.Name, ...
                    mat2cell(f(slice, 1 + (1:n_fields)), length(slice), ones(1, n_fields)));
                
                
                self.msg_names{i} = msg_name;
                info{i} = field;
                msg_counts(i) = length(slice);
            end
            self.msg_names = string(self.msg_names);
            self.data = containers.Map(self.msg_names, data_dict);
            self.msg_counts_ = containers.Map(self.msg_names, msg_counts);
            self.msg_info_ = containers.Map(self.msg_names, info);
            self.parsed = true;
        end
        
        function handles = Plot(self, opt)
            arguments
                self
                opt.msg_name {mustBeA(opt.msg_name, ["char", "string"])}
                opt.msg_id {mustBeInteger(opt.msg_id)}
                opt.fields {mustBeA(opt.fields, ["char", "string"])} % Not supported yet
                opt.line_width {mustBeGreaterThan(opt.line_width, 1)} = 2
                % many more plot options are applicable
            end
            assert(self.parsed, "No data to plot");
            if isfield(opt, 'msg_name')
                msg_name = upper(string(opt.msg_name));
                assert(any(strcmp(msg_name, self.msg_names)), ...
                    "No such messages are included in the logfile");
            else
                if isfield(opt, 'msg_id')
                    msg_name = upper(self.mav.msginfo(opt.msg_id).MessageName);
                    assert(ismember(msg_name, self.msg_names), ...
                        "No such messages are included in the logfile");
                else
                    error("Specify message (either string or id) to plot");
                end
            end
            data_ = self.data(msg_name);
            info_ = self.msg_info_(msg_name);
            units = info_.Units;
            names = info_.Name;
            if any(startsWith(names, "time"))
                for key = data_.keys
                    if startsWith(key, "time")
                        timeline = data_(key{1});
                        time_label = key{1};
                        break;
                    end
                end
            else
                timeline = 1:self.msg_count(msg_name);
                time_label = "data count";
            end
            
            n_fields = size(info_,1);
            handles = zeros(1, n_fields);
            for i = 1:n_fields
                field_name = names(i);
                if startsWith(field_name, "time")
                    continue;
                end
                figure;
                handles(i) = plot(timeline, data_(field_name), 'LineWidth', opt.line_width);
                xlabel(time_label, 'Interpreter', 'none');
                ylabel(units(i));
                title(field_name);
                grid on;
            end
        end
    end
    
    methods (Access = private)
%         function 
    end
    
    
end