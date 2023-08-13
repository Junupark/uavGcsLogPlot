1. usage 1

'''
plotter = GCSLogPlotter();
plotter.Parse("PATH-TO-LOGFILE"); % plotter.Parse("Flight_Log_Sortie_73.csv");
plotter.Plot('msg_name', "msg_name_you_want_to_plot"); % such as: plotter.Plot('msg_name', "HIL_STATE");
'''

2. usage 2

'''
plotter = GCSLogPlotter().Parse("Flight_Log_Sortie_73.csv").Plot('msg_id', 90); 
% 90 = HIL_STATE
'''
