bind 'unix:///tmp/pumaproject.sock'

workers 4
threads 1, 1

daemonize
preload_app!

environment      'production'

pidfile         '/home/project/Backend/log/puma.pid'
stdout_redirect '/home/project/Backend/log/puma/access.log', '/home/project/Backend/log/puma/error.log', true
state_path      '/home/project/Backend/log/puma.stats'
rackup          '/home/project/Backend/lib/sinatra/config.ru'
