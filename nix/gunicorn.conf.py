import os

import dashboard


def post_worker_init(worker):
    dashboard.startThreads()
    dashboard.DashboardPlugins.startThreads()


worker_class = "gthread"
workers = 1
threads = 2
bind = os.environ.get("WGDASHBOARD_BIND", "127.0.0.1:10086")
wsgi_app = "dashboard:app"
accesslog = "-"
errorlog = "-"
capture_output = True
control_socket_disable = True
loglevel = os.environ.get("WGDASHBOARD_LOG_LEVEL", "info")
