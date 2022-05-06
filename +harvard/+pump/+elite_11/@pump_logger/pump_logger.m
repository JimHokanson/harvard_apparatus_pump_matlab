classdef pump_logger < handle
    %
    %   Class:
    %   harvard.pump.elite_11.pump_logger
    %
    %   Singleton, access via:
    %   log = harvard.pump.elite_11.pump_logger.getInstance
    
    properties
        TIMEOUT_VALUE = 10
        
        start_time
        cmd
        cmd_response
        wait_duration
        cmd_duration
        wait_failed
        cmd_failed
        time_at_wait_start
        time_at_cmd_start
        time_at_cmd_finish
        failed
        
        I = 0
        h_tics
    end
    
    methods (Static)
        %Singleton
        function obj = getInstance()
            %
            %   harvard.pump.elite_11.pump_logger.getInstance
            
            persistent instance
            
            if isempty(instance)
                instance = harvard.pump.elite_11.pump_logger();
            end
            obj = instance;
        end
    end
    
    methods (Access=private)
        function obj = pump_logger()
            n = 10000;
            obj.start_time = now*86400;
            obj.cmd = cell(1,n);
            obj.cmd_response = cell(1,n);
            obj.wait_failed = false(1,n);
            obj.cmd_failed = true(1,n);
            obj.wait_duration = zeros(1,n);
            obj.cmd_duration = zeros(1,n);
            obj.time_at_wait_start = zeros(1,n);
            obj.time_at_cmd_start = zeros(1,n);
            obj.time_at_cmd_finish = zeros(1,n);
            obj.h_tics = zeros(1,n,'like',tic);
            obj.failed = true(1,n);
        end
    end
    methods
        function t = getTable(obj,indices)
            s = struct;
            s.cmd = obj.cmd(indices)';
            s.wait_time = obj.wait_duration(indices)';
            s.dur_time = obj.cmd_duration(indices)';
            s.wait_failed = obj.wait_failed(indices)';
            s.cmd_failed = obj.cmd_failed(indices)';
            s.cmd_response = obj.cmd_response(indices)';
            
            t = struct2table(s);
        end
        function I2 = logWaitStart(obj,cmd)
            I2 = obj.I + 1;
            if I2 > 10000
                I2 = 1;
            end
            obj.I = I2;
            obj.cmd{I2} = cmd;
            obj.h_tics(I2) = tic;
            obj.time_at_wait_start(I2) = now()*86400 - obj.start_time;
        end
        function logWaitFailed(obj,I2)
            obj.wait_failed(I2) = true;
            obj.wait_duration(I2) = obj.TIMEOUT_VALUE;
            obj.cmd_duration(I2) = obj.TIMEOUT_VALUE;
        end
        function logCmdStart(obj,I2)
            obj.wait_duration(I2) = toc(obj.h_tics(I2));
            obj.time_at_cmd_start(I2) = now()*86400 - obj.start_time;
        end
        function logCmdResponse(obj,response,I2,is_failure)
            obj.cmd_response{I2} = response;
            obj.cmd_failed(I2) = is_failure;
        end
        function logCmdStop(obj,I2)
            obj.cmd_duration(I2) = toc(obj.h_tics(I2));
            obj.time_at_cmd_finish(I2) = now()*86400 - obj.start_time;
            obj.failed(I2) = false;
        end
    end
end

